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
	/** A steerable point mass with a velocity-aligned local coordinate system.
	* SimpleVehicle is useful for developing prototype vehicles in OpenSteerDemo,
	* it is the base class for vehicles in the PlugIns supplied with OpenSteer.
	* Note that SimpleVehicle is provided only as sample code.  Your application
	* can use the OpenSteer library without using SimpleVehicle, as long as you
	* implement the AbstractVehicle protocol.
	* 
	* In OpenSteer, vehicles are defined by an interface: an abstract base class
	* called AbstractVehicle.  Implementations of that interface, and related
	* functionality (like steering behaviors and vehicle physics) are provided as
	* template-based mixin classes.  The intent of this design is to allow you to
	* reuse OpenSteer code with your application's own base class.
	*/
	public class SimpleVehicle extends SteerLibrary
	{
		var _mass:Number;// mass (defaults to unity so acceleration=force)
		var _radius:Number;// size of bounding sphere, for obstacle avoidance, etc.
		var _speed:Number;// speed along Forward direction.  Because local space
		// is velocity-aligned, velocity = Forward * Speed

		var _maxForce:Number;// the maximum steering force this vehicle can apply
		// (steering force is clipped to this magnitude)

		var _maxSpeed:Number;// the maximum speed this vehicle is allowed to move
		// (velocity is clipped to this magnitude)

		var _curvature:Number;
		var _lastForward:Vector3;
		var _lastPosition:Vector3;
		var _smoothedPosition:Vector3;
		var _smoothedCurvature:Number;
		var _smoothedAcceleration:Vector3;

		static var serialNumberCounter:int=0;

		var serialNumber:int;
		// Constructor

		public function SimpleVehicle()
		{
			// set inital state
			reset();

			// maintain unique serial numbers
			serialNumber=serialNumberCounter++;
		}

		// Reset vehicle state
		public function reset():void
		{
			// reset LocalSpace state
			resetLocalSpace();

			// reset SteerLibraryMixin state
			// (XXX this seems really fragile, needs to be redesigned XXX)
			resetSteering();

			setMass(1);// mass (defaults to 1 so acceleration=force)
			setSpeed(0);// speed along Forward direction.

			setRadius(0.5);// size of bounding sphere

			setMaxForce(0.1);// steering force is clipped to this magnitude
			setMaxSpeed(1.0);// velocity is clipped to this magnitude

			// reset bookkeeping to do running averages of these quanities
			resetSmoothedPosition(Vector3.ZERO);
			resetSmoothedCurvature(0);//Vector3.ZERO);
			resetSmoothedAcceleration(Vector3.ZERO);
		}

		// get/set mass
		public override  function mass():Number
		{
			return _mass;
		}
		public override  function setMass(m:Number):Number
		{
			return _mass=m;
		}

		// get velocity of vehicle
		public override  function velocity():Vector3
		{
			return Vector3.ScalarMultiplication1(forward() , speed());
		}

		// get/set speed of vehicle  (may be faster than taking mag of velocity)
		public override  function speed():Number
		{
			return _speed;
		}
		public override  function setSpeed(s:Number):Number
		{
			return _speed=s;
		}

		// size of bounding sphere, for obstacle avoidance, etc.
		public override  function radius():Number
		{
			return _radius;
		}
		public override  function setRadius(m:Number):Number
		{
			return _radius=m;
		}

		// get/set maxForce
		public override  function maxForce():Number
		{
			return _maxForce;
		}
		public override  function setMaxForce(mf:Number):Number
		{
			return _maxForce=mf;
		}

		// get/set maxSpeed
		public override  function maxSpeed():Number
		{
			return _maxSpeed;
		}
		public override  function setMaxSpeed(ms:Number):Number
		{
			return _maxSpeed=ms;
		}

		// get instantaneous curvature (since last update)
		function curvature():Number
		{
			return _curvature;
		}

		// get/reset smoothedCurvature, smoothedAcceleration and smoothedPosition
		function smoothedCurvature():Number
		{
			return _smoothedCurvature;
		}
		function resetSmoothedCurvature(value:Number):Number
		{
			_lastForward=Vector3.ZERO;
			_lastPosition=Vector3.ZERO;

			return _smoothedCurvature=_curvature=value;
		}
		function smoothedAcceleration():Vector3
		{
			return _smoothedAcceleration;
		}
		function resetSmoothedAcceleration(value:Vector3):Vector3
		{
			return _smoothedAcceleration=value;
		}
		function smoothedPosition():Vector3
		{
			return _smoothedPosition;
		}
		function resetSmoothedPosition(value:Vector3):Vector3
		{
			return _smoothedPosition=value;
		}

		function randomizeHeadingOnXZPlane():void
		{
			setUp(Vector3.UNIT_Y);
			setForward(Utility.RandomUnitVectorOnXZPlane());
			setSide(localRotateForwardToSide(forward()));
		}

		// From CPP
		// ----------------------------------------------------------------------------
		// adjust the steering force passed to applySteeringForce.
		//
		// allows a specific vehicle class to redefine this adjustment.
		// default is to disallow backward-facing steering at low speed.
		//
		// xxx should the default be this ad-hocery, or no adjustment?
		// xxx experimental 8-20-02
		//
		// parameter names commented out to prevent compiler warning from "-W"
		public function adjustRawSteeringForce(force:Vector3):Vector3
		{
			var maxAdjustedSpeed:Number=0.2 * maxSpeed();

			if (speed() > maxAdjustedSpeed || force == Vector3.ZERO)
			{
				return force;
			}
			else
			{
				var range:Number=speed() / maxAdjustedSpeed;
				var cosine:Number=Utility.interpolate2(Number(Math.pow(range,20)),1.0,-1.0);
				return Utility.limitMaxDeviationAngle(force,cosine,forward());
			}
		}


		// ----------------------------------------------------------------------------
		// xxx experimental 9-6-02
		//
		// apply a given braking force (for a given dt) to our momentum.
		//
		// (this is intended as a companion to applySteeringForce, but I'm not sure how
		// well integrated it is.  It was motivated by the fact that "braking" (as in
		// "capture the flag" endgame) by using "forward * speed * -rate" as a steering
		// force was causing problems in adjustRawSteeringForce.  In fact it made it
		// get NAN, but even if it had worked it would have defeated the braking.
		//
		// maybe the guts of applySteeringForce should be split off into a subroutine
		// used by both applySteeringForce and applyBrakingForce?

		function applyBrakingForce(rate:Number,deltaTime:Number):void
		{
			var rawBraking:Number=speed() * rate;
			var clipBraking:Number=rawBraking < maxForce()?rawBraking:maxForce();

			setSpeed(speed() - (clipBraking * deltaTime));
		}

		// ----------------------------------------------------------------------------
		// apply a given steering force to our momentum,
		// adjusting our orientation to maintain velocity-alignment.
		public function applySteeringForce(force:Vector3,elapsedTime:Number):void
		{
			
			var adjustedForce:Vector3=adjustRawSteeringForce(force);//, elapsedTime);
			var clippedForce:Vector3=truncateLength(adjustedForce,maxForce());

			// compute acceleration and velocity
			var newAcceleration:Vector3=Vector3.ScalarDivision(clippedForce , mass());
			var newVelocity:Vector3=velocity();

			// damp out abrupt changes and oscillations in steering acceleration
			// (rate is proportional to time step, then clipped into useful range)
			if (elapsedTime > 0)
			{
				var smoothRate:Number=Utility.clip(9 * elapsedTime,0.15,0.4);
				_smoothedAcceleration=Utility.blendIntoAccumulator(smoothRate,newAcceleration,_smoothedAcceleration);
			}

			// Euler integrate (per frame) acceleration into velocity
			newVelocity = Vector3.VectorAddition(newVelocity,Vector3.ScalarMultiplication1(_smoothedAcceleration , elapsedTime));

			// enforce speed limit
			newVelocity= truncateLength(newVelocity,maxSpeed());

			// update Speed
			setSpeed(newVelocity.Length());

			// Euler integrate (per frame) velocity into position
			setPosition(Vector3.VectorAddition(Position() , Vector3.ScalarMultiplication1(newVelocity , elapsedTime)));

			// regenerate local space (by default: align vehicle's forward axis with
			// new velocity, but this behavior may be overridden by derived classes.)
			regenerateLocalSpace(newVelocity);//, elapsedTime);

			// maintain path curvature information
			measurePathCurvature(elapsedTime);

			// running average of recent positions
			_smoothedPosition=Utility.blendIntoAccumulator(elapsedTime * 0.06,Position(),_smoothedPosition);
		}


		// ----------------------------------------------------------------------------
		// the default version: keep FORWARD parallel to velocity, change UP as
		// little as possible.
		//
		// parameter names commented out to prevent compiler warning from "-W"
		function regenerateLocalSpace(newVelocity:Vector3):void
		{
			// adjust orthonormal basis vectors to be aligned with new velocity
			if (speed() > 0)
			{
				regenerateOrthonormalBasisUF(Vector3.ScalarDivision(newVelocity , speed()));
			}
		}

		// ----------------------------------------------------------------------------
		// alternate version: keep FORWARD parallel to velocity, adjust UP according
		// to a no-basis-in-reality "banking" behavior, something like what birds and
		// airplanes do

		// XXX experimental cwr 6-5-03
		public function regenerateLocalSpaceForBanking(newVelocity:Vector3,elapsedTime:Number):void
		{
			// the length of this global-upward-pointing vector controls the vehicle's
			// tendency to right itself as it is rolled over from turning acceleration
			var globalUp:Vector3=new Vector3(0,0.2,0);

			// acceleration points toward the center of local path curvature, the
			// length determines how much the vehicle will roll while turning
			var accelUp:Vector3=Vector3.ScalarMultiplication1(_smoothedAcceleration , 0.05);

			// combined banking, sum of UP due to turning and global UP
			var bankUp:Vector3=Vector3.VectorAddition(accelUp , globalUp);

			// blend bankUp into vehicle's UP basis vector
			var smoothRate:Number=elapsedTime * 3;
			var tempUp:Vector3=up();
			tempUp=Utility.blendIntoAccumulator(smoothRate,bankUp,tempUp);
			tempUp.Normalise();
			setUp(tempUp);

			// adjust orthonormal basis vectors to be aligned with new velocity
			if (speed() > 0)
			{
				regenerateOrthonormalBasisUF(Vector3.ScalarDivision(newVelocity , speed()));
			}
		}

		// ----------------------------------------------------------------------------
		// measure path curvature (1/turning-radius), maintain smoothed version
		function measurePathCurvature(elapsedTime:Number):void
		{
			if (elapsedTime > 0)
			{
				var dP:Vector3=Vector3.VectorSubtraction(_lastPosition , Position());
				var dF:Vector3=Vector3.VectorSubtraction(_lastForward , Vector3.ScalarDivision(forward() , dP.Length()));
				//SI - BIT OF A WEIRD FIX HERE . NOT SURE IF ITS CORRECT
				var lateral:Vector3=Utility.perpendicularComponent(dF,forward());

				var sign:Number=lateral.DotProduct(side()) < 0?1.0:-1.0;
				_curvature=lateral.Length() * sign;
				_smoothedCurvature=Utility.blendIntoAccumulator2(elapsedTime * 4.0,_curvature,_smoothedCurvature);

				_lastForward=forward();
				_lastPosition=Position();
			}
		}

		// ----------------------------------------------------------------------------
		// draw lines from vehicle's position showing its velocity and acceleration
		function annotationVelocityAcceleration(maxLengthA:Number,maxLengthV:Number):void
		{
			var desat:Number=0.4;
			var aScale:Number=maxLengthA / maxForce();
			var vScale:Number=maxLengthV / maxSpeed();
			var p:Vector3=Position();
			var aColor:Vector3=new Vector3(desat,desat,1);// bluish
			var vColor:Vector3=new Vector3(1,desat,1);// pinkish
		}


		// ----------------------------------------------------------------------------
		// predict position of this vehicle at some time in the future
		// (assumes velocity remains constant, hence path is a straight line)
		//
		// XXX Want to encapsulate this since eventually I want to investigate
		// XXX non-linear predictors.  Maybe predictFutureLocalSpace ?
		//
		// XXX move to a vehicle utility mixin?
		public override  function predictFuturePosition(predictionTime:Number):Vector3
		{
			return Vector3.VectorAddition(Position(), Vector3.ScalarMultiplication1(velocity() , predictionTime));
		}
		// ----------------------------------------------------------------------------
	}
}