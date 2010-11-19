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

package tabinda.demo.plugins.Boids
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.objects.*;
	import org.papervision3d.Papervision3D;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;

	public class Boid extends SimpleVehicle
	{		
		public var uvArr:Array;							// UV Array to assign texture
		public var triArr:Vector.<Triangle3D>;			// Triangle Array for the Mesh
		public var colArr:Vector.<ColorMaterial>;		// Used to assign a color Material to the Mesh
		
		// a pointer to this boid's interface object for the proximity database
		public var proximityToken:ITokenForProximityDatabase;

		// allocate one and share amoung instances just to save memory usage
		// (change to per-instance allocation to be more MP-safe)
		public static  var neighbors:Vector.<IVehicle>=new Vector.<IVehicle>();
		public static  var boundaryCondition:int=0;
		public static const worldRadius:Number=50.0;

		// constructor
		public function Boid (pd:IProximityDatabase)
		{
			// allocate a token for this boid in the proximity database
			proximityToken=null;
			NewPD (pd);
			
			// Keep the Steer Library Clean from PV3D Stuff
			initPV3D();
			
			// reset all boid state
			Reset ();
		}
		
		public function initPV3D():void
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			triArr = new Vector.<Triangle3D>(6);
			colArr = new Vector.<ColorMaterial>(6);
			
			for (var i:int = 0; i < 6; i++)
			{
				colArr[i] = new ColorMaterial(0x000000, 1, false);
				colArr[i].doubleSided = false;
				triArr[i] = new Triangle3D(objectMesh, new Array(), colArr[i]);
			}
			
			objectMesh = new TriangleMesh3D(colArr[0] , new Array(), new Array(), null);
		}

		// reset state
		public override  function Reset ():void
		{
			// reset the vehicle
			super.Reset ();

			// steering force is clipped to this magnitude
			MaxForce=27.0;

			// velocity is clipped to this magnitude
			MaxSpeed=9.0;

			// initial slow speed
			Speed = MaxSpeed * 0.3;
			
			RegenerateOrthonormalBasisUF (VHelper.RandomUnitVector());
			
			// randomize initial position
			Position = Vector3.ScalarMultiplication(20.0,VHelper.RandomVectorInUnitRadiusSphere());
			
			// notify proximity database that our position has changed
			// FIXME: SimpleVehicle::SimpleVehicle() calls reset() before proximityToken is set
			if (proximityToken != null)
			{
				proximityToken.UpdateForNewPosition (Position);
			}
		}

		// draw this boid into the scene
		public function Draw ():void
		{
			objectMesh.geometry.vertices =[];
			objectMesh.geometry.faces = [];
			
			DrawBasic3dSphericalVehicle();
		}
		
		private function DrawBasic3dSphericalVehicle():void
		{
			var vColor:Vector3 = Colors.HexToVector(Colors.LightGray);
			
			// "aspect ratio" of body (as seen from above)
			const x:Number = 0.5;
			var y:Number = Number(Math.sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = Radius;
			var p:Vector3 = Position;

			// body shape parameters
			var f:Vector3 = Vector3.ScalarMultiplication(r,Forward);
			var s:Vector3 = Vector3.ScalarMultiplication((r * x), Side);
			var u:Vector3 = Vector3.ScalarMultiplication((r * x * 0.5),Up);
			var b:Vector3 = Vector3.ScalarMultiplication(r * -y,Forward);

			// vertex positions
			var nose:Vertex3D = Vector3.VectorAddition(p , f).ToVertex3D();
			var side1:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , s).ToVertex3D();
			var side2:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , s).ToVertex3D();
			var top:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , u).ToVertex3D();
			var bottom:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , u).ToVertex3D();;
	
			// colors
			const j:Number = +0.05;
			const k:Number = -0.05;
			
			colArr[0].fillColor = Colors.VectorToHex(Vector3.VectorAddition(vColor , new Vector3(j, j, k)));
			colArr[1].fillColor = Colors.VectorToHex(Vector3.VectorAddition(vColor , new Vector3(j, k, j)));
			colArr[2].fillColor = Colors.VectorToHex(Vector3.VectorAddition(vColor , new Vector3(k, j, j)));
			colArr[3].fillColor = Colors.VectorToHex(Vector3.VectorAddition(vColor , new Vector3(k, j, k)));
			colArr[4].fillColor = Colors.VectorToHex(Vector3.VectorAddition(vColor , new Vector3(k, k, j)));
			
			objectMesh.geometry.vertices.push(nose,top,side1,side2,bottom);
			
			triArr[0].reset(objectMesh, [nose, side1, top], colArr[0],uvArr);
			triArr[1].reset(objectMesh, [nose, top, side2], colArr[1], uvArr);
			triArr[2].reset(objectMesh, [nose, bottom, side1], colArr[2], uvArr);
			triArr[3].reset(objectMesh, [nose, side2, bottom], colArr[3], uvArr);
			triArr[4].reset(objectMesh, [side1, side2, top], colArr[4], uvArr);
			triArr[5].reset(objectMesh, [side2, side1, bottom], colArr[4], uvArr);
			
			objectMesh.geometry.faces.push(triArr[0]);
			objectMesh.geometry.faces.push(triArr[1]);
			objectMesh.geometry.faces.push(triArr[2]);
			objectMesh.geometry.faces.push(triArr[3]);
			objectMesh.geometry.faces.push(triArr[4]);
			objectMesh.geometry.faces.push(triArr[5]);

			objectMesh.geometry.ready = true;
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// steer to flock and perhaps to stay within the spherical boundary
			ApplySteeringForce (Vector3.VectorAddition(SteerToFlock() , HandleBoundary()), elapsedTime);

			// notify proximity database that our position has changed
			proximityToken.UpdateForNewPosition (Position);
		}

		// basic flocking
		public function SteerToFlock ():Vector3
		{
			const separationRadius:Number = 5.0;
			const separationAngle:Number = -0.707;
			const separationWeight:Number = 12.0;

			const alignmentRadius:Number=7.5;
			const alignmentAngle:Number=0.7;
			const alignmentWeight:Number=8.0;

			const cohesionRadius:Number=9.0;
			const cohesionAngle:Number=-0.15;
			const cohesionWeight:Number=8.0;

			var maxRadius:Number=Math.max(separationRadius,Math.max(alignmentRadius,cohesionRadius));

			// find all flockmates within maxRadius using proximity database
			neighbors.splice(0,neighbors.length);
			neighbors = proximityToken.FindNeighbors (Position,maxRadius,neighbors);

			// determine each of the three component behaviors of flocking
			var separation:Vector3=SteerForSeparation(separationRadius,separationAngle,neighbors);
			var alignment:Vector3=SteerForAlignment(alignmentRadius,alignmentAngle,neighbors);
			var cohesion:Vector3=SteerForCohesion(cohesionRadius,cohesionAngle,neighbors);

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
				return Vector3.Zero;
			}

			// once outside, select strategy
			switch (boundaryCondition)
			{
				case 0 :
					{
						// steer back when outside
						var seek:Vector3=xxxSteerForSeek(Vector3.Zero);
						var lateral:Vector3=VHelper.PerpendicularComponent(seek,Forward);
						return lateral;

					}
				case 1 :
					{
						// wrap around (teleport)
						Position=VHelper.SphericalWrapAround(Position,Vector3.Zero,worldRadius);
						return Vector3.Zero;

				}
			}
			return Vector3.Zero;// should not reach here
		}

		// make boids "bank" as they fly
		public override  function RegenerateLocalSpace (newVelocity:Vector3,elapsedTime:Number):void
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
			boundaryCondition=(boundaryCondition + 1) % max;
		}
	}
}