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
	 * pure virtual base class for generic steerable vehicles
	 */
	public class AbstractVehicle extends LocalSpace
	{
		/** mass (defaults to unity so acceleration=force)
		 */
		public function mass():Number
		{
			return 0;
		}
		public function setMass(mass:Number):Number
		{
			return 0;
		}

		/** size of bounding sphere, for obstacle avoidance, etc.
		 */
		public function radius():Number
		{
			return 0;
		}
		public function setRadius(radius:Number):Number
		{
			return 0;
		}

		/** velocity of vehicle
		 * 
		 */ 
		public function velocity():Vector3
		{
			return Vector3.ZERO;
		}

		/** speed of vehicle  (may be faster than taking magnitude of velocity)
		 * 
		 */ 
		public function speed():Number
		{
			return 0;
		}
		public function setSpeed(speed:Number):Number
		{
			return 0;
		}

		/**predict position of this vehicle at some time in the future
		 * (assumes velocity remains constant)
		 * 
		 */ 
		public function predictFuturePosition(predictionTime:Number):Vector3
		{
			return Vector3.ZERO;
		}

		/** ----------------------------------------------------------------------
		 * XXX this vehicle-model-specific functionality functionality seems out
		 * XXX of place on the abstract base class, but for now it is expedient
		 * the maximum steering force this vehicle can apply
		 * 
		 * @return
		 */ 
		public function maxForce():Number
		{
			return 0;
		}
		public function setMaxForce(max:Number):Number
		{
			return 0;
		}

		/** the maximum speed this vehicle is allowed to move
		 * 
		 */ 
		public function maxSpeed():Number
		{
			return 0;
		}
		public function setMaxSpeed(max:Number):Number
		{
			return 0;
		}
	}
}