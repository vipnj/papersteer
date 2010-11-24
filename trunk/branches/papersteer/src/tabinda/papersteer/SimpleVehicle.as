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
	import flash.display.Sprite;
	import org.papervision3d.core.geom.TriangleMesh3D;
	
	public class SimpleVehicle extends SteerLibrary
	{
		public var objectMesh:TriangleMesh3D;			// For Papervision3D
		
		// give each vehicle a unique number
		private var _SerialNumber:int;
		private static var serialNumberCounter:int =0;

		// Mass (defaults to unity so acceleration=force)
		private var mass:Number;

		// size of bounding sphere, for obstacle avoidance, etc.
		private var radius:Number;

		// speed along Forward direction. Because local space is
		// velocity-aligned, velocity = Forward * Speed
		private var speed:Number;

		// the maximum steering force this vehicle can apply
		// (steering force is clipped to this magnitude)
		private var maxForce:Number;

		// the maximum speed this vehicle is allowed to move
		// (velocity is clipped to this magnitude)
		private var maxSpeed:Number;

		private var curvature:Number;
		private var lastForward:Vector3;
		private var lastPosition:Vector3;
		private var smoothedPosition:Vector3;
		private var smoothedCurvature:Number;
		// The acceleration is smoothed
		private var acceleration:Vector3;

		// constructor
		public function SimpleVehicle ()
		{
			// set inital state
			Reset ();

			// maintain unique serial numbers
			_SerialNumber=serialNumberCounter++;
		}

		// reset vehicle state
		override public function Reset ():void
		{
			// reset LocalSpace state
			ResetLocalSpace ();

			// reset SteerLibraryMixin state
			//FIXME: this is really fragile, needs to be redesigned
			super.Reset ();

			Mass=1.0;// Mass (defaults to 1 so acceleration=force)
			Speed=0.0;// speed along Forward direction.

			Radius=0.5;// size of bounding sphere

			MaxForce=0.1;// steering force is clipped to this magnitude
			MaxSpeed=1.0;// velocity is clipped to this magnitude

			// reset bookkeeping to do running averages of these quanities
			ResetSmoothedPosition (Vector3.Zero);
			ResetSmoothedCurvature ();
			ResetAcceleration ();
		}

		// get/set Mass
		public override function get Mass ():Number
		{
			return mass;
		}
		public override function set Mass (val:Number):void
		{
			mass=val;
		}

		// get velocity of vehicle
		public override function get Velocity ():Vector3
		{
			return Vector3.ScalarMultiplication(speed,Forward);
		}

		// get/set speed of vehicle  (may be faster than taking mag of velocity)
		public override function get Speed ():Number
		{
			return speed;
		}
		public override function set Speed (val:Number):void
		{
			speed=val;
		}

		// size of bounding sphere, for obstacle avoidance, etc.
		public override function get Radius ():Number
		{
			return radius;
		}
		public override  function set Radius (val:Number):void
		{
			radius=val;
		}

		// get/set maxForce
		public override function get MaxForce ():Number
		{
			return maxForce;
		}
		public override function set MaxForce (val:Number):void
		{
			maxForce=val;
		}

		// get/set maxSpeed
		public override function get MaxSpeed ():Number
		{
			return maxSpeed;
		}
		public override function set MaxSpeed (val:Number):void
		{
			maxSpeed=val;
		}


		// apply a given steering force to our momentum,
		// adjusting our orientation to maintain velocity-alignment.
		public function ApplySteeringForce (force:Vector3,elapsedTime:Number):void
		{
			var adjustedForce:Vector3=AdjustRawSteeringForce(force,elapsedTime);
			
			// enforce limit on magnitude of steering force
			var clippedForce:Vector3 = VHelper.TruncateLength(adjustedForce,MaxForce);

			// compute acceleration and velocity
			var newAcceleration:Vector3=Vector3.ScalarMultiplication(1/Mass,clippedForce);
			var newVelocity:Vector3=Velocity;

			// damp out abrupt changes and oscillations in steering acceleration
			// (rate is proportional to time step, then clipped into useful range)
			if (elapsedTime > 0)
			{
				var smoothRate:Number=Utilities.Clip(9 * elapsedTime,0.15,0.4);
				acceleration = Utilities.BlendIntoAccumulator2 (smoothRate, newAcceleration, acceleration);
			}

			// Euler integrate (per frame) acceleration into velocity
			newVelocity = Vector3.VectorAddition(newVelocity,Vector3.ScalarMultiplication(elapsedTime,acceleration));

			// enforce speed limit
			newVelocity=VHelper.TruncateLength(newVelocity,MaxSpeed);

			// update Speed
			Speed=newVelocity.Magnitude();

			// Euler integrate (per frame) velocity into position
			Position=Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(elapsedTime,newVelocity));

			// regenerate local space (by default: align vehicle's forward axis with
			// new velocity, but this behavior may be overridden by derived classes.)
			RegenerateLocalSpace (newVelocity,elapsedTime);

			// maintain path curvature information
			MeasurePathCurvature (elapsedTime);

			// running average of recent positions
			smoothedPosition = Utilities.BlendIntoAccumulator2 (elapsedTime * 0.06, Position, smoothedPosition);
		}

		// the default version: keep FORWARD parallel to velocity, change
		// UP as little as possible.
		public function RegenerateLocalSpace (newVelocity:Vector3,elapsedTime:Number):void
		{
			// adjust orthonormal basis vectors to be aligned with new velocity
			if (Speed > 0)
			{
				RegenerateOrthonormalBasisUF (Vector3.ScalarMultiplication(1/Speed,newVelocity));
			}
		}

		// alternate version: keep FORWARD parallel to velocity, adjust UP
		// according to a no-basis-in-reality "banking" behavior, something
		// like what birds and airplanes do.  (XXX experimental cwr 6-5-03)
		public function RegenerateLocalSpaceForBanking (newVelocity:Vector3,elapsedTime:Number):void
		{
			// the length of this global-upward-pointing vector controls the vehicle's
			// tendency to right itself as it is rolled over from turning acceleration
			var globalUp:Vector3=new Vector3(0,0.2,0);

			// acceleration points toward the center of local path curvature, the
			// length determines how much the vehicle will roll while turning
			var accelUp:Vector3=Vector3.ScalarMultiplication(0.05,acceleration);

			// combined banking, sum of UP due to turning and global UP
			var bankUp:Vector3=Vector3.VectorAddition(accelUp , globalUp);

			// blend bankUp into vehicle's UP basis vector
			var smoothRate:Number=elapsedTime * 3.0;
			var tempUp:Vector3=Up;
			tempUp = Utilities.BlendIntoAccumulator2 (smoothRate,bankUp,tempUp);
			Up=tempUp;
			Up.Normalize ();

			annotation.Line (Position,Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(4,globalUp)),0xFFFFFF);
			annotation.Line (Position,Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(4,bankUp)),0xFF9900);
			annotation.Line (Position,Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(4,accelUp)),0xCC0000);
			annotation.Line (Position,Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(1,Up)),0xFFFF00);

			// adjust orthonormal basis vectors to be aligned with new velocity
			if (Speed > 0)
			{
				RegenerateOrthonormalBasisUF (Vector3.ScalarMultiplication(1/Speed,newVelocity));
			}
		}

		// adjust the steering force passed to applySteeringForce.
		// allows a specific vehicle class to redefine this adjustment.
		// default is to disallow backward-facing steering at low speed.
		// xxx experimental 8-20-02
		public function AdjustRawSteeringForce (force:Vector3,deltaTime:Number):Vector3
		{
			var maxAdjustedSpeed:Number=0.2 * MaxSpeed;

			if (Speed > maxAdjustedSpeed || Vector3.isEqual(force, Vector3.Zero))
			{
				return force;
			}
			else
			{
				var range:Number=(Speed / maxAdjustedSpeed);
				var cosine:Number = Utilities.Interpolate(Number(Math.pow(range, 20)), 1.0, -1.0);
				return VHelper.LimitMaxDeviationAngle(force,cosine,Forward);
			}
		}

		// apply a given braking force (for a given dt) to our momentum.
		// xxx experimental 9-6-02
		public function ApplyBrakingForce (rate:Number,deltaTime:Number):void
		{
			var rawBraking:Number=(Speed * rate);
			var clipBraking:Number=((rawBraking < MaxForce)?rawBraking:MaxForce);
			Speed=(Speed - (clipBraking * deltaTime));
		}

		// predict position of this vehicle at some time in the future
		// (assumes velocity remains constant)
		public override  function PredictFuturePosition (predictionTime:Number):Vector3
		{
			return Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(predictionTime,Velocity));
		}

		// get instantaneous curvature (since last update)
		public function get Curvature ():Number
		{
			return curvature;
		}

		// get/reset smoothedCurvature, smoothedAcceleration and smoothedPosition
		public function get SmoothedCurvature ():Number
		{
			return smoothedCurvature;
		}
		public function ResetSmoothedCurvature ():Number
		{
			return ResetSmoothedCurvature2(0);
		}
		public function ResetSmoothedCurvature2 (val:Number):Number
		{
			lastForward=Vector3.Zero;
			lastPosition=Vector3.Zero;
			return smoothedCurvature=curvature=val;
		}

		public override function get Acceleration ():Vector3
		{
			return acceleration;
		}
		
		public function get SerialNumber():int { return _SerialNumber; }
		
		public function ResetAcceleration ():Vector3
		{
			return ResetAcceleration2(Vector3.Zero);
		}
		public function ResetAcceleration2 (val:Vector3):Vector3
		{
			return acceleration=val;
		}

		public function SmoothedPosition ():Vector3
		{
			return smoothedPosition;
		}
		public function callResetSmoothedPosition ():Vector3
		{
			return ResetSmoothedPosition(Vector3.Zero);
		}
		public function ResetSmoothedPosition (val:Vector3):Vector3
		{
			return smoothedPosition=val;
		}

		// set a random "2D" heading: set local Up to global Y, then effectively
		// rotate about it by a random angle (pick random forward, derive side).
		public function RandomizeHeadingOnXZPlane ():void
		{
			Up=Vector3.Up;
			Forward=VHelper.RandomUnitVectorOnXZPlane();
			Side=LocalRotateForwardToSide(Forward);
		}

		// measure path curvature (1/turning-radius), maintain smoothed version
		private function MeasurePathCurvature (elapsedTime:Number):void
		{
			if (elapsedTime > 0)
			{
				var dP:Vector3=Vector3.VectorSubtraction(lastPosition , Position);
				var dF:Vector3 = Vector3.ScalarMultiplication(1/dP.Magnitude(),Vector3.VectorSubtraction(lastForward , Forward));
				var lateral:Vector3=VHelper.PerpendicularComponent(dF,Forward);
				var sign:Number=lateral.DotProduct(Side) < 0?1.0:-1.0;
				curvature=lateral.Magnitude() * sign;
				smoothedCurvature = Utilities.BlendIntoAccumulator (elapsedTime * 4.0,curvature,smoothedCurvature);
				lastForward=Forward;
				lastPosition=Position;
			}
		}
	}
}