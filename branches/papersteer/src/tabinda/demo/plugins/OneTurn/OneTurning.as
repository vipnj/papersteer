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

package tabinda.demo.plugins.OneTurn
{
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	public class OneTurning extends SimpleVehicle
	{
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		public var triangle:Triangle3D;
		public var lines:Lines3D;
		
		private var trail:Trail;

		// constructor
		public function OneTurning ()
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			lines = new Lines3D(new LineMaterial(0x000000, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			colMat.interactive = false;

			triangle = new Triangle3D(objectMesh, new Array, colMat, uvArr);
			
			objectMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 
			Speed=1.5;// speed along Forward direction.
			MaxForce=0.3;// steering force is clipped to this magnitude
			MaxSpeed=5;// velocity is clipped to this magnitude
			//trail=new Trail();
			//trail.Clear ();// prevent long streaks due to teleportation 
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			ApplySteeringForce (new Vector3(-2,0,-3),elapsedTime);
			annotation.VelocityAcceleration (this);
			//trail.Record (currentTime,Position);
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			objectMesh.geometry.vertices = [];
			objectMesh.geometry.faces = [];
			
			lines.geometry.faces = [];
            lines.geometry.vertices = [];
            lines.removeAllLines();
			
			//Drawing.DrawBasic2dCircularVehicle (this,OneMesh,triArr,uvArr,Colors.Gray);
			DrawBasic2dCircularVehicle();
			//trail.Draw (Annotation.drawer);
		}
		
		private function DrawBasic2dCircularVehicle():void
		{
			// "aspect ratio" of body (as seen from above)
			var x:Number = 0.5;
			var y:Number = Number(Math.sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = Radius;
			var p:Vector3 = Position;

			// shape of triangular body
			var u:Vector3 = Vector3.ScalarMultiplication((r * 0.05),new Vector3(0, 1, 0)); // slightly up
			var f:Vector3 = Vector3.ScalarMultiplication(r,Forward);
			var s:Vector3 = Vector3.ScalarMultiplication(x * r, Side);
			var b:Vector3 = Vector3.ScalarMultiplication(-y*r,Forward);

			var a:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , f) , u).ToVertex3D();
			var d:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			var e:Vertex3D = Vector3.VectorAddition( Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			
			colMat.fillColor = Colors.Orange;
			
			// draw double-sided triangle (that is: no (back) face culling)
			objectMesh.geometry.vertices.push(a,d,e);
			
			triangle.reset(objectMesh, [a, d, e], colMat, uvArr);
			
			objectMesh.geometry.faces.push(triangle);
			
			objectMesh.geometry.ready = true;
						
			// draw the circular collision boundary
			DrawXZCircle(r, Vector3.VectorAddition(p , u), Colors.White, 20);
		}
		
		private function DrawXZCircle(radius:Number,center:Vector3,color:uint,segments:int):void
		{
			if (Demo.IsDrawPhase())
			{
				var axis:Vector3 = Vector3.Zero;
				var temp : Number3D = new Number3D(Radius,0,0);
				var tempcurve:Number3D = new Number3D(0,0,0);
				var joinends : Boolean;
				var i:int;
				var pointcount : int;
				var filled:Boolean = false;
				var in3d:Boolean = false;
				
				var angle:Number = (0-360)/segments;
				var curveangle : Number = angle/2;

				tempcurve.x = Radius/Math.cos(curveangle * Number3D.toRADIANS);
				tempcurve.rotateY(curveangle+0);

				if(360-0<360)
				{
					joinends = false;
					pointcount = segments+1;
				}
			   else
				{
					joinends = true;
					pointcount = segments;
				}
			   
				temp.rotateY(0);

				var vertices:Array = new Array();
				var curvepoints:Array = new Array();

				for(i = 0; i< pointcount;i++)
				{
					vertices.push(new Vertex3D(center.x+temp.x, center.y+temp.y, center.z+temp.z));
					curvepoints.push(new Vertex3D(center.x+tempcurve.x, center.y+tempcurve.y, center.z+tempcurve.z));
					temp.rotateY(angle);
					tempcurve.rotateY(angle);
				}

				for(i = 0; i < segments ;i++)
				{
					var line:Line3D = new Line3D(lines, new LineMaterial(Colors.White), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					lines.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(lines,Radius, axis, center, color, segments, filled, in3d);
			}
		}
	}
}