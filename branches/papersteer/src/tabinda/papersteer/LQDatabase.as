// ----------------------------------------------------------------------------
//
// PaperSteer - Papervision3D Port of OpenSteer
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

package tabinda.papersteer
{
	import flash.accessibility.Accessibility;
	/**
	 * This structure represents the spatial database.  Typically one of
	 * these would be created, by a call to lqCreateDatabase, for a given
	 * application.
	 */
	public class LQDatabase
	{
		// the origin is the super-brick corner minimum coordinates
		private var Origin:Vector3;

		// length of the edges of the super-brick
		private var Size:Vector3;

		// number of sub-brick divisions in each direction
		private var DivX:int;
		private var DivY:int;
		private var DivZ:int;

		// pointer to an array of pointers, one for each bin
		// The last index is the extra bin for "everything else" (points outside super-brick)
		private var bins:Vector.<ClientProxy>;

		// extra bin for "everything else" (points outside super-brick)
		//ClientProxy other;

		/**
		 * Allocate and initialize an LQ database, return a pointer to it.
		 * The application needs to call this before using the LQ facility.
		 * The nine parameters define the properties of the "super-brick":
		 * 
		 * @param origin: coordinates of one corner of the super-brick, its minimum x, y and z extent.
		 * @param size: the width, height and depth of the super-brick.
		 * @param the number of subdivisions (sub-bricks) along each axis.
		 * 
		 * This routine also allocates the bin array, and initialize its
		 * contents.
		 */
		public function LQDatabase(origin:Vector3, size:Vector3, divx:int, divy:int, divz:int):void
		{
			Origin = origin;
			Size = size;
			DivX = divx;
			DivY = divy;
			DivZ = divz;

			// The last index is the "other" bin
			var bincount:int = divx * divy * divz + 1;
			bins = new Vector.<ClientProxy>(bincount);
			for (var i:int = 0; i < bins.length; i++)
			{
				bins[i] = null;
			}
		}

		/**
		 * Determine index into linear bin array given 3D bin indices
		 * @param	ix
		 * @param	iy
		 * @param	iz
		 * @return
		 */
		public function BinCoordsToBinIndex(ix:int, iy:int, iz:int):int
		{
			return ((ix * DivY * DivZ) + (iy * DivZ) + iz);
		}

		/**
		 * Call for each client obj every time its location changes.  For
		 * example, in an animation application, this would be called each
		 * frame for every moving obj.
		 *  
		 * @param	obj
		 * @param	position
		 */  
		public function UpdateForNewLocation(obj:ClientProxy, position:Vector3):ClientProxy
		{
			/* find bin for new location */
			var newBin:int = BinForLocation(position);

			/* store location in client obj, for future reference */
			obj.Position = position;

			/* has obj moved into a new bin? */
			if (newBin != obj.Bin)
			{
				obj = RemoveFromBin(obj);
				obj = AddToBin(obj, newBin);
			}
			return obj;
		}

		/**
		 * Adds a given client obj to a given bin, linking it into the bin
		 *  contents list.
		 *  
		 * @param	obj
		 * @param	binIndex
		 */
		public function AddToBin(obj:ClientProxy, binIndex:int):ClientProxy
		{
			/* if bin is currently empty */
			if (bins[binIndex] == null)
			{
				obj.Prev = null;
				obj.Next = null;
			}
			else
			{
				obj.Prev = null;
				obj.Next = bins[binIndex];
				bins[binIndex].Prev = obj;
			}

			bins[binIndex] = obj;

			/* record bin ID in proxy obj */
			obj.Bin = binIndex;
			return obj;
		}

		/* Find the bin ID for a location in space.  The location is given in
		   terms of its XYZ coordinates.  The bin ID is a pointer to a pointer
		   to the bin contents list.  */
		public function BinForLocation(position:Vector3):int
		{
			/* if point outside super-brick, return the "other" bin */
			if (position.x < Origin.x || position.y < Origin.y || position.z < Origin.z ||
				position.x >= Origin.x + Size.x || position.y >= Origin.y + Size.y || position.z >= Origin.z + Size.z)
			{
				return bins.length - 1;
			}

			/* if point inside super-brick, compute the bin coordinates */
			var ix:int = int((((position.x - Origin.x) / Size.x) * DivX));
			var iy:int = int((((position.y - Origin.y) / Size.y) * DivY));
			var iz:int = int((((position.z - Origin.z) / Size.z) * DivZ));

			/* convert to linear bin number */
			var i:int = BinCoordsToBinIndex(ix, iy, iz);

			/* return pointer to that bin */
			return i;// (bins[i]);
		}

		/* Apply an application-specific function to all objects in a certain
		   locality.  The locality is specified as a sphere with a given
		   center and radius.  All objects whose location (key-point) is
		   within this sphere are identified and the function is applied to
		   them.  The application-supplied function takes three arguments:

			 (1) a void* pointer to an lqClientProxy's "object".
			 (2) the square of the distance from the center of the search
				 locality sphere (x,y,z) to object's key-point.
			 (3) a void* pointer to the caller-supplied "client query state"
				 object -- typically NULL, but can be used to store state
				 between calls to the lqCallBackFunction.

		   This routine uses the LQ database to quickly reject any objects in
		   bins which do not overlap with the sphere of interest.  Incremental
		   calculation of index values is used to efficiently traverse the
		   bins of interest. */
		public function MapOverAllObjectsInLocality(center:Vector3, radius:Number, func:Function, clientQueryState:Object):void
		{
			var partlyOut:int = 0;
			var completelyOutside:Boolean =
				(((center.x + radius) < Origin.x) ||
				 ((center.y + radius) < Origin.y) ||
				 ((center.z + radius) < Origin.z) ||
				 ((center.x - radius) >= Origin.x + Size.x) ||
				 ((center.y - radius) >= Origin.y + Size.y) ||
				 ((center.z - radius) >= Origin.z + Size.z));
			var minBinX:int, minBinY:int, minBinZ:int, maxBinX:int, maxBinY:int, maxBinZ:int;

			/* is the sphere completely outside the "super brick"? */
			if (completelyOutside)
			{
				MapOverAllOutsideObjects(center, radius,func, clientQueryState);
				return;
			}

			/* compute min and max bin coordinates for each dimension */
			minBinX = int(((((center.x - radius) - Origin.x) / Size.x) * DivX));
			minBinY = int(((((center.y - radius) - Origin.y) / Size.y) * DivY));
			minBinZ = int(((((center.z - radius) - Origin.z) / Size.z) * DivZ));
			maxBinX = int(((((center.x + radius) - Origin.x) / Size.x) * DivX));
			maxBinY = int(((((center.y + radius) - Origin.y) / Size.y) * DivY));
			maxBinZ = int(((((center.z + radius) - Origin.z) / Size.z) * DivZ));

			/* clip bin coordinates */
			if (minBinX < 0) { partlyOut = 1; minBinX = 0; }
			if (minBinY < 0) { partlyOut = 1; minBinY = 0; }
			if (minBinZ < 0) { partlyOut = 1; minBinZ = 0; }
			if (maxBinX >= DivX) { partlyOut = 1; maxBinX = DivX - 1; }
			if (maxBinY >= DivY) { partlyOut = 1; maxBinY = DivY - 1; }
			if (maxBinZ >= DivZ) { partlyOut = 1; maxBinZ = DivZ - 1; }

			/* map function over outside objects if necessary (if clipped) */
			if (partlyOut != 0)
				MapOverAllOutsideObjects(center, radius,func, clientQueryState);

			/* map function over objects in bins */
			MapOverAllObjectsInLocalityClipped(
				center, radius,
				func,
				clientQueryState,
				minBinX, minBinY, minBinZ,
				maxBinX, maxBinY, maxBinZ);
		}

		/* Given a bin's list of client proxies, traverse the list and invoke
		the given lqCallBackFunction on each obj that falls within the
		search radius.  */
		public function TraverseBinClientObjectList(co:ClientProxy, radiusSquared:Number,func:Function, state:Object,position:Vector3):ClientProxy
		{
			while (co != null)
			{
				// compute distance (squared) from this client obj to given
				// locality sphere's centerpoint
				var d:Vector3 = Vector3.VectorSubtraction(position, co.Position);
				var distanceSquared:Number = d.SquaredMagnitude();

				// apply function if client obj within sphere
				if (distanceSquared < radiusSquared)
					func.call(null,{clientObject:co.Obj, objectDistanceSquared: distanceSquared,objectState: state});

				// consider next client obj in bin list
				co = co.Next;
			}
			return co;
		}

		/* This subroutine of lqMapOverAllObjectsInLocality efficiently
		   traverses of subset of bins specified by max and min bin
		   coordinates. */
		public function MapOverAllObjectsInLocalityClipped(center:Vector3, radius:Number,
							   func:Function,
							   clientQueryState:Object,
							   minBinX:int, minBinY:int, minBinZ:int,
							   maxBinX:int, maxBinY:int, maxBinZ:int):void
		{
			var i:int, j:int, k:int;
			var iindex:int, jindex:int, kindex:int;
			var slab:int = DivY * DivZ;
			var row:int = DivZ;
			var istart:int = minBinX * slab;
			var jstart:int = minBinY * row;
			var kstart:int = minBinZ;
			var co:ClientProxy;
			var bin:ClientProxy;
			var radiusSquared:Number = radius * radius;

			/* loop for x bins across diameter of sphere */
			iindex = istart;
			for (i = minBinX; i <= maxBinX; i++)
			{
				/* loop for y bins across diameter of sphere */
				jindex = jstart;
				for (j = minBinY; j <= maxBinY; j++)
				{
					/* loop for z bins across diameter of sphere */
					kindex = kstart;
					for (k = minBinZ; k <= maxBinZ; k++)
					{
						/* get current bin's client obj list */
						bin = bins[iindex + jindex + kindex];
						co = bin;

						/* traverse current bin's client obj list */
						co = TraverseBinClientObjectList(co,
							radiusSquared,
							func,
							clientQueryState,
							center);
						kindex += 1;
					}
					jindex += row;
				}
				iindex += slab;
			}
		}

		/* If the query region (sphere) extends outside of the "super-brick"
		   we need to check for objects in the catch-all "other" bin which
		   holds any object which are not inside the regular sub-bricks  */
		public function MapOverAllOutsideObjects(center:Vector3, radius:Number,func:Function, clientQueryState:Object):void
		{
			var co:ClientProxy = bins[bins.length - 1];
			var radiusSquared:Number = radius * radius+0.0;

			// traverse the "other" bin's client object list
			co = TraverseBinClientObjectList(co, radiusSquared,func, clientQueryState, center);
		}

		/* public helper function */
		public function MapOverAllObjectsInBin(binProxyList:ClientProxy,func:Function, clientQueryState:Object):void
		{
			// walk down proxy list, applying call-back function to each one
			while (binProxyList != null)
			{
				func.call(null,{clientObject:binProxyList.Obj, objectDistanceSquared:0, objectState:clientQueryState});
				binProxyList = binProxyList.Next;
			}
		}

		/* Apply a user-supplied function to all objects in the database,
		   regardless of locality (cf lqMapOverAllObjectsInLocality) */
		public function MapOverAllObjects(func:Function,clientQueryState:Object):void
		{
			for (var i:int = 0; i < bins.length; i++)
			{
				MapOverAllObjectsInBin(bins[i],func, clientQueryState);
			}
			//MapOverAllObjectsInBin(other, func, clientQueryState);
		}

		/* Removes a given client obj from its current bin, unlinking it
		   from the bin contents list. */
		public function RemoveFromBin(obj:ClientProxy):ClientProxy
		{
			/* adjust pointers if obj is currently in a bin */
			if (obj.Bin != 0)
			{
				/* If this obj is at the head of the list, move the bin
				   pointer to the next item in the list (might be null). */
				if (bins[obj.Bin] == obj)
					bins[obj.Bin] = obj.Next;

				/* If there is a prev obj, link its "next" pointer to the
				   obj after this one. */
				if (obj.Prev != null)
					obj.Prev.Next = obj.Next;

				/* If there is a next obj, link its "prev" pointer to the
				   obj before this one. */
				if (obj.Next != null)
					obj.Next.Prev = obj.Prev;
			}

			/* Null out prev, next and bin pointers of this obj. */
			obj.Prev = null;
			obj.Next = null;
			obj.Bin = 0;
			return obj;
		}

		/* Removes (all proxies for) all objects from all bins */
		public function RemoveAllObjects():void
		{
			for (var i:int = 0; i < bins.length; i++)
			{
				bins[i] = RemoveAllObjectsInBin(bins[i]);
			}
			//RemoveAllObjectsInBin(ref other);
		}

		/* public helper function */
		private function RemoveAllObjectsInBin(bin:ClientProxy):ClientProxy
		{
			while (bin != null)
			{
				bin = RemoveFromBin(bin);
			}
			return bin;
		}

		private static function FindNearestHelper(clientObject:Object, distanceSquared:Number,clientQueryState:Object):void
		{
			var fns:FindNearestState = FindNearestState(clientQueryState);
			
			/* do nothing if this is the "ignoreObject" */
			if (fns.ignoreObject != clientObject)
			{
				/* record this object if it is the nearest one so far */
				if (fns.minDistanceSquared > distanceSquared)
				{
					fns.nearestObject = clientObject;
					fns.minDistanceSquared = distanceSquared;
				}
			}
		}

		/* Search the database to find the object whose key-point is nearest
		   to a given location yet within a given radius.  That is, it finds
		   the object (if any) within a given search sphere which is nearest
		   to the sphere's center.  The ignoreObject argument can be used to
		   exclude an object from consideration (or it can be NULL).  This is
		   useful when looking for the nearest neighbor of an object in the
		   database, since otherwise it would be its own nearest neighbor.
		   The function returns a void* pointer to the nearest object, or
		   NULL if none is found.  */
		public function FindNearestNeighborWithinRadius(center:Vector3, radius:Number, ignoreObject:Object):Object
		{
			/* initialize search state */
			var lqFNS:FindNearestState;
			lqFNS.nearestObject = null;
			lqFNS.ignoreObject = ignoreObject;
			lqFNS.minDistanceSquared = Number.MAX_VALUE;

			/* map search helper function over all objects within radius */
			MapOverAllObjectsInLocality(center, radius, FindNearestHelper, lqFNS);

			/* return nearest object found, if any */
			return lqFNS.nearestObject;
		}
	}
}

class FindNearestState extends Object
{
	public var ignoreObject:Object;
	public var nearestObject:Object;
	public var minDistanceSquared:Number;

}
