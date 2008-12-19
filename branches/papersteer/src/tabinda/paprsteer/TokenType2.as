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
	public class TokenType2 implements ITokenForProximityDatabase
	{
		var proxy:ClientProxy;
		var lq:LQDatabase;

		// constructor
		public function TokenType2(parentObject:Object, lqsd:LQProximityDatabase):void
		{
			proxy = new ClientProxy(parentObject);
			lq = lqsd.lq;
		}

		public function Dispose():void
		{
			Dispose2(true);
			System.gc();
		}
		protected function Dispose2(disposing:Boolean):void
		{
			if (proxy != null)
			{
				//System.Diagnostics.Debug.Assert(disposing == true);

				// remove this token from the database's vector
				proxy = lq.RemoveFromBin(proxy);
				proxy = null;
			}
		}

		// the client obj calls this each time its position changes
		public function UpdateForNewPosition(p:Vector3):void
		{
			proxy = lq.UpdateForNewLocation(proxy, p);
		}

		// find all neighbors within the given sphere (as center and radius)
		public function FindNeighbors(center:Vector3, radius:Number, results:Vector.<IVehicle>):Vector.<IVehicle> 
		{
			lq.MapOverAllObjectsInLocality(center, radius, perNeighborCallBackFunction, results);
			return results;
		}

		// called by LQ for each clientObject in the specified neighborhood:
		// push that clientObject onto the ContentType vector in void*
		// clientQueryState
		public static function perNeighborCallBackFunction(clientObject:Object, distanceSquared:Number, clientQueryState:Object):void
		{
			var results:Vector = clientQueryState as Vector;
			results.push(Object(clientObject));
		}
	}
}