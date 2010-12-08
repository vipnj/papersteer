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

package tabinda.demo.plugins.Ctf
{
	import tabinda.papersteer.*;
	
	public class CtfEnemy extends CtfBase
	{
		// constructor
		public function CtfEnemy ()
		{
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();
			BodyColor=Colors.RGBToHex(int(255.0 * 0.6),int(255.0 * 0.4),int(255.0 * 0.4));// redish
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// determine upper bound for pursuit prediction time
			var seekerToGoalDist:Number=Vector3.Distance(Globals.HomeBaseCenter,CtfPlugIn.Seeker.Position);
			var adjustedDistance:Number=seekerToGoalDist - Radius - Globals.HomeBaseRadius;
			var seekerToGoalTime:Number=((adjustedDistance < 0)?0:(adjustedDistance / CtfPlugIn.Seeker.Speed));
			var maxPredictionTime:Number=seekerToGoalTime * 0.9;

			// determine steering (pursuit, obstacle avoidance, or braking)
			var steer:Vector3=Vector3.Zero;
			if (CtfPlugIn.Seeker.State == SeekerState.Running)
			{
				var avoidance:Vector3=SteerToAvoidObstacles(Globals.AvoidancePredictTimeMin,Vector.<IObstacle>(AllObstacles));

				// saved for annotation
				Avoiding=Vector3.isEqual(avoidance, Vector3.Zero);

				if (Avoiding)
				{
					steer=SteerForPursuit2(CtfPlugIn.Seeker,maxPredictionTime);
				}
				else
				{
					steer=avoidance;
				}
			}
			else
			{
				ApplyBrakingForce (Globals.BrakingRate,elapsedTime);
			}
			ApplySteeringForce (steer,elapsedTime);

			// annotation
			annotation.VelocityAcceleration (this);
			trail.Record (currentTime,Position);

			// detect and record interceptions ("tags") of seeker
			var seekerToMeDist:Number=Vector3.Distance(Position,CtfPlugIn.Seeker.Position);
			var sumOfRadii:Number=Radius + CtfPlugIn.Seeker.Radius;
			if (seekerToMeDist < sumOfRadii)
			{
				if (CtfPlugIn.Seeker.State == SeekerState.Running)
				{
					CtfPlugIn.Seeker.State=SeekerState.Tagged;
				}

				// annotation:
				if (CtfPlugIn.Seeker.State == SeekerState.Tagged)
				{
					var color:uint=Colors.RGBToHex(int(255.0 * 0.8),int(255.0 * 0.5),int(255.0 * 0.5));
					annotation.DiskXZ (sumOfRadii,Vector3.ScalarMultiplication(1/2,Vector3.VectorAddition(Position , CtfPlugIn.Seeker.Position)),color,20);
				}
			}
		}
	}
}