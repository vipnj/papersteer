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
	/**
	 *  This is the "brute force" O(n^2) approach implemented in terms of the
     *  AbstractProximityDatabase protocol so it can be compared directly to other
     *  approaches.  (e.g. the Boids plugin allows switching at runtime.)
	 */
	public class BruteForceProximityDatabase extends AbstractProximityDatabase
	{
		/** Array containing all tokens in database
		 * 
		 */ 
		public var group:Array;

		/** constructor
		 * 
		 */ 
		public function BruteForceProximityDatabase()
		{
			group=new Array();
		}


		/**allocate a token to represent a given client object in this database
		 * 
		 * @param	parentObject
		 * @return  AbstractTokenForProximityDatabase
		 */
		public override  function allocateToken(parentObject:AbstractVehicle):AbstractTokenForProximityDatabase
		{

			var tToken:token=new token(parentObject,this);
			return AbstractTokenForProximityDatabase(tToken);
		}

		/** return the number of tokens currently in the database
		 * 
		 * @return
		 */ 
		public override  function getPopulation():int
		{
			return group.length;
		}
	}
}

import tabinda.as3steer.*;

/**
 * "token" to represent objects stored in the database
 */ 
class token extends AbstractTokenForProximityDatabase
{
	private var _bfpd:BruteForceProximityDatabase;
	private var _tParentObject:AbstractVehicle;
	private var _position:Vector3;

	// constructor
	public function token(parentObject:AbstractVehicle,pd:BruteForceProximityDatabase)
	{
		// store pointer to our associated database and the object this
		// token represents, and store this token on the database's vector
		bfpd=pd;
		tParentObject=parentObject;
		bfpd.group.push(this);
	}

	// the client object calls this each time its position changes
	public override  function updateForNewPosition(newPosition:Vector3):void
	{
		position = newPosition;
	}

	// find all neighbors within the given sphere (as center and radius)
	public override function findNeighbors(center:Vector3,radius:Number,results:Array):void
	{
		// loop over all tokens
		var r2:Number=radius * radius;

		for (var i:int=0; i < bfpd.group.length; i++)
		{
			var tToken:token = token(bfpd.group[i]);
			var offset:Vector3=Vector3.VectorSubtraction(center , tToken.position);
			var d2:Number = offset.SquaredMagnitude();

			// push onto result vector when within given radius
			if (d2 < r2)
			{
				results.push(tToken.tParentObject);
			}//
		}
	}
	
	public function get bfpd():BruteForceProximityDatabase { return _bfpd; }
	
	public function set bfpd(value:BruteForceProximityDatabase):void 
	{
		_bfpd = value;
	}
	
	public function get tParentObject():AbstractVehicle { return _tParentObject; }
	
	public function set tParentObject(value:AbstractVehicle):void 
	{
		_tParentObject = value;
	}
	
	public function get position():Vector3 { return _position; }
	
	public function set position(value:Vector3):void 
	{
		_position = value;
	}
}