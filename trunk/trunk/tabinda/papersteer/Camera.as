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
	public class Camera extends LocalSpace
	{
		// xxx since currently (10-21-02) the camera's Forward and Side basis
		// xxx vectors are not being set, construct a temporary local space for
		// xxx the camera view -- so as not to make the camera behave
		// xxx differently (which is to say, correctly) during mouse adjustment.
		
		var ls:LocalSpace;
		
		public function xxxls ():LocalSpace
		{
			ls.RegenerateOrthonormalBasis2 (Vector3D.VectorSubtraction(Target, Position),Up);
			return ls;
		}

		// "look at" point, center of view
		public var Target:Vector3D;

		// vehicle being tracked
		public var VehicleToTrack:IVehicle;

		// aim at predicted position of vehicleToTrack, this far into thefuture
		public var AimLeadTime:Number;
		protected var smoothNextMove:Boolean;
		protected var smoothMoveSpeed:Number;

		// current mode for this camera instance
		public var Mode:String;

		// "static" camera mode parameters
		public var FixedPosition:Vector3D;
		public var FixedTarget:Vector3D;
		public var FixedUp:Vector3D;

		// "constant distance from vehicle" camera mode parameters
		public var FixedDistanceDistance:Number;// desired distance from it
		public var FixedDistanceVerticalOffset:Number;// fixed vertical offset from it

		// "look straight down at vehicle" camera mode parameters
		public var LookDownDistance:Number;// fixed vertical offset from it

		// "fixed local offset" camera mode parameters
		public var FixedLocalOffset:Vector3D;

		// "offset POV" camera mode parameters
		public var PovOffset:Vector3D;

		// constructor
		public function Camera ()
		{
			Reset ();
		}

		// reset all camera state to default values
		public function Reset ():void
		{
			// reset camera's position and orientation
			ResetLocalSpace ();

			ls=new LocalSpace();

			// "look at" point, center of view
			Target=Vector3D.Zero;

			// vehicle being tracked
			VehicleToTrack=null;

			// aim at predicted position of vehicleToTrack, this far into thefuture
			AimLeadTime=1;

			// make first update abrupt
			smoothNextMove=false;

			// relative rate at which camera transitions proceed
			smoothMoveSpeed=1.5;

			// select camera aiming mode
			Mode=CameraMode.Fixed;

			// "constant distance from vehicle" camera mode parameters
			FixedDistanceDistance=1;
			FixedDistanceVerticalOffset=0;

			// "look straight down at vehicle" camera mode parameters
			LookDownDistance=30;

			// "static" camera mode parameters
			FixedPosition=new Vector3D(75,75,75);
			FixedTarget=Vector3D.Zero;
			FixedUp=Vector3D.Up;

			// "fixed local offset" camera mode parameters
			FixedLocalOffset=new Vector3D(5,5,-5);

			// "offset POV" camera mode parameters
			PovOffset=new Vector3D(0,1,-3);
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number,simulationPaused:Boolean):void
		{
			// vehicle being tracked (just a reference with a more concise name)
			var v:IVehicle=VehicleToTrack;
			var noVehicle:Boolean=VehicleToTrack == null;

			// new position/target/up, set in switch below, defaults to current
			var newPosition:Vector3D=Position;
			var newTarget:Vector3D=Target;
			var newUp:Vector3D=Up;

			// prediction time to compensate for lag caused by smoothing moves
			var antiLagTime:Number=simulationPaused?0:1 / smoothMoveSpeed;

			// aim at a predicted future position of the target vehicle
			var predictionTime:Number=AimLeadTime + antiLagTime;

			// set new position/target/up according to camera aim mode
			switch (Mode)
			{
				case CameraMode.Fixed :
					newPosition=FixedPosition;
					newTarget=FixedTarget;
					newUp=FixedUp;
					break;

				case CameraMode.FixedDistanceOffset :
					if (noVehicle)
					{
						break;
					}
					newUp=Vector3D.Up;// xxx maybe this should be v.up ?
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=ConstantDistanceHelper(elapsedTime);
					break;

				case CameraMode.StraightDown :
					if (noVehicle)
					{
						break;
					}
					newUp=v.Forward;
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=newTarget;
					newPosition.y+= LookDownDistance;
					break;

				case CameraMode.FixedLocalOffset :
					if (noVehicle)
					{
						break;
					}
					newUp=v.Up;
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=v.GlobalizePosition(FixedLocalOffset);
					break;

				case CameraMode.OffsetPOV :
					{
						if (noVehicle)
						{
							break;
						}
						newUp=v.Up;
						var futurePosition:Vector3D=v.PredictFuturePosition(antiLagTime);
						var globalOffset:Vector3D=v.GlobalizeDirection(PovOffset);
						newPosition=Vector3D.VectorAddition(futurePosition, globalOffset);
						// XXX hack to improve smoothing between modes (no effect on aim)
						var L:Number=10;
						newTarget=Vector3D.ScalarMultiplication(L,Vector3D.VectorAddition(newPosition, v.Forward));
						break;

					};
				default :
					break;
			}

			// blend from current position/target/up towards new values
			SmoothCameraMove (newPosition,newTarget,newUp,elapsedTime);

			// set camera in draw module
			//FIXME: drawCameraLookAt(position(), target, up());
		}

		public function callUpdate (currentTime:Number,elapsedTime:Number):void
		{
			Update (currentTime,elapsedTime,false);
		}

		// helper function for "drag behind" mode
		protected function ConstantDistanceHelper (elapsedTime:Number):Vector3D
		{
			// is the "global up"/"vertical" offset constraint enabled?  (it forces
			// the camera's global-up (Y) cordinate to be a above/below the target
			// vehicle by a given offset.)
			var constrainUp:Boolean=FixedDistanceVerticalOffset != 0;

			// vector offset from target to current camera position
			var adjustedPosition:Vector3D=new Vector3D(Position.x,constrainUp?Target.y:Position.y,Position.z);
			var offset:Vector3D=Vector3D.VectorSubtraction(adjustedPosition,Target);

			// current distance between them
			var distance:Number=offset.Magnitude();

			// move camera only when geometry is well-defined (avoid degenerate case)
			if (distance == 0)
			{
				return Position;
			}
			else
			{
				// unit vector along original offset
				var unitOffset:Vector3D=offset.UnaryScalarDivision(distance);

				// new offset of length XXX
				//var xxxDistance:Number = Number(Math.Sqrt(Utilities.Square(FixedDistanceDistance) - Utilities.Square(FixedDistanceVerticalOffset)));
				var xxxDistance:Number=Number(Math.sqrt(Utilities.Square(FixedDistanceDistance) - Utilities.Square(FixedDistanceVerticalOffset)));
				var newOffset:Vector3D=Vector3D.ScalarMultiplication(xxxDistance,unitOffset);

				// return new camera position: adjust distance to target
				return Vector3D.VectorAddition(Vector3D.VectorAddition(Target, newOffset), new Vector3D(0,FixedDistanceVerticalOffset,0));
			}
		}

		// Smoothly move camera ...
		public function SmoothCameraMove (newPosition:Vector3D,newTarget:Vector3D,newUp:Vector3D,elapsedTime:Number):void
		{
			if (smoothNextMove)
			{
				var smoothRate:Number=elapsedTime * smoothMoveSpeed;

				var tempPosition:Vector3D=Position;
				var tempUp:Vector3D=Up;
				Utilities.BlendIntoAccumulator2 (smoothRate,newPosition,tempPosition);
				Utilities.BlendIntoAccumulator2 (smoothRate,newTarget,Target);
				Utilities.BlendIntoAccumulator2 (smoothRate,newUp,tempUp);
				Position=tempPosition;
				Up=tempUp;

				// xxx not sure if these are needed, seems like a good idea
				// xxx (also if either up or oldUP are zero, use the other?)
				// xxx (even better: force up to be perp to target-position axis))
				if (Up == Vector3D.Zero)
				{
					Up=Vector3D.Up;
				}
				else
				{
					Up.fNormalize();
				}
			}
			else
			{
				smoothNextMove=true;

				Position=newPosition;
				Target=newTarget;
				Up=newUp;
			}
		}

		public function DoNotSmoothNextMove():void
		{
			smoothNextMove=false;
		}

		// adjust the offset vector of the current camera mode based on a
		// "mouse adjustment vector" from OpenSteerDemo (xxx experiment 10-17-02)
		public function MouseAdjustOffset (adjustment:Vector3D):void
		{
			// vehicle being tracked (just a reference with a more concise name)
			var v:IVehicle=VehicleToTrack;

			switch (Mode)
			{
				case CameraMode.Fixed :
					{
						var offset:Vector3D=Vector3D.VectorSubtraction(FixedPosition,FixedTarget);
						var adjusted:Vector3D=MouseAdjustPolar(adjustment,offset);
						FixedPosition=Vector3D.VectorAddition(FixedTarget, adjusted);
						break;

					};
				case CameraMode.FixedDistanceOffset :
					{
						// XXX this is the oddball case, adjusting "position" instead
						// XXX of mode parameters, hence no smoothing during adjustment
						// XXX Plus the fixedDistVOffset feature complicates things
						var offset:Vector3D=Vector3D.VectorSubtraction(Position , Target);
						var adjusted:Vector3D=MouseAdjustPolar(adjustment,offset);
						// XXX --------------------------------------------------
						//position = target + adjusted;
						//fixedDistDistance = adjusted.length();
						//fixedDistVOffset = position.y - target.y;
						// XXX --------------------------------------------------
						//const float s = smoothMoveSpeed * (1.0f/40f);
						//const Vector3 newPosition = target + adjusted;
						//position = interpolate (s, position, newPosition);
						//fixedDistDistance = interpolate (s, fixedDistDistance, adjusted.length());
						//fixedDistVOffset = interpolate (s, fixedDistVOffset, position.y - target.y);
						// XXX --------------------------------------------------
						//position = target + adjusted;
						Position=Vector3D.VectorAddition(Target , adjusted);
						FixedDistanceDistance=adjusted.Magnitude();
						//fixedDistVOffset = position.y - target.y;
						FixedDistanceVerticalOffset=Position.y - Target.y;
						// XXX --------------------------------------------------
						break;

					};
				case CameraMode.StraightDown :
					{
						var offset:Vector3D=new Vector3D(0,0,LookDownDistance);
						var adjusted:Vector3D=MouseAdjustPolar(adjustment,offset);
						LookDownDistance=adjusted.z;
						break;

					};
				case CameraMode.FixedLocalOffset :
					{
						var offset:Vector3D=v.GlobalizeDirection(FixedLocalOffset);
						var adjusted:Vector3D=MouseAdjustPolar(adjustment,offset);
						FixedLocalOffset=v.LocalizeDirection(adjusted);
						break;

					};
				case CameraMode.OffsetPOV :
					{
						// XXX this might work better as a translation control, it is
						// XXX non-obvious using a polar adjustment when the view
						// XXX center is not at the camera aim target
						var offset:Vector3D=v.GlobalizeDirection(PovOffset);
						var adjusted:Vector3D=MouseAdjustOrtho(adjustment,offset);
						PovOffset=v.LocalizeDirection(adjusted);
						break;

					};
				default :
					break;
			}
		}

		public function MouseAdjust2 (polar:Boolean,adjustment:Vector3D,offsetToAdjust:Vector3D):Vector3D
		{
			// value to be returned
			var result:Vector3D=offsetToAdjust;

			// using the camera's side/up axes (essentially: screen space) move the
			// offset vector sideways according to adjustment.x and vertically
			// according to adjustment.y, constrain the offset vector's length to
			// stay the same, hence the offset's "tip" stays on the surface of a
			// sphere.
			var oldLength:Number=result.Magnitude();
			var rate:Number=polar?oldLength:1;
			result = Vector3D.VectorAddition(result,Vector3D.ScalarMultiplication((adjustment.x * rate),xxxls().Side));
			result = Vector3D.VectorAddition(result,Vector3D.ScalarMultiplication((adjustment.y * rate),xxxls().Up));
			if (polar)
			{
				var newLength:Number=result.Magnitude();
				result = Vector3D.ScalarMultiplication((oldLength / newLength),result);
			}

			// change the length of the offset vector according to adjustment.z
			if (polar)
			{
				result = Vector3D.ScalarMultiplication(1 + adjustment.z,result);
			}
			else
			{
				result = Vector3D.VectorAddition(result,Vector3D.ScalarMultiplication(adjustment.z,xxxls().Forward));

			}
			return result;
		}

		public function MouseAdjustPolar (adjustment:Vector3D,offsetToAdjust:Vector3D):Vector3D
		{
			return MouseAdjust2(true,adjustment,offsetToAdjust);
		}
		public function MouseAdjustOrtho (adjustment:Vector3D,offsetToAdjust:Vector3D):Vector3D
		{
			return MouseAdjust2(false,adjustment,offsetToAdjust);
		}

		// string naming current camera mode, used by OpenSteerDemo
		public function get ModeName ():String
		{
			switch (Mode)
			{
				case CameraMode.Fixed :
					return "static";
				case CameraMode.FixedDistanceOffset :
					return "fixed distance offset";
				case CameraMode.FixedLocalOffset :
					return "fixed local offset";
				case CameraMode.OffsetPOV :
					return "offset POV";
				case CameraMode.StraightDown :
					return "straight down";
				default :
					return "unknown";
			}
		}

		// select next camera mode, used by OpenSteerDemo
		public function SelectNextMode ():void
		{
			Mode=SuccessorMode(Mode);
			if (Mode >= CameraMode.EndMode)
			{
				Mode=SuccessorMode(CameraMode.StartMode);
			}
		}

		// the mode that comes after the given mode (used by selectNextMode)
		protected function SuccessorMode (cm:String):String
		{
			return String(int(cm) + 1);
		}
	}
}