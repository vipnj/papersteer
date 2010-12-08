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

package tabinda.demo.plugins.Soccer
{
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.Papervision3D;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class Ball extends SimpleVehicle
	{
		public var trail:Trail;
		
		// PV3D variables
		public var ColorTexture:ColorMaterial;
		public var UVCoord:Array;
		public var VehicleFace:Triangle3D;
		public var LineList:Lines3D;
		
		public function Ball (bbox:AABBox)
		{
			initPV3D();
			
			m_bbox=bbox;
			Reset ();
		}
		
		public function initPV3D():void
		{
			UVCoord = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			LineList = new Lines3D(new LineMaterial(0x000000, 1));
			
			ColorTexture = new ColorMaterial(0x000000, 1);
			ColorTexture.doubleSided = false;
			ColorTexture.interactive = false;

			VehicleFace = new Triangle3D(VehicleMesh, new Array, ColorTexture, UVCoord);
			
			VehicleMesh = new TriangleMesh3D(ColorTexture , new Array(), new Array(), null);
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 
			Speed=0.0;// speed along Forward direction.
			MaxForce=9.0;// steering force is clipped to this magnitude
			MaxSpeed=9.0;// velocity is clipped to this magnitude

			SetPosition (0,0,0);
			if (trail == null)
			{
				trail = new Trail(100, 6000);
				annotation.AddTrail(trail);
			}
			annotation.ClearTrail(trail);// prevent long streaks due to teleportation 
		}
		
		public function removeTrail():void
		{
			annotation.RemoveTrail(trail);
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			ApplyBrakingForce (1.5,elapsedTime);
			ApplySteeringForce (Velocity, elapsedTime);
			 
			// are we now outside the field?
			if (!m_bbox.IsInsideX(Position))
			{
				var d:Vector3=Velocity;
				RegenerateOrthonormalBasis (new Vector3(- d.x,d.y,d.z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			if (! m_bbox.IsInsideZ(Position))
			{
				d = Velocity;
				RegenerateOrthonormalBasis (new Vector3(d.x,d.y,- d.z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			
			trail.Record (currentTime,Position);
		}

		public function Kick (dir:Vector3,elapsedTime:Number):void
		{
			Speed=dir.Magnitude();
			RegenerateOrthonormalBasis (dir);
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
			var u:Vector3 = Vector3.ScalarMultiplication((r * 0.05),new Vector3(0, 0, 0)); // slightly up
			var f:Vector3 = Vector3.ScalarMultiplication(r,Forward);
			var s:Vector3 = Vector3.ScalarMultiplication(x * r, Side);
			var b:Vector3 = Vector3.ScalarMultiplication(-y*r,Forward);

			var a:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , f) , u).ToVertex3D();
			var d:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			var e:Vertex3D = Vector3.VectorAddition( Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			
			ColorTexture.fillColor = Colors.Green;
			
			// draw double-sided triangle (that is: no (back) face culling)
			VehicleMesh.geometry.vertices.push(a,d,e);
			
			VehicleFace.reset(VehicleMesh, [a, d, e], ColorTexture, UVCoord);
			
			VehicleMesh.geometry.faces.push(VehicleFace);

			VehicleMesh.geometry.ready = true;
						
			// draw the circular collision boundary
			DrawCircleOrDisk(r, Vector3.Zero,Vector3.VectorAddition(p , u), Colors.White, 7,false,false);
		}
		
		private function DrawCircleOrDisk(radius:Number,axis:Vector3,center:Vector3,color:uint,segments:int,filled:Boolean,in3d:Boolean):void
		{
			if (Demo.IsDrawPhase())
			{
				var temp : Number3D = new Number3D(radius,0,0);
				var tempcurve:Number3D = new Number3D(0,0,0);
				var joinends : Boolean;
				var i:int;
				var pointcount : int;
				
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
					var line:Line3D = new Line3D(LineList, new LineMaterial(Colors.White), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					LineList.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(LineList,Radius, axis, center, color, segments, filled, in3d);
			}
		}


		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			VehicleMesh.geometry.vertices = [];
			VehicleMesh.geometry.faces = [];
			
			LineList.geometry.faces = [];
            LineList.geometry.vertices = [];
            LineList.removeAllLines();

			DrawBasic2dCircularVehicle();
			annotation.DrawTrail(trail);
		}

		private var m_bbox:AABBox;
	}
}