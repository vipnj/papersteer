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

package tabinda.papersteer
{
	/// <summary>
	/// SphericalObstacle a simple concrete type of obstacle.
	/// </summary>
	public class SphericalObstacle implements IObstacle
	{
		var seenfrom:SeenFromState;

		public var Radius:Number;
        public var Center:Vector3D;

		// constructors
		/*public function SphericalObstacle()	extends this(1, Vector3.Zero)
		{
		}*/
        public function SphericalObstacle(r:Number, c:Vector3D)
		{
			Radius = r;
			Center = c;
		}

		public function get SeenFrom():SeenFromState
		{
			return seenfrom;
			
		}
		public function set SeenFrom(val:SeenFromState):void
		{
			seenfrom = val;
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

        public function SteerToAvoid(v:IVehicle , minTimeToCollision:Number): Vector3D
		{
			// minimum distance to obstacle before avoidance is required
			var minDistanceToCollision:Number = minTimeToCollision * v.Speed;
			var minDistanceToCenter:Number = minDistanceToCollision + Radius;

			// contact distance: sum of radii of obstacle and vehicle
			var totalRadius:Number = Radius + v.Radius;

			// obstacle center relative to vehicle position
			var localOffset: Vector3D = Vector3D.VectorSubtraction(Center, v.Position);

			// distance along vehicle's forward axis to obstacle's center
          	var forwardComponent:Number = localOffset.DotProduct(v.Forward);
			var forwardOffset: Vector3D = Vector3D.ScalarMultiplication(forwardComponent,v.Forward);

			// offset from forward axis to obstacle's center
			var offForwardOffset: Vector3D = Vector3D.VectorSubtraction(localOffset, forwardOffset);

			// test to see if sphere overlaps with obstacle-free corridor
			var inCylinder:Boolean = offForwardOffset.Magnitude() < totalRadius;
			var nearby:Boolean = forwardComponent < minDistanceToCenter;
			var inFront:Boolean = forwardComponent > 0;

			// if all three conditions are met, steer away from sphere center
			if (inCylinder && nearby && inFront)
			{
				return Vector3D.ScalarMultiplication(-1,offForwardOffset);
			}
			else
			{
                return Vector3D.Zero;
			}
		}
	}
}
