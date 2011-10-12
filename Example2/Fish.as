package
{
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.text.TextField;
	import tabinda.as3steer.*;
	
	public class Fish extends SimpleVehicle 
	{
		public var proximityToken:AbstractTokenForProximityDatabase;
		public var centre:Vector3;
		public var simulationRadius:Number;
		public var neighbors:Array;
		public var predatorList:Array;
		public static var boundaryCondition:int = 0;
		
		public var runForYourLives:Number = 50.0 * 50.0;
		public var soul:Sprite;
		
		public var vertices:Vector.<Number>;
		public var indices:Vector.<int>;
		public var matrix:Matrix3D;
		
		public function Fish(pd:AbstractProximityDatabase,tCentre:Vector3,tSimulationRadius:Number)
		{
			soul = new Sprite();

			centre = tCentre;
			neighbors = new Array();
			predatorList=new Array();
			
			// allocate a token for this boid in the proximity database
			proximityToken = null;
			newPD (pd);

			matrix = new Matrix3D();
            vertices = new Vector.<Number>();
            indices = new Vector.<int>(); 
			
			// reset all boid state
			resetBoid(tSimulationRadius);
		}
		
		
		public function addShark(shark:AbstractVehicle):void
		{
			predatorList.push(shark);
		}
		
		// reset state
		private function resetBoid(sim:Number):void
		{
			// reset the vehicle
			super.reset();

			// steering force is clipped to this magnitude
			maxForce = 27;

			// velocity is clipped to this magnitude
			maxSpeed = 30;

			// initial slow speed
			speed = (maxSpeed * 0.3);

			radius = 5;
			simulationRadius = sim;
			
			// randomize initial orientation
			regenerateOrthonormalBasisUF (Utility.RandomUnitVector ());

			// randomize initial position
			Position = Vector3.VectorAddition(centre,Vector3.ScalarMultiplication(20,Utility.RandomVectorInUnitRadiusSphere()));

			// notify proximity database that our position has changed
			proximityToken.updateForNewPosition(Position);
		}
		
		public function resetPosition():void
		{
			Position =Vector3.ScalarMultiplication(20,Utility.RandomVectorInUnitRadiusSphere());
		}
		
		// per frame simulation update
		public function update (currentTime:Number, elapsedTime:Number):void
		{
			// steer to flock and perhaps to stay within the spherical boundary
			applySteeringForce (Vector3.VectorAddition(steerToFlock () , handleBoundary()), elapsedTime);

			// notify proximity database that our position has changed
			proximityToken.updateForNewPosition (Position);
				
			// "aspect ratio" of body (as seen from above)
			const x:Number = 0.5;
			var y:Number = Number(Math.sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = radius;
			var p:Vector3 = Position;

			// body shape parameters
			var f:Vector3 = Vector3.ScalarMultiplication(r,forward);
			var s:Vector3 = Vector3.ScalarMultiplication((r * x), side);
			var u:Vector3 = Vector3.ScalarMultiplication((r * x * 0.5),up);
			var b:Vector3 = Vector3.ScalarMultiplication(r * -y, forward);
			
			// vertex position
			var nose:Vector3 = Vector3.VectorAddition(p , f);
			var side1:Vector3 = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , s);
			var side2:Vector3 = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , s);
			var top:Vector3 = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , u);
			var bottom:Vector3 = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , u);
			
			vertices.length = 0;
			indices.length = 0;
			
			vertices = Vector.<Number>([nose.x, nose.y, side1.x, side1.y, side2.x, side2.y, top.x, top.y, bottom.x, bottom.y]);
			indices = Vector.<int>([0, 1, 3, 0, 3, 2, 0, 4, 1, 0, 2, 4, 1, 2, 3, 2, 1, 4]);
			
			soul.graphics.clear();
			soul.graphics.beginFill(0xc5c5c5,0.5);
			soul.graphics.lineStyle(0.1, 0x333333, 0.5);
			soul.graphics.drawTriangles(vertices,indices);
			soul.graphics.endFill();
		}
		
		// basic flocking
		private function steerToFlock ():Vector3
		{
			var separationRadius:Number =  5.0;
			var separationAngle:Number  = -0.707;
			var separationWeight:Number =  12.0;

			var alignmentRadius:Number = 7.5;
			var alignmentAngle:Number  = 0.7;
			var alignmentWeight:Number = 8.0;

			var cohesionRadius:Number = 9.0;
			var cohesionAngle:Number  = -0.15;
			var cohesionWeight:Number = 8.0;
			var fleeWeight:Number = 12.0;

			var maxRadius:Number = Number(Math.max(separationRadius, Math.max (alignmentRadius, cohesionRadius)));

			// find all flockmates within maxRadius using proximity database
			neighbors = [];
			proximityToken.findNeighbors (Position, maxRadius, neighbors);

			// determine each of the three component behaviors of flocking
			var separation:Vector3 = steerForSeparation (separationRadius, separationAngle, neighbors);
			var alignment:Vector3  = steerForAlignment  (alignmentRadius,
														alignmentAngle,
														neighbors);
			var cohesion:Vector3   = steerForCohesion   (cohesionRadius,
														cohesionAngle,
														neighbors);
														
			var flee:Vector3 = Vector3.ZERO;
			
			for (var i:int=0;i<predatorList.length;i++)
			{
				var shark:Shark=Shark(predatorList[i]);
				if (Vector3.VectorSubtraction(shark.Position , Position).SquaredMagnitude() < runForYourLives)
				{
					flee = Vector3.VectorAddition(steerForFlee(shark.Position), flee);
				}
			}

			// apply weights to components (save in variables for annotation)
			var separationW:Vector3 = Vector3.ScalarMultiplication(separationWeight, separation);
			var alignmentW:Vector3 = Vector3.ScalarMultiplication(alignmentWeight, alignment);// * alignmentWeight;
			var cohesionW:Vector3 = Vector3.ScalarMultiplication(cohesionWeight, cohesion);// * cohesionWeight;

			var fleeW:Vector3 = Vector3.ScalarMultiplication(fleeWeight, flee);

			return Vector3.VectorAddition(Vector3.VectorAddition(separationW , alignmentW) , Vector3.VectorAddition(cohesionW ,fleeW));
		}

		// Take action to stay within sphereical boundary.  Returns steering
		// value (which is normally zero) and may take other side-effecting
		// actions such as kinematically changing the Boid's position.
		private function handleBoundary ():Vector3
		{
			// while inside the sphere do noting
			if (Vector3.VectorSubtraction(Position , centre).Magnitude() < simulationRadius) return Vector3.ZERO;
	
			// once outside, select strategy
			switch (boundaryCondition)
			{
			case 0:
				{
					// steer back when outside
					var seek:Vector3 = xxxsteerForSeek(centre);	
					var lateral:Vector3 = Utility.perpendicularComponent(seek, forward);
					return lateral;
				}
			case 1:
				{
					// wrap around (teleport)
					Position = Utility.sphericalWrapAround(Position, centre, simulationRadius);
					return Vector3.ZERO;
				}
			}
			return Vector3.ZERO; // should not reach here
		}

		// make boids "bank" as they fly
		private function regenerateLocalSpace ( newVelocity:Vector3, elapsedTime:Number):void
		{
			regenerateLocalSpaceForBanking (newVelocity, elapsedTime);
		}

		// switch to new proximity database -- just for demo purposes
		public function newPD (pd:AbstractProximityDatabase):void
		{
			// allocate a token for this boid in the proximity database
			proximityToken = pd.allocateToken (this);
		}
	}
}
