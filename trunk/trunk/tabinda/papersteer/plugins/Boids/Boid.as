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

package tabinda.papersteer.plugins.Boids
{
	import tabinda.papersteer.*;
	
	/*var ProximityDatabase = IProximityDatabase;
	var ProximityToken = ITokenForProximityDatabase;
	var SOG = List<SphericalObstacle>;  // spherical obstacle group*/

	public class Boid extends SimpleVehicle
	{
		public const AvoidancePredictTimeMin:Number=0.9;
		public const AvoidancePredictTimeMax:Number=2;
		public static  var AvoidancePredictTime:Number = AvoidancePredictTimeMin;
		
		protected static  var obstacleCount:int=-1;
		protected const maxObstacleCount:int=100;
		public static  var AllObstacles:Array=new Array;

		// a pointer to this boid's interface object for the proximity database
		public var proximityToken:ITokenForProximityDatabase;

		// allocate one and share amoung instances just to save memory usage
		// (change to per-instance allocation to be more MP-safe)
		public static  var neighbors:Array=new Array();
		public static  var boundaryCondition:int=0;
		public const worldRadius:Number=50;

		// constructor
		public function Boid (pd:IProximityDatabase)
		{
			// allocate a token for this boid in the proximity database
			proximityToken=null;
			NewPD (pd);

			// reset all boid state
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			// reset the vehicle
			super.Reset ();

			// steering force is clipped to this magnitude
			MaxForce=27;

			// velocity is clipped to this magnitude
			MaxSpeed=9;

			// initial slow speed
			Speed=MaxSpeed * 0.3;

			// randomize initial orientation
			//RegenerateOrthonormalBasisUF(Vector3Helpers.RandomUnitVector());
			var d:Vector3D=Vector3D.RandomUnitVector();
			d.x=Math.abs(d.x);
			d.y=0;
			d.z=Math.abs(d.z);
			RegenerateOrthonormalBasisUF (d);

			// randomize initial position
			Position=Vector3D.UnitX * 10 + Vector3D.RandomVectorInUnitRadiusSphere() * 20;

			// notify proximity database that our position has changed
			//FIXME: SimpleVehicle::SimpleVehicle() calls reset() before proximityToken is set
			if (proximityToken != null)
			{
				proximityToken.UpdateForNewPosition (Position);
			}
		}

		// draw this boid into the scene
		public function Draw ():void
		{
			Drawing.DrawBasic3dSphericalVehicle (this,0xCCCCCC);
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// steer to flock and perhaps to stay within the spherical boundary
			ApplySteeringForce (Vector3D.VectorAddition(SteerToFlock() , HandleBoundary()),elapsedTime);

			// notify proximity database that our position has changed
			proximityToken.UpdateForNewPosition (Position);
		}

		// basic flocking
		public function SteerToFlock ():Vector3D
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
			neighbors.Clear();
			proximityToken.FindNeighbors (Position,maxRadius,neighbors);

			// determine each of the three component behaviors of flocking
			var separation:Vector3D=SteerForSeparation(separationRadius,separationAngle,neighbors);
			var alignment:Vector3D=SteerForAlignment(alignmentRadius,alignmentAngle,neighbors);
			var cohesion:Vector3D=SteerForCohesion(cohesionRadius,cohesionAngle,neighbors);

			// apply weights to components (save in variables for annotation)
			var separationW:Vector3D=Vector3D.ScalarMultiplication(separationWeight,separation);
			var alignmentW:Vector3D=Vector3D.ScalarMultiplication(alignmentWeightalignment);
			var cohesionW:Vector3D=Vector3D.ScalarMultiplication(cohesionWeight,cohesion);

			var avoidance:Vector3D=SteerToAvoidObstacles(Boid.AvoidancePredictTimeMin,AllObstacles);

			// saved for annotation
			var Avoiding:Boolean=avoidance != Vector3D.Zero;
			var steer:Vector3D=Vector3D.VectorAddition(Vector3D.VectorAddition(separationW , alignmentW) , cohesionW);
			if (Avoiding)
			{
				steer=avoidance;
				trace ("Avoiding: [{0}, {1}, {2}]",avoidance.x,avoidance.y,avoidance.z);
			}
			COMPILE::IGNORED
			{
				// annotation
				const s:Number = 0.1;
				AnnotationLine(Position, Vector3D.VectorAddition(Position , (Vector3D.ScalarMultiplication(s,separationW))), Colors.Red);
				AnnotationLine(Position, Vector3D.VectorAddition(Position , (Vector3D.ScalarMultiplication(s,alignmentW))), Colors.Orange);
				AnnotationLine(Position, Vector3D.VectorAddition(Position , (Vector3D.ScalarMultiplication(s,cohesionW))), Colors.Yellow);
			}
			return steer;
		}

		// Take action to stay within sphereical boundary.  Returns steering
		// value (which is normally zero) and may take other side-effecting
		// actions such as kinematically changing the Boid's position.
		public function HandleBoundary ():Vector3D
		{
			// while inside the sphere do noting
			if (Position.Magnitude() < worldRadius)
			{
				return Vector3D.Zero;
			}

			// once outside, select strategy
			switch (boundaryCondition)
			{
				case 0 :
					{
						// steer back when outside
						var seek:Vector3D=xxxSteerForSeek(Vector3D.Zero);
						var lateral:Vector3D=seek.PerpendicularComponent(Forward);
						return lateral;

					};
				case 1 :
					{
						// wrap around (teleport)
						Position=Vector3D.SphericalWrapAround(Position,Vector3D.Zero,worldRadius);
						return Vector3D.Zero;

				}
			};
			return Vector3D.Zero;// should not reach here
		}

		// make boids "bank" as they fly
		public override  function RegenerateLocalSpace (newVelocity:Vector3D,elapsedTime:Number):void
		{
			RegenerateLocalSpaceForBanking (newVelocity,elapsedTime);
		}

		// switch to new proximity database -- just for demo purposes
		public function NewPD (pd:IProximityDatabase):void
		{
			// delete this boid's token in the old proximity database
			if (proximityToken != null)
			{
				proximityToken.Dispose();
				proximityToken=null;
			}

			// allocate a token for this boid in the proximity database
			proximityToken=pd.AllocateToken(this);
		}

		// cycle through various boundary conditions
		public static  function NextBoundaryCondition ():void
		{
			const max:int=2;
			boundaryCondition=boundaryCondition + 1 % max;
		}

		// dynamic obstacle registry
		public static  function InitializeObstacles ():void
		{
			// start with 40% of possible obstacles
			if (obstacleCount == -1)
			{
				obstacleCount=0;
				for (var i:int=0; i < maxObstacleCount * 1.0; i++)
				{
					AddOneObstacle ();
				}
			}
		}

		public static  function AddOneObstacle ():void
		{
			if (obstacleCount < maxObstacleCount)
			{
				// pick a random center and radius,
				// loop until no overlap with other obstacles and the home base
				//float r = 15;
				//Vector3 c = Vector3.Up * r * (-0.5f * maxObstacleCount + obstacleCount);
				var r:Number=Utilities.random(0.5,2);
				var c:Vector3D=Vector3D.RandomVectorInUnitRadiusSphere() * worldRadius * 1.1;

				// add new non-overlapping obstacle to registry
				AllObstacles.push (new SphericalObstacle(r,c));
				obstacleCount++;
			}
		}

		public static  function RemoveOneObstacle ():void
		{
			if (obstacleCount > 0)
			{
				obstacleCount--;
				AllObstacles.splice (obstacleCount,1);
			}
		}

		public function MinDistanceToObstacle (point:Vector3D):Number
		{
			var r:Number=0;
			var c:Vector3D=point;
			var minClearance:Number=Number.MAX_VALUE;
			for (var so:int=0; so < AllObstacles.length; so++)
			{
				minClearance=TestOneObstacleOverlap(minClearance,r,AllObstacles[so].Radius,c,AllObstacles[so].Center);
			}
			return minClearance;
		}

		static function TestOneObstacleOverlap (minClearance:Number,r:Number,radius:Number,c:Vector3D,center:Vector3D):Number
		{
			var d:Number=Vector3D.Distance(c,center);
			var clearance:Number=d - r + radius;
			if (minClearance > clearance)
			{
				minClearance=clearance;
			}
			return minClearance;
		}
	}
}