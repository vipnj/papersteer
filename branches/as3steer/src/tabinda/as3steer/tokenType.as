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
	 * "token" to represent objects stored in the database
	 */ 
	public class tokenType extends AbstractTokenForProximityDatabase
	{
		var proxy:lqClientProxy;
		var lq:locationQueryDatabase;

		// constructor
		public function tokenType(parentObject:Object,lqsd:LQProximityDatabase)
		{
			proxy=new lqClientProxy(parentObject);// lqInitClientProxy(proxy, parentObject);
			lq=lqsd.lq;
		}

		// the client object calls this each time its position changes
		public override function updateForNewPosition(p:Vector3):void
		{
			lq.lqUpdateForNewLocation(proxy,p.x,p.y,p.z);
		}

		// find all neighbors within the given sphere (as center and radius)
		public override function findNeighbors(center:Vector3,radius:Number,results:Array):void
		{
			var tList:Array=lq.getAllObjectsInLocality(center.x,center.y,center.z,radius);
			for (var i:int=0; i < tList.length; i++)
			{
				var tProxy:lqClientProxy=lqClientProxy(tList[i]);
				results.push(AbstractVehicle(tProxy.clientObject));
			}
		}
	}
}