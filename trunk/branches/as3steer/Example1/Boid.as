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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.text.*;
	import tabinda.as3steer.*;

	public class Boid extends SimpleVehicle
	{
		public static const AvoidancePredictTimeMin:Number=5.9;
		public static const AvoidancePredictTimeMax:Number=5.0;
		public static var AvoidancePredictTime:Number = AvoidancePredictTimeMin;

		// a pointer to this boid's interface object for the proximity database
		public var proximityToken:AbstractTokenForProximityDatabase;

		// allocate one and share amoung instances just to save memory usage
		// (change to per-instance allocation to be more MP-safe)
		public static var neighbors:Array=new Array();
		public static var boundaryCondition:int=0;
		public static const worldRadius:Number = 50.0;
		
		public var sp:Sprite;
		public var vertices:Vector.<Number>;
		public var indices:Vector.<int>;

		// constructor
		public function Boid (pd:AbstractProximityDatabase)
		{
			// allocate a token for this boid in the proximity database
			proximityToken=null;
			NewPD (pd);
			
            vertices = new Vector.<Number>();
            indices = new Vector.<int>(); 
		
			sp = new Sprite();
			// reset all boid state
			Reset ();
		}

		// reset state
		public function Reset ():void
		{
			// reset the vehicle
			super.reset();

			// steering force is clipped to this magnitude
			maxForce = (27.0);

			// velocity is clipped to this magnitude
			maxSpeed = (50.0);
			
			// initial slow speed
			speed = (maxSpeed * 0.3);
			
			regenerateOrthonormalBasisUF(Utility.RandomUnitVector());
			
			// randomize initial position
			Position = Vector3.ScalarMultiplication(20.0, Utility.RandomVectorInUnitRadiusSphere());
			
			// notify proximity database that our position has changed
			//FIXME: SimpleVehicle::SimpleVehicle() calls reset() before proximityToken is set
			if (proximityToken != null)
			{
				proximityToken.updateForNewPosition (Position);
			}
		}

		// draw this boid into the scene
		public function Draw ():void
		{
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
			
			sp.graphics.clear();
			sp.graphics.beginFill(0xff0000,0.5);
			sp.graphics.lineStyle(0.1, 0xcc0000, 0.5);
			sp.graphics.drawTriangles(vertices,indices);
			sp.graphics.endFill();
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// steer to flock and perhaps to stay within the spherical boundary
			applySteeringForce(Vector3.VectorAddition(SteerToFlock() , HandleBoundary()),elapsedTime);
			
			// notify proximity database that our position has changed
			proximityToken.updateForNewPosition(Position);
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
			neighbors = [];
			proximityToken.findNeighbors (Position,maxRadius,neighbors);

			// determine each of the three component behaviors of flocking
			var separation:Vector3=steerForSeparation(separationRadius,separationAngle,neighbors);
			var alignment:Vector3=steerForAlignment(alignmentRadius,alignmentAngle,neighbors);
			var cohesion:Vector3=steerForCohesion(cohesionRadius,cohesionAngle,neighbors);

			// apply weights to components (save in variables for annotation)
			var separationW:Vector3=Vector3.ScalarMultiplication(separationWeight,separation);
			var alignmentW:Vector3=Vector3.ScalarMultiplication(alignmentWeight,alignment);
			var cohesionW:Vector3 = Vector3.ScalarMultiplication(cohesionWeight, cohesion);
			
			return Vector3.VectorAddition(Vector3.VectorAddition(separationW,alignmentW),cohesionW);
		}

		// Take action to stay within sphereical boundary.  Returns steering
		// value (which is normally zero) and may take other side-effecting
		// actions such as kinematically changing the Boid's position.
		public function HandleBoundary ():Vector3
		{
			// while inside the sphere do noting
			if (Position.Magnitude() < worldRadius)
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
						var lateral:Vector3 = Utility.perpendicularComponent(seek, forward);
						return lateral;

					}
				case 1 :
					{
						// wrap around (teleport)
						Position = Utility.sphericalWrapAround(Position, Vector3.ZERO, worldRadius);
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