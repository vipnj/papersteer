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

package tabinda.papersteer.plugins.Ctf
{
	import flash.text.TextField;
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class CtfSeeker extends CtfBase
	{
		public var State:String;
		var evading:Boolean;// xxx store steer sub-state for anotation
		var lastRunningTime:Number;// for auto-reset
		
		// constructor
		public function CtfSeeker ():void
		{
			super ();
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();
			BodyColor=Colors.toHex(int(255.0 * 0.4),int(255.0 * 0.4),int(255.0 * 0.6));// blueish
			Globals.Seeker=this;
			State=SeekerState.Running;
			evading=false;
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// do behavioral state transitions, as needed
			UpdateState (currentTime);

			// determine and apply steering/braking forces
			var steer:Vector3=Vector3.Zero;
			if (State == SeekerState.Running)
			{
				steer=SteeringForSeeker();
			}
			else
			{
				ApplyBrakingForce (Globals.BrakingRate,elapsedTime);
			}
			ApplySteeringForce (steer,elapsedTime);

			// annotation
			annotation.VelocityAcceleration (this);
			trail.Record (currentTime,Position);
		}

		// is there a clear path to the goal?
		public function IsPathToGoalClear ():Boolean
		{
			var sideThreshold:Number=Radius * 8.0;
			var behindThreshold:Number=Radius * 2.0;

			var goalOffset:Vector3=Vector3.VectorAddition(Globals.HomeBaseCenter , Position);
			var goalDistance:Number=goalOffset.Magnitude();
			var goalDirection:Vector3=Vector3.ScalarDivision(goalOffset,goalDistance);

			var goalIsAside:Boolean=IsAside2(Globals.HomeBaseCenter,0.5);

			// for annotation: loop over all and save result, instead of early return 
			var xxxReturn:Boolean=true;

			// loop over enemies
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				// short name for this enemy
				var e:CtfEnemy=Globals.CtfEnemies[i];
				var eDistance:Number=Vector3.Distance(Position,e.Position);
				var timeEstimate:Number=0.3 * eDistance / e.Speed;//xxx
				var eFuture:Vector3=e.PredictFuturePosition(timeEstimate);
				var eOffset:Vector3=Vector3.VectorAddition(eFuture , Position);
				var alongCorridor:Number=goalDirection.DotProduct(eOffset);
				var inCorridor=((alongCorridor > - behindThreshold) && (alongCorridor < goalDistance));
				var eForwardDistance:Number=Forward.DotProduct(eOffset);

				// xxx temp move this up before the conditionals
				annotation.CircleXZ (e.Radius,eFuture,Globals.ClearPathColor,20);//xxx

				// consider as potential blocker if within the corridor
				if (inCorridor)
				{
					var perp:Vector3=Vector3.VectorSubtraction(eOffset , Vector3.ScalarMultiplication(alongCorridor,goalDirection));
					var acrossCorridor:Number=perp.Magnitude();
					if (acrossCorridor < sideThreshold)
					{
						// not a blocker if behind us and we are perp to corridor
						var eFront:Number=eForwardDistance + e.Radius;

						//annotation.annotationLine (position, forward*eFront, gGreen); // xxx
						//annotation.annotationLine (e.position, forward*eFront, gGreen); // xxx

						// xxx
						// std::ostringstream message;
						// message << "eFront = " << std::setprecision(2)
						//         << std::setiosflags(std::ios::fixed) << eFront << std::ends;
						// draw2dTextAt3dLocation (*message.str(), eFuture, gWhite);

						var eIsBehind:Boolean=eFront < - behindThreshold;
						var eIsWayBehind:Boolean=eFront < (-2 * behindThreshold);
						var safeToTurnTowardsGoal:Boolean=((eIsBehind && goalIsAside) || eIsWayBehind);

						if (! safeToTurnTowardsGoal)
						{
							// this enemy blocks the path to the goal, so return false
							annotation.Line (Position,e.Position,Globals.ClearPathColor);
							// return false;
							xxxReturn=false;
						}
					}
				}
			}

			// no enemies found along path, return true to indicate path is clear
			// clearPathAnnotation (sideThreshold, behindThreshold, goalDirection);
			// return true;
			//if (xxxReturn)
			ClearPathAnnotation (sideThreshold,behindThreshold,goalDirection);
			return xxxReturn;
		}

		public function SteeringForSeeker ():Vector3
		{
			// determine if obstacle avodiance is needed
			var clearPath:Boolean=IsPathToGoalClear();
			AdjustObstacleAvoidanceLookAhead (clearPath);
			var obstacleAvoidance:Vector3=SteerToAvoidObstacles(Globals.AvoidancePredictTime,Vector.<IObstacle>(AllObstacles));

			// saved for annotation
			Avoiding=Vector3.isNotEqual(obstacleAvoidance , Vector3.Zero);

			if (Avoiding)
			{
				// use pure obstacle avoidance if needed
				return obstacleAvoidance;
			}
			else
			{
				// otherwise seek home base and perhaps evade defenders
				var seek:Vector3=xxxSteerForSeek(Globals.HomeBaseCenter);
				if (clearPath)
				{
					// we have a clear path (defender-free corridor), use pure seek

					// xxx experiment 9-16-02
					var s:Vector3=VHelper.LimitMaxDeviationAngle(seek,0.707,Forward);

					annotation.Line (Position,Vector3.VectorAddition(Position,Vector3.ScalarMultiplication(0.2, s)),Globals.SeekColor);
					return s;
				}
				else
				{
					var evade:Vector3=XXXSteerToEvadeAllDefenders();
					var steer:Vector3=Vector3.LimitMaxDeviationAngle(Vector3.VectorAddition(seek , evade),0.707,Forward);

					annotation.Line (Position,Vector3.VectorAddition(Position , seek),Colors.Red);
					annotation.Line (Position,Vector3.VectorAddition(Position , evade),Colors.Green);

					// annotation: show evasion steering force
					annotation.Line (Position,Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(0.2,steer)),Globals.EvadeColor);
					return steer;
				}
			}
		}

		public function UpdateState (currentTime:Number):void
		{
			// if we reach the goal before being tagged, switch to atGoal state
			if (State == SeekerState.Running)
			{
				var baseDistance:Number=Vector3.Distance(Position,Globals.HomeBaseCenter);
				if (baseDistance < (Radius + Globals.HomeBaseRadius))
				{
					State=SeekerState.AtGoal;
				}
			}

			// update lastRunningTime (holds off reset time)
			if (State == SeekerState.Running)
			{
				lastRunningTime=currentTime;
			}
			else
			{
				var resetDelay:Number=4;
				var resetTime:Number=lastRunningTime + resetDelay;
				if (currentTime > resetTime)
				{
					// xxx a royal hack (should do this internal to CTF):
					Demo.QueueDelayedResetPlugInXXX ();
				}
			}
		}

		public override  function Draw ():void
		{
			// first call the draw method in the base class
			super.Draw ();

			// select string describing current seeker state
			var seekerStateString:String = "";
			
			switch (State)
			{
				case SeekerState.Running :
					if (Avoiding)
					{
						seekerStateString="avoid obstacle";
					}
					else if (evading)
					{
						seekerStateString="seek and evade";
					}
					else
					{
						seekerStateString="seek goal";
					}
					break;
				case SeekerState.Tagged :
					seekerStateString="tagged";
					break;
				case SeekerState.AtGoal :
					seekerStateString="reached goal";
					break;
			}

			// annote seeker with its state as text
			var textOrigin:Vector3=Vector3.VectorAddition(Position , new Vector3(0,0.25,0));
			var annote:String = new String();
			annote+=seekerStateString;
			annote+="\n"+Speed;
			Drawing.Draw2dTextAt3dLocation(annote, textOrigin, Colors.White);
			
			// display status in the upper left corner of the window
			var status:String = new String();
			status += seekerStateString;
			status+="\n "+obstacleCount +" obstacles [F1/F2]";
			status+="\n"+Globals.ResetCount+" restarts";
			var screenLocation:Vector3=new Vector3(15,50,0);
			Drawing.Draw2dTextAt2dLocation (status,screenLocation,Colors.LightGray);
		}

		public function SteerToEvadeAllDefenders ():Vector3
		{
			var evade:Vector3=Vector3.Zero;
			var goalDistance:Number=Vector3.Distance(Globals.HomeBaseCenter,Position);

			// sum up weighted evasion
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				var e:CtfEnemy=Globals.CtfEnemies[i];
				var eOffset:Vector3=Vector3.VectorSubtraction(e.Position , Position);
				var eDistance:Number = eOffset.Magnitude();

				var eForwardDistance:Number=Forward.DotProduct(eOffset);
				var behindThreshold:Number=Radius * 2;
				var behind:Boolean=eForwardDistance < behindThreshold;
				if ((! behind) || (eDistance < 5))
				{
					if (eDistance < (goalDistance * 1.2))
					{
						// const float timeEstimate = 0.5f * eDistance / e.speed;//xxx
						var timeEstimate:Number=0.15 * eDistance / e.Speed;//xxx
						var future:Vector3=e.PredictFuturePosition(timeEstimate);

						annotation.CircleXZ (e.Radius,future,Globals.EvadeColor,20);// xxx

						var offset:Vector3=Vector3.VectorSubtraction(future , Position);
						var lateral:Vector3=VHelper.PerpendicularComponent(offset,Forward);
						var d:Number = lateral.Magnitude();
						var weight:Number=-1000 / (d * d);
						evade= Vector3.VectorAddition(evade,Vector3.ScalarMultiplication(weight,Vector3.ScalarDivision(lateral,d)));
					}
				}
			}
			return evade;
		}

		public function XXXSteerToEvadeAllDefenders ():Vector3
		{
			// sum up weighted evasion
			var evade:Vector3=Vector3.Zero;
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				var e:CtfEnemy=Globals.CtfEnemies[i];
				var eOffset:Vector3=Vector3.VectorAddition(e.Position , Position);
				var eDistance:Number = eOffset.Magnitude();

				// xxx maybe this should take into account e's heading? xxx
				var timeEstimate:Number=0.5 * eDistance / e.Speed;//xxx
				var eFuture:Vector3=e.PredictFuturePosition(timeEstimate);

				// annotation
				annotation.CircleXZ (e.Radius,eFuture,Globals.EvadeColor,20);

				// steering to flee from eFuture (enemy's future position)
				var flee:Vector3=xxxSteerForFlee(eFuture);

				var eForwardDistance:Number=Forward.DotProduct(eOffset);
				var behindThreshold:Number=Radius * -2;

				var distanceWeight:Number=4 / eDistance;
				var forwardWeight:Number=((eForwardDistance > behindThreshold)?1.0:0.5);

				var adjustedFlee:Vector3=Vector3.ScalarMultiplication(distanceWeight * forwardWeight,flee);

				evade= Vector3.VectorAddition(evade,adjustedFlee);
			}
			return evade;
		}

		public function AdjustObstacleAvoidanceLookAhead (clearPath:Boolean):void
		{
			if (clearPath)
			{
				evading=false;
				var goalDistance:Number=Vector3.Distance(Globals.HomeBaseCenter,Position);
				var headingTowardGoal:Boolean=IsAhead2(Globals.HomeBaseCenter,0.98);
				var isNear:Boolean=(goalDistance / Speed) < Globals.AvoidancePredictTimeMax;
				var useMax:Boolean=headingTowardGoal && ! isNear;
				Globals.AvoidancePredictTime=(useMax?Globals.AvoidancePredictTimeMax:Globals.AvoidancePredictTimeMin);
			}
			else
			{
				evading=true;
				Globals.AvoidancePredictTime=Globals.AvoidancePredictTimeMin;
			}
		}

		public function ClearPathAnnotation (sideThreshold:Number,behindThreshold:Number,goalDirection:Vector3):void
		{
			var behindSide:Vector3=Vector3.ScalarMultiplication(sideThreshold,Side);
			var behindBack:Vector3=Vector3.ScalarMultiplication(-behindThreshold,Forward);
			var pbb:Vector3=Vector3.VectorAddition(Position , behindBack);
			var gun:Vector3=LocalRotateForwardToSide(goalDirection);
			var gn:Vector3=Vector3.ScalarMultiplication(sideThreshold,gun);
			var hbc:Vector3=Globals.HomeBaseCenter;
			annotation.Line (Vector3.VectorAddition(pbb ,gn),Vector3.VectorAddition(hbc , gn),Globals.ClearPathColor);
			annotation.Line (Vector3.VectorSubtraction(pbb , gn),Vector3.VectorSubtraction(hbc , gn),Globals.ClearPathColor);
			annotation.Line (Vector3.VectorSubtraction(hbc , gn),Vector3.VectorAddition(hbc , gn),Globals.ClearPathColor);
			annotation.Line (Vector3.VectorSubtraction(pbb , gn),Vector3.VectorAddition(pbb , gn),Globals.ClearPathColor);
			//annotation.AnnotationLine(pbb - behindSide, pbb + behindSide, Globals.clearPathColor);
		}
	}
}