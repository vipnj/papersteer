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
	import flash.system.System;
	
	// "token" to represent objects stored in the database
	public class TokenType implements ITokenForProximityDatabase
	{
		var bfpd:BruteForceProximityDatabase;
		var obj:Object;
		var position:Vector3;

		// constructor
		public function TokenType (parentObject:Object,pd:BruteForceProximityDatabase):void
		{
			// store pointer to our associated database and the obj this
			// token represents, and store this token on the database's vector
			bfpd=pd;
			obj=parentObject;
			bfpd.group.push(this);
			position = Vector3.Zero;
		}

		// destructor
		public function Dispose ():void
		{
			Dispose2 (true);
			System.gc();
		}
		protected function Dispose2 (disposing:Boolean):void
		{
			if (obj != null)
			{
				bfpd.group.some(check);
				obj=null;
			}
		}
		
		function check(item:TokenType, index:int, v:Vector.<TokenType>):Boolean
		{
			return item == this;
		}

		// the client obj calls this each time its position changes
		public function UpdateForNewPosition (newPosition:Vector3):void
		{
			position=newPosition;
		}

		// find all neighbors within the given sphere (as center and radius)
		public function FindNeighbors (center:Vector3,radius:Number,results:Vector.<IVehicle>):Vector.<IVehicle>
		{
			// loop over all tokens
			var r2:Number=radius * radius;
			for (var i:int=0; i < bfpd.group.length; i++)
			{
				trace(center,bfpd.group[i].obj);
				var offset:Vector3=Vector3.VectorSubtraction(center , bfpd.group[i].position);
				var d2:Number=offset.SquaredMagnitude();

				// push onto result vector when within given radius
				if (d2 < r2)
				{
					results.push (bfpd.group[i].obj);
				}
			}
			return results;
		}
	}
}