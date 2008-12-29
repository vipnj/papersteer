// ----------------------------------------------------------------------------
//
// OpenSteer Example using AS3Steer
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

package
{
	import flash.display.Shape;
	import flash.text.*;
	import tabinda.as3steer.*;

	public class Boid extends SimpleVehicle
	{
		public static const AvoidancePredictTimeMin:Number=0.9;
		public static const AvoidancePredictTimeMax:Number=2.0;
		public static var AvoidancePredictTime:Number = AvoidancePredictTimeMin;

		// a pointer to this boid's interface object for the proximity database
		public var proximityToken:AbstractTokenForProximityDatabase;

		// allocate one and share amoung instances just to save memory usage
		// (change to per-instance allocation to be more MP-safe)
		public static  var neighbors:Array=new Array();
		public static  var boundaryCondition:int=0;
		public static const worldRadius:Number = 50.0;
		
		public var sp:Shape;

		// constructor
		public function Boid (pd:AbstractProximityDatabase)
		{
			// allocate a token for this boid in the proximity database
			proximityToken=null;
			NewPD (pd);
			
			sp = new Shape();
			sp.graphics.beginFill(0x000000,1);
			sp.graphics.drawEllipse(0,0,3,3);
			sp.graphics.endFill();
		
			// reset all boid state
			Reset ();
		}

		// reset state
		public function Reset ():void
		{
			// reset the vehicle
			super.reset();

			// steering force is clipped to this magnitude
			setMaxForce(27.0);

			// velocity is clipped to this magnitude
			setMaxSpeed(9.0);
			
			// initial slow speed
			setSpeed(maxSpeed() * 0.3);
			
			regenerateOrthonormalBasisUF(Utility.RandomUnitVector());
			
			// randomize initial position
			setPosition(Vector3.ScalarMultiplication2(20.0, Utility.RandomVectorInUnitRadiusSphere()));
			
			// notify proximity database that our position has changed
			//FIXME: SimpleVehicle::SimpleVehicle() calls reset() before proximityToken is set
			if (proximityToken != null)
			{
				proximityToken.updateForNewPosition (Position());
			}
		}

		// draw this boid into the scene
		public function Draw ():void
		{
			// You may add your drawing routine here
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// steer to flock and perhaps to stay within the spherical boundary
			applySteeringForce(Vector3.VectorAddition(SteerToFlock() , HandleBoundary()),elapsedTime);
			
			// Updates to the visual objects here
			sp.x = Position().x;
			sp.y = Position().y;
			sp.z = Position().z;
			
			// notify proximity database that our position has changed
			proximityToken.updateForNewPosition(Position());
		}

		// basic flocking
		public function SteerToFlock ():Vector3
		{
			const separationRadius:Number=5.0;
			const separationAngle:Number=-0.707;
			const separationWeight:Number=12.0;

			const alignmentRadius:Number=7.5;
			const alignmentAngle:Number=0.7;
			const alignmentWeight:Number=8.0;

			const cohesionRadius:Number=9.0;
			const cohesionAngle:Number=-0.15;
			const cohesionWeight:Number=8.0;

			var maxRadius:Number=Math.max(separationRadius,Math.max(alignmentRadius,cohesionRadius));

			// find all flockmates within maxRadius using proximity database
			neighbors.splice(0);
			proximityToken.findNeighbors (Position(),maxRadius,neighbors);

			// determine each of the three component behaviors of flocking
			var separation:Vector3=steerForSeparation(separationRadius,separationAngle,neighbors);
			var alignment:Vector3=steerForAlignment(alignmentRadius,alignmentAngle,neighbors);
			var cohesion:Vector3=steerForCohesion(cohesionRadius,cohesionAngle,neighbors);

			// apply weights to components (save in variables for annotation)
			var separationW:Vector3=Vector3.ScalarMultiplication2(separationWeight,separation);
			var alignmentW:Vector3=Vector3.ScalarMultiplication2(alignmentWeight,alignment);
			var cohesionW:Vector3 = Vector3.ScalarMultiplication2(cohesionWeight, cohesion);
			
			return Vector3.VectorAddition(Vector3.VectorAddition(separationW,alignmentW),cohesionW);
		}

		// Take action to stay within sphereical boundary.  Returns steering
		// value (which is normally zero) and may take other side-effecting
		// actions such as kinematically changing the Boid's position.
		public function HandleBoundary ():Vector3
		{
			// while inside the sphere do noting
			if (Position().Length() < worldRadius)
			{
				return Vector3.ZERO;
			}

			// once outside, select strategy
			switch (boundaryCondition)
			{
				case 0 :
					{
						// steer back when outside
						var seek:Vector3 = xxxsteerForSeek(Vector3.ZERO);
						var lateral:Vector3 = Utility.perpendicularComponent(seek, forward());
						return lateral;

					}
				case 1 :
					{
						// wrap around (teleport)
						setPosition(Utility.sphericalWrapAround(Position(), Vector3.ZERO, worldRadius));
						return Vector3.ZERO;
					}
			}
			return Vector3.ZERO;// should not reach here
		}

		// make boids "bank" as they fly
		public function RegenerateLocalSpace(newVelocity:Vector3,elapsedTime:Number):void
		{
			regenerateLocalSpaceForBanking(newVelocity,elapsedTime);
		}

		// switch to new proximity database -- just for demo purposes
		public function NewPD (pd:AbstractProximityDatabase):void
		{
			// delete this boid's token in the old proximity database
			if (proximityToken != null)
			{
				proximityToken=null;
			}

			// allocate a token for this boid in the proximity database
			proximityToken=pd.allocateToken(this);
		}

		// cycle through various boundary conditions
		public static  function NextBoundaryCondition (boundinfo:TextField):void
		{
			if(boundaryCondition ==1)
			{
				boundinfo.autoSize = TextFieldAutoSize.RIGHT;
				boundinfo.text = "Steering: Steer Back";
			}
			else
			{
				boundinfo.autoSize = TextFieldAutoSize.RIGHT;
				boundinfo.text = "Steering: Wrap Around";
			}
			const max:int=2;
			boundaryCondition=(boundaryCondition + 1) % max;
		}
	}
}