package
{
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	import tabinda.as3steer.*;
	
	public class Shark extends SimpleVehicle
	{
		public var pd:AbstractProximityDatabase;
		public var soul:Sprite;
		
		public var vertices:Vector.<Number>;
		public var indices:Vector.<int>;
		public var matrix:Matrix3D;

		// constructor
		public function Shark(tPd:AbstractProximityDatabase)
		{
			matrix = new Matrix3D();
			vertices = new Vector.<Number>();
			indices = new Vector.<int>(); 
				
			pd = tPd;
			soul = new Sprite();
				
			// reset all boid state
			resetBoid();	
		}
		
		// reset state
	   private  function resetBoid():void
	   {
			// reset the vehicle
			super.reset();//::reset ();

			radius = 5;
			
			// steering force is clipped to this magnitude
			maxForce = 27;

			// velocity is clipped to this magnitude
			maxSpeed = 60;

			// initial slow speed
			speed = (maxSpeed * 0.3);

			// randomize initial orientation
			regenerateOrthonormalBasisUF(Utility.RandomUnitVector());

			// randomize initial position
			Position = Vector3.ScalarMultiplication(20, Utility.RandomVectorInUnitRadiusSphere());
		}   

		// per frame simulation update
		public function update(currentTime:Number, elapsedTime:Number):void
		{
			var nearestFishPosition:Vector3 = Vector3.ZERO;

			nearestFishPosition = pd.getMostPopulatedBinCenter();
			
			// steer to flock and perhaps to stay within the spherical boundary
			applySteeringForce(Vector3.VectorAddition(Vector3.ScalarMultiplication(10, steerToFlock(nearestFishPosition)) , Vector3.ScalarMultiplication(5,handleBoundary())), elapsedTime);

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
			soul.graphics.beginFill(0xFF0000,0.5);
			soul.graphics.lineStyle(0.1, 0xFF0000, 0.5);
			soul.graphics.drawTriangles(vertices,indices);
			soul.graphics.endFill();
		}

		// basic flocking
		private function steerToFlock(target:Vector3):Vector3
		{
			var wander:Vector3 = steerForWander(2);

			var steerForFollow:Vector3 = steerForSeek(target);
			return Vector3.VectorAddition(steerForFollow , wander);
		}


		// Take action to stay within sphereical boundary.  Returns steering
		// value (which is normally zero) and may take other side-effecting
		// actions such as kinematically changing the Boid's position.
		private function handleBoundary():Vector3
		{
			var worldRadius:Number = 40;
			var boundaryCondition:int = 0;
			// while inside the sphere do noting
			if (Position.Magnitude() < worldRadius) return Vector3.ZERO;

			// once outside, select strategy
			switch (boundaryCondition)
			{
				case 0:
					{
						// steer back when outside
					   var seek:Vector3 = xxxsteerForSeek(Vector3.ZERO);
						var lateral:Vector3 = Utility.perpendicularComponent(seek, forward);
						return lateral;
					}
				case 1:
					{
						// wrap around (teleport)
						Position = Utility.sphericalWrapAround(Position, Vector3.ZERO, worldRadius);
						return Vector3.ZERO;
					}
			}
			return Vector3.ZERO; // should not reach here
		}
		
		// make boids "bank" as they fly
		private function egenerateLocalSpace(newVelocity:Vector3, elapsedTime:Number):void
		{
			regenerateLocalSpaceForBanking(newVelocity, elapsedTime);
		}
	}
}