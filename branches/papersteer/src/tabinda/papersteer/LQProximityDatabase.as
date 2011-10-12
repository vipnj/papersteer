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
	/**
	 * @author Mohammad Haseeb
	 * @author Craig Reynolds
	 * 
	 * Location Query (LQ) Facility
	 * 
	 * A AbstractProximityDatabase-style wrapper for the LQ bin lattice system
	 * 
	 * <p>This utility is a spatial database which stores objects each of
	 * which is associated with a 3d point (a location in a 3d space).
	 * The points serve as the "search key" for the associated object.
	 * It is intended to efficiently answer "sphere inclusion" queries,
	 * also known as range queries: basically questions like:
     *
	 * Which objects are within a radius R of the location L?
     *
	 * In this context, "efficiently" means significantly faster than the
	 * naive, brute force O(n) testing of all known points.  Additionally
	 * it is assumed that the objects move along unpredictable paths, so
	 * that extensive preprocessing (for example, constructing a Delaunay
	 * triangulation of the point set) may not be practical.
     *
	 * The implementation is a "bin lattice": a 3d rectangular array of
	 * brick-shaped (rectangular parallelepipeds) regions of space.  Each
	 * region is represented by a pointer to a (possibly empty) doubly-
	 * linked list of objects.  All of these sub-bricks are the same
	 * size.  All bricks are aligned with the global coordinate axes.
     *
	 * Terminology used here: the region of space associated with a bin
	 * is called a sub-brick.  The collection of all sub-bricks is called
	 * the super-brick.  The super-brick should be specified to surround
	 * the region of space in which (almost) all the key-points will
	 * exist.  If key-points move outside the super-brick everything will
	 * continue to work, but without the speed advantage provided by the
	 * spatial subdivision.  For more details about how to specify the
	 * super-brick's position, size and subdivisions see lqCreateDatabase
	 * below.
     * 
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
     * 
	 * Note that "locality query" is also known as neighborhood query,
	 * neighborhood search, near neighbor search, and range query.  For
	 * additional information on this and related topics 
	 * http://www.red3d.com/cwr/boids/ips.html
     *
	 * For some description and illustrations of this database in use,
	 * this paper: http://www.red3d.com/cwr/papers/2000/pip.html
	 * </p>
	 */
	public class LQProximityDatabase implements IProximityDatabase
	{
		private var _lq:LQDatabase;

		/**
		 * Constructor
		 * @param	center
		 * @param	dimensions
		 * @param	divisions
		 */
        public function LQProximityDatabase(center:Vector3, dimensions:Vector3, divisions:Vector3)
		{
			var halfsize:Vector3 = Vector3.ScalarMultiplication(0.5,dimensions);
			var origin:Vector3 = Vector3.VectorSubtraction(center, halfsize);

			_lq = new LQDatabase(origin, dimensions, int(Math.round(divisions.x)), int(Math.round(divisions.y)), int(Math.round(divisions.z)));
		}

		/**
		 * Allocate a token to represent a given client obj in this database
		 * @param	parentObject
		 * @return
		 */
		public function AllocateToken(parentObject:Object):ITokenForProximityDatabase
		{
			return new TokenType(parentObject, this);
		}

		/**
		 * Count the number of tokens currently in the database
		 */
		public function get Count():int
		{
			var count:int = 0;
			lq.MapOverAllObjects(CounterCallBackFunction,count);
			return count;
		}
		
		/**
		 * Counter Call Back function to increase the Counter
		 * @param clientObject
		 * @param distanceSquared
		 * @param clientQueryState
		 */
		public static function CounterCallBackFunction(params:Object):void
		{
			var counter:int = int(params.objectState);
			counter++;
		}
		
		/******************************************************************************************
		* Getters and Setters
		* ****************************************************************************************/
		
		public function get lq():LQDatabase { return _lq; }
		public function set lq(value:LQDatabase):void { _lq = value; }
		
	}
}

import flash.system.System;
import tabinda.papersteer.*;

class TokenType implements ITokenForProximityDatabase
{
	private var proxy:ClientProxy;
	private var lq:LQDatabase;

	/**
	 * Constructor
	 * @param	parentObject
	 * @param	lqsd
	 */
	public function TokenType(parentObject:Object, lqsd:LQProximityDatabase):void
	{
		proxy = new ClientProxy(parentObject);
		lq = lqsd.lq;
	}

	/**
	 * Destroy the object forcefully.
	 */
	public function Dispose():void
	{
		if (proxy != null)
		{
			// remove this token from the database's vector
			proxy = lq.RemoveFromBin(proxy);
			proxy = null;
		}
		System.gc();
	}

	/**
	 * The client obj calls this each time its position changes
	 * @param	p Position Vector
	 */
	public function UpdateForNewPosition(p:Vector3):void
	{
		proxy = lq.UpdateForNewLocation(proxy, p);
	}

	/**
	 * Find all neighbors within the given sphere (as center and radius)
	 */ 
	public function FindNeighbors(center:Vector3, radius:Number, results:Vector.<IVehicle>):Vector.<IVehicle> 
	{
		lq.MapOverAllObjectsInLocality(center, radius, perNeighborCallBackFunction, results);
		return results;
	}

	/**
	 * Called by LQ for each clientObject in the specified neighborhood:
	 * push that clientObject onto the ContentType vector in void*
	 * clientQueryState
	 * 
	 * @param clientObject
	 * @param distanceSquared
	 * @param clientQueryState
	 */
	public static function perNeighborCallBackFunction(params:*):void
	{
		var results:* = params.objectState;
		results.push(params.clientObject);
	}
}