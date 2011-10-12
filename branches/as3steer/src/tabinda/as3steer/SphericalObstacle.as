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
	 *  SphericalObstacle a simple concrete type of obstacle
	 */
	public class SphericalObstacle extends Obstacle
	{

		public var radius:Number;
		public var center:Vector3;

		private var _seenFrom:String;

		// constructors
		public function SphericalObstacle(...args):void
		{
			if (args.length == 2)
			{
				radius=args[0];
				center = args[1];
			}
			else
			{
				radius = 1;
				center = Vector3.ZERO;
			}
		}

		// XXX 4-23-03: Temporary work around (see comment above)
		//
		// Checks for intersection of the given spherical obstacle with a
		// volume of "likely future vehicle positions": a cylinder along the
		// current path, extending minTimeToCollision seconds along the
		// forward axis from current position.
		//
		// If they intersect, a collision is imminent and this function returns
		// a steering force pointing laterally away from the obstacle's center.
		//
		// Returns a zero vector if the obstacle is outside the cylinder
		//
		// xxx couldn't this be made more compact using localizePosition?

		public override function steerToAvoid(v:AbstractVehicle,minTimeToCollision:Number):Vector3
		{
			// minimum distance to obstacle before avoidance is required
			var minDistanceToCollision:Number=minTimeToCollision * v.speed;
			var minDistanceToCenter:Number=minDistanceToCollision + radius;

			// contact distance: sum of radii of obstacle and vehicle
			var totalRadius:Number=radius + v.radius;

			// obstacle center relative to vehicle position
			var localOffset:Vector3=Vector3.VectorSubtraction(center , v.Position);

			// distance along vehicle's forward axis to obstacle's center
			var forwardComponent:Number=localOffset.DotProduct(v.forward);
			var forwardOffset:Vector3=Vector3.ScalarMultiplication(forwardComponent, v.forward);

			// offset from forward axis to obstacle's center
			var offForwardOffset:Vector3=Vector3.VectorSubtraction(localOffset, forwardOffset);

			// test to see if sphere overlaps with obstacle-free corridor
			var inCylinder:Boolean=offForwardOffset.Magnitude() < totalRadius;
			var nearby:Boolean=forwardComponent < minDistanceToCenter;
			var inFront:Boolean=forwardComponent > 0;

			// if all three conditions are met, steer away from sphere center
			if (inCylinder && nearby && inFront)
			{
				return Vector3.ScalarMultiplication(-1,offForwardOffset);
			}
			else
			{
				return Vector3.ZERO;
			}
		}
		override public function get SeenFrom():String
		{
			return _seenFrom;
		}
		
		override public function set SeenFrom(value:String):void 
		{
			_seenFrom = value;
		}
	}
}