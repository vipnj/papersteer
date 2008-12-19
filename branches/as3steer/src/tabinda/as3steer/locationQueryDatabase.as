// ----------------------------------------------------------------------------
//
// OpenSteer - Action Script 3 Port
// Port by Mohammad Haseeb aka M.H.A.Q.S.
// http://www.tabinda.net
//
// OpenSteer -- Steering Behaviors for Autonomous Characters
//
// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Original author: Craig Reynolds <craig_reynolds@playstation.sony.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//
// ----------------------------------------------------------------------------

package tabinda.as3steer
{
    /** This utility is a spatial database which stores objects each of
    * which is associated with a 3d point (a location in a 3d space).
    * The points serve as the "search key" for the associated object.
    * It is intended to efficiently answer "sphere inclusion" queries,
    * also known as range queries: basically questions like:

    *  Which objects are within a radius R of the location L?

    * In this context, "efficiently" means significantly faster than the
    * naive, brute force O(n) testing of all known points.  Additionally
    * it is assumed that the objects move along unpredictable paths, so
    * that extensive preprocessing (for example, constructing a Delaunay
    * triangulation of the point set) may not be practical.

    * The implementation is a "bin lattice": a 3d rectangular array of
    * brick-shaped (rectangular parallelepipeds) regions of space.  Each
    * region is represented by a pointer to a (possibly empty) doubly-
    * linked list of objects.  All of these sub-bricks are the same
    * size.  All bricks are aligned with the global coordinate axes.

    * Terminology used here: the region of space associated with a bin
    * is called a sub-brick.  The collection of all sub-bricks is called
    * the super-brick.  The super-brick should be specified to surround
    * the region of space in which (almost) all the key-points will
    * exist.  If key-points move outside the super-brick everything will
    * continue to work, but without the speed advantage provided by the
    * spatial subdivision.  For more details about how to specify the
    * super-brick's position, size and subdivisions see lqCreateDatabase
    * below.

    * Overview of usage: an application using this facility would first
    * create a database with lqCreateDatabase.  For each client object
    * the application wants to put in the database it creates a
    * lqClientProxy and initializes it with lqInitClientProxy.  When a
    * client object moves, the application calls lqUpdateForNewLocation.
    * To perform a query lqMapOverAllObjectsInLocality is passed an
    * application-supplied call-back function to be applied to all
    * client objects in the locality.  See lqCallBackFunction below for
    * more detail.  The lqFindNearestNeighborWithinRadius function can
    * be used to find a single nearest neighbor using the database.

    * Note that "locality query" is also known as neighborhood query,
    * neighborhood search, near neighbor search, and range query.  For
    * additional information on this and related topics see:
    * http://www.red3d.com/cwr/boids/ips.html

    * For some description and illustrations of this database in use,
    * see this paper: http://www.red3d.com/cwr/papers/2000/pip.html
	*/
	public class locationQueryDatabase
	{

		/* the origin is the super-brick corner minimum coordinates */
		public var originx:Number,originy:Number,originz:Number;

		// length of the edges of the super-brick
		public var sizex:Number,sizey:Number,sizez:Number;

		// number of sub-brick divisions in each direction 
		public var divx:int,divy:int,divz:int;

		// pointer to an array of pointers, one for each bin 
		public var bins:Array;

		//extra bin for "everything else" (points outside super-brick) 
		public var other:lqBin;

		var bincount:int;

		public function locationQueryDatabase(_originx:Number,_originy:Number,_originz:Number,_sizex:Number,_sizey:Number,_sizez:Number,_divx:int,_divy:int,_divz:int)
		{
			originx=_originx;
			originy=_originy;
			originz=_originz;
			sizex=_sizex;
			sizey=_sizey;
			sizez=_sizez;
			divx=_divx;
			divy=_divy;
			divz=_divz;

			var i:int;
			bincount=divx * divy * divz;

			bins=new Array(bincount);

			for (var x:int=0; x < divx; x++)
			{
				for (var y:int=0; y < divy; y++)
				{
					for (var z:int=0; z < divz; z++)
					{
						i=int(x * divy * divz + y * divz + z);
						var tx:Number=originx + Number(x) * Number(sizex) / Number(divx);
						var ty:Number=originy + Number(y) * Number(sizey) / Number(divy);
						var tz:Number=originz + Number(z) * Number(sizez) / Number(divz);

						var binCenter:Vector3=new Vector3(tx,ty,tz);
						bins[i]=new lqBin(binCenter);
					}
				}
			}
			other=new lqBin(Vector3.ZERO);
		}

		// ------------------------------------------------------------------ 
		// Determine index into linear bin array given 3D bin indices 
		public function lqBinCoordsToBinIndex(ix:Number,iy:Number,iz:Number):int
		{
			return int(((ix * divy * divz) + (iy * divz) + iz));
		}

		/* ------------------------------------------------------------------ */
		/* Find the bin ID for a location in space.  The location is given in
           terms of its XYZ coordinates.  The bin ID is a pointer to a pointer
           to the bin contents list.  */
		public function lqBinForLocation(x:Number,y:Number,z:Number):lqBin
		{
			var i:int,ix:int,iy:int,iz:int;

		/* if point outside super-brick, return the "other" bin */
			if (x < originx)
			{
				return other;
			}
			if (y < originy)
			{
				return other;
			}
			if (z < originz)
			{
				return other;
			}
			if (x >= originx + sizex)
			{
				return other;
			}
			if (y >= originy + sizey)
			{
				return other;
			}
			if (z >= originz + sizez)
			{
				return other;
			}

			/* if point inside super-brick, compute the bin coordinates */
			ix = int((((x - originx) / sizex) * divx));
            iy = int((((y - originy) / sizey) * divy));
            iz = int((((z - originz) / sizez) * divz));

			/* convert to linear bin number */
            i = lqBinCoordsToBinIndex ( ix, iy, iz);
 			if (i < 0 || i >= bincount) return other;
            /* return pointer to that bin */
			return bins[i];
		}

		// Adds a given client object to a given bin, linking it into the bin
		// contents list.
		public function lqAddToBin(clientObject:lqClientProxy,bin:lqBin):void
		{

			bin.clientList.push(clientObject);
			clientObject.bin=bin;
		}

		// Removes a given client object from its current bin, unlinking it
		//   from the bin contents list. 
		public function lqRemoveFromBin(clientObject:lqClientProxy):void
		{
			if (clientObject.bin != null)
			{
				clientObject.bin.clientList.splice(clientObject.bin.clientList.indexOf(clientObject),1);
			}
		}
		
		// Call for each client object every time its location changes.  For
		//   example, in an animation application, this would be called each
		//   frame for every moving object.  
		public function lqUpdateForNewLocation(clientObject:lqClientProxy,x:Number,y:Number,z:Number):void
		{
			// find bin for new location 
			var newBin:lqBin=lqBinForLocation(x,y,z);

			// store location in client object, for future reference
			clientObject.x=x;
			clientObject.y=y;
			clientObject.z=z;

			/* has object moved into a new bin? */
			if (newBin != clientObject.bin)
			{
				lqRemoveFromBin(clientObject);
				lqAddToBin(clientObject,newBin);
			}
		}

		// Given a bin's list of client proxies, traverse the list and invoke
		//   the given lqCallBackFunction on each object that falls within the
		//   search radius.  
		public function getBinClientObjectList(bin:lqBin,x:Number,y:Number,z:Number,radiusSquared:Number):Array
		{
			var tList:Array=new Array();
			for (var i:int=0; i < bin.clientList.length; i++)
			{
				var tClientObject:lqClientProxy=lqClientProxy(bin.clientList[i]);

				/* compute distance (squared) from this client   */
				/* object to given locality sphere's centerpoint */
				var dx:Number=x - tClientObject.x;
				var dy:Number=y - tClientObject.y;
				var dz:Number=z - tClientObject.z;
				var distanceSquared:Number=(dx * dx) + (dy * dy) + (dz * dz);

				/* apply function if client object within sphere */
				if (distanceSquared < radiusSquared)
				{
					tList.push(tClientObject);
				}   
			}
			//});
			return tList;
		}

		/* ------------------------------------------------------------------ */
		/* This subroutine of lqMapOverAllObjectsInLocality efficiently
				   traverses of subset of bins specified by max and min bin
				   coordinates. */
		public function getAllClientObjectsInLocalityClipped(x:Number,y:Number,z:Number,radius:Number,minBinX:int,minBinY:int,minBinZ:int,maxBinX:int,maxBinY:int,maxBinZ:int):Array
		{
			var iindex:int,jindex:int,kindex:int;
			var slab:int=divy * divz;
			var row:int=divz;
			var istart:int=minBinX * slab;
			var jstart:int=minBinY * row;
			var kstart:int=minBinZ;
			var bin:lqBin;
			var radiusSquared:Number=radius * radius;

			var returnList:Array=new Array();

			// loop for x bins across diameter of sphere 
			iindex=istart;
			for (var i:int=minBinX; i <= maxBinX; i++)
			{
				// loop for y bins across diameter of sphere
				jindex=jstart;
				for (var j:int=minBinY; j <= maxBinY; j++)
				{
					// loop for z bins across diameter of sphere
					kindex=kstart;
					for (var k:int=minBinZ; k <= maxBinZ; k++)
					{
						// get current bin's client object list
						bin=bins[iindex + jindex + kindex];

						// traverse current bin's client object list
						var tSubList:Array=getBinClientObjectList(bin,x,y,z,radiusSquared);
						returnList.concat(tSubList);
						kindex+= 1;
					}
					jindex+= row;
				}
				iindex+= slab;
			}
			return returnList;
		}

		// ------------------------------------------------------------------
		// If the query region (sphere) extends outside of the "super-brick"
		//   we need to check for objects in the catch-all "other" bin which
		//   holds any object which are not inside the regular sub-bricks  
		public function getAllOutsideObjects(x:Number,y:Number,z:Number,radius:Number):Array
		{
			var radiusSquared:Number=radius * radius;
			return (getBinClientObjectList(other,x,y,z,radiusSquared));
		}

		// ------------------------------------------------------------------
		// Apply an application-specific function to all objects in a certain
		//   locality.  The locality is specified as a sphere with a given
		//   center and radius.  All objects whose location (key-point) is
		//   within this sphere are identified and the function is applied to
		//   them.  The application-supplied function takes three arguments:
		//
		//     (1) a void* pointer to an lqClientProxy's "object".
		//     (2) the square of the distance from the center of the search
		//         locality sphere (x,y,z) to object's key-point.
		//     (3) a void* pointer to the caller-supplied "client query state"
		//         object -- typically NULL, but can be used to store state
		//         between calls to the lqCallBackFunction.
		//
		//   This routine uses the LQ database to quickly reject any objects in
		//   bins which do not overlap with the sphere of interest.  Incremental
		//   calculation of index values is used to efficiently traverse the
		//   bins of interest.
		public function getAllObjectsInLocality(x:Number,y:Number,z:Number,radius:Number):Array
		{
			var partlyOut:Boolean=false;
			var completelyOutside:Boolean =
					       (((x + radius) < originx) ||
							((y + radius) < originy) ||
						    ((z + radius) < originz) ||
						    ((x - radius) >= originx + sizex) ||
						    ((y - radius) >= originy + sizey) ||
						    ((z - radius) >= originz + sizez));
			 
			var minBinX:int,minBinY:int,minBinZ:int,maxBinX:int,maxBinY:int,maxBinZ:int;

			// is the sphere completely outside the "super brick"?
			if (completelyOutside)
			{
				return getAllOutsideObjects(x,y,z,radius);
			}

			var returnList:Array=new Array();

			/* compute min and max bin coordinates for each dimension */
			minBinX=int(((((x - radius) - originx) / sizex) * divx));
			minBinY=int(((((y - radius) - originy) / sizey) * divy));
			minBinZ=int(((((z - radius) - originz) / sizez) * divz));
			maxBinX=int(((((x + radius) - originx) / sizex) * divx));
			maxBinY=int(((((y + radius) - originy) / sizey) * divy));
			maxBinZ=int(((((z + radius) - originz) / sizez) * divz));

			/* clip bin coordinates */
			if (minBinX < 0)
			{
				partlyOut=true;
				minBinX=0;
			}
			if (minBinY < 0)
			{
				partlyOut=true;
				minBinY=0;
			}
			if (minBinZ < 0)
			{
				partlyOut=true;
				minBinZ=0;
			}
			if (maxBinX >= divx)
			{
				partlyOut=true;
				maxBinX=divx - 1;
			}
			if (maxBinY >= divy)
			{
				partlyOut=true;
				maxBinY=divy - 1;
			}
			if (maxBinZ >= divz)
			{
				partlyOut=true;
				maxBinZ=divz - 1;
			}

			// map function over objects in bins 
			returnList.concat(getAllClientObjectsInLocalityClipped(x,y,z,radius,minBinX,minBinY,minBinZ,maxBinX,maxBinY,maxBinZ));
			return returnList;
		}

		/* ------------------------------------------------------------------ */
		/* Search the database to find the object whose key-point is nearest
           to a given location yet within a given radius.  That is, it finds
           the object (if any) within a given search sphere which is nearest
           to the sphere's center.  The ignoreObject argument can be used to
           exclude an object from consideration (or it can be NULL).  This is
           useful when looking for the nearest neighbor of an object in the
           database, since otherwise it would be its own nearest neighbor.
           The function returns a void* pointer to the nearest object, or
           NULL if none is found.  */
		public function lqFindNearestNeighborWithinRadius(x:Number,y:Number,z:Number,radius:Number,ignoreObject:Object):lqClientProxy
		{

			var minDistanceSquared:Number=Number.MAX_VALUE;

			// map search helper function over all objects within radius 
			var foundList:Array=getAllObjectsInLocality(x,y,z,radius);

			var nearestObject:lqClientProxy=null;

			for (var i:int=0; i < foundList.length; i++)
			{
				var tProxyObject:lqClientProxy=lqClientProxy(foundList[i]);
				if (tProxyObject != ignoreObject)
				{
					var dx:Number=tProxyObject.x - x;
					var dy:Number=tProxyObject.y - y;
					var dz:Number=tProxyObject.z - z;

					var distanceSquared:Number=(dx * dx) + (dy * dy) + (dz * dz);
					if (distanceSquared < minDistanceSquared)
					{
						nearestObject=tProxyObject;
						minDistanceSquared=distanceSquared;
					}
				}
			}
			return nearestObject;
		}

	/* ------------------------------------------------------------------ */
	/* Apply a user-supplied function to all objects in the database,
	   regardless of locality (cf lqMapOverAllObjectsInLocality) */
		public function getAllObjects():Array
		{
			var bincount:int=divx * divy * divz;

			var returnList:Array=new Array();
			for (var i:int=0; i < bincount; i++)
			{
				returnList.concat(bins[i].clientList);
			}
			returnList.concat(other.clientList);
			return returnList;
		}

		/* ------------------------------------------------------------------ */
		/* internal helper function */
		public function lqRemoveAllObjectsInBin(bin:lqBin):void
		{
			bin.clientList.splice(0,null);
		}

		/* ------------------------------------------------------------------ */
		/* Removes (all proxies for) all objects from all bins */
		public function lqRemoveAllObjects():void
		{
			var bincount:int=divx * divy * divz;

			for (var i:int=0; i < bincount; i++)
			{
				lqRemoveAllObjectsInBin(bins[i]);
			}
			lqRemoveAllObjectsInBin(other);
		}

		public function getMostPopulatedBinCenter():Vector3
		{
			var mostPopulatedBin:lqBin=getMostPopulatedBin();
			if (mostPopulatedBin != null)
			{
				return mostPopulatedBin.center;
			}
			else
			{
				return Vector3.ZERO;
			}
		}

		public function getMostPopulatedBin():lqBin
		{
			var bincount:int=divx * divy * divz;
			var largestPopulation:int=0;
			var mostPopulatedBin:lqBin=null;

			for (var i:int=0; i < bincount; i++)
			{
				if (bins[i].clientList.length > largestPopulation)
				{
					largestPopulation=bins[i].clientList.length;
					mostPopulatedBin=bins[i];
				}
			}
			// We will ignore other for now. Hope that works out ok
			return mostPopulatedBin;
		}
	}
}