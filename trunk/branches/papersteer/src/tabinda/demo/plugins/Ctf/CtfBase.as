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
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.Papervision3D;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	public class CtfBase extends SimpleVehicle
	{
		public var trail:Trail;
		
		protected static var obstacleCount:int=-1;
		protected static const maxObstacleCount:int=100;
		public static var AllObstacles:Vector.<SphericalObstacle> = new Vector.<SphericalObstacle>();
		
		// for draw method
		public var BodyColor:uint;

		// xxx store steer sub-state for anotation
		public var Avoiding:Boolean;
		
		// PV3D variables
		public var ColorTexture:ColorMaterial;
		public var UVCoord:Array;
		public var VehicleFace:Triangle3D;
		public var LineList:Lines3D;

		// constructor
		public function CtfBase ()
		{
			initPV3D();
			
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
		public override function Reset ():void
		{
			super.Reset ();									// reset the vehicle 

			Speed=3;										// speed along Forward direction.
			MaxForce=3.0;									// steering force is clipped to this magnitude
			MaxSpeed=3.0;									// velocity is clipped to this magnitude

			Avoiding=false;									// not actively avoiding

			RandomizeStartingPositionAndHeading ();			// new starting position
			if ( trail == null)
			{
				trail = new Trail();
				annotation.AddTrail(trail);
			}
			annotation.ClearTrail(trail);					// prevent long streaks due to teleportation
		}
		
		public function removeTrail():void
		{
			annotation.RemoveTrail(trail);
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
			
			ColorTexture.fillColor = BodyColor;
			
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

			annotation.DrawAllTrails();
		}

		// TTT - Handled by Annotation now.
		// annotate when actively avoiding obstacles
		// xxx perhaps this should be a call to a general purpose annotation
		// xxx for "local xxx axis aligned box in XZ plane" -- same code in in
		// xxx Pedestrian.cpp
		public function AnnotateAvoidObstacle (minDistanceToCollision:Number):void
		{
			var boxSide:Vector3=Vector3.ScalarMultiplication(Radius,Side);
			var boxFront:Vector3=Vector3.ScalarMultiplication(minDistanceToCollision,Forward);
			var FR:Vector3=Vector3.VectorAddition(Position , Vector3.VectorSubtraction(boxFront, boxSide));
			var FL:Vector3=Vector3.VectorAddition(Position , Vector3.VectorAddition(boxFront , boxSide));
			var BR:Vector3=Vector3.VectorSubtraction(Position , boxSide);
			var BL:Vector3=Vector3.VectorAddition(Position , boxSide);
			annotation.Line (FR,FL,Colors.White);
			annotation.Line (FL,BL,Colors.White);
			annotation.Line (BL,BR,Colors.White);
			annotation.Line (BR,FR,Colors.White);
		}

		public function DrawHomeBase ():void
		{
			var up:Vector3=new Vector3(0,0.01,0);
			var atColor:uint=Colors.RGBToHex(int(255.0 * 0.3),int(255.0 * 0.3),int(255.0 * 0.5));
			var noColor:uint=Colors.Gray;
			var reached:Boolean=CtfPlugIn.Seeker.State == SeekerState.AtGoal;
			var baseColor:uint = reached?atColor:noColor;
			
			DrawCircleOrDisk (Globals.HomeBaseRadius,Vector3.Zero,Globals.HomeBaseCenter,baseColor,40,true,false);
			DrawCircleOrDisk (Globals.HomeBaseRadius / 15,Vector3.Zero,Vector3.VectorAddition(Globals.HomeBaseCenter , up),Colors.Black,20,true,false);
		}

		public function RandomizeStartingPositionAndHeading ():void
		{
			// randomize position on a ring between inner and outer radii
			// centered around the home base
			var rRadius:Number=Utilities.random(Globals.MinStartRadius,Globals.MaxStartRadius);
			var randomOnRing:Vector3 = Vector3.ScalarMultiplication( rRadius, VHelper.RandomUnitVectorOnXZPlane());			
			Position = Vector3.VectorAddition(Globals.HomeBaseCenter , randomOnRing);

			// are we are too close to an obstacle?
			if (MinDistanceToObstacle(Position) < Radius * 5)
			{
				// if so, retry the randomization (this recursive call may not return
				// if there is too little free space)
				RandomizeStartingPositionAndHeading ();
			}
			else
			{
				// otherwise, if the position is OK, randomize 2D heading
				RandomizeHeadingOnXZPlane ();
			}
		}

		// dynamic obstacle registry
		public static  function InitializeObstacles ():void
		{
			// start with 40% of possible obstacles
			if (obstacleCount == -1)
			{
				obstacleCount=0;
				for (var i:int=0; i < maxObstacleCount * 0.4; i++)
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
				var r:Number;
				var c:Vector3;
				var minClearance:Number;
				var requiredClearance:Number=CtfPlugIn.Seeker.Radius * 4;// 2 x diameter
				do
				{
					r=Utilities.random(1.5,4);
					c=Vector3.ScalarMultiplication(Globals.MaxStartRadius * 1.1,VHelper.RandomVectorOnUnitRadiusXZDisk());
					minClearance=Number.MAX_VALUE;
					
					for (var so:int=0; so < AllObstacles.length; so++)
					{
						minClearance=TestOneObstacleOverlap(minClearance,r,AllObstacles[so].Radius,c,AllObstacles[so].Center);
					}

					minClearance=TestOneObstacleOverlap(minClearance,r,Globals.HomeBaseRadius - requiredClearance,c,Globals.HomeBaseCenter);
				} while (minClearance < requiredClearance);

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
				AllObstacles.splice(obstacleCount,1);
			}
		}

		public function MinDistanceToObstacle (point:Vector3):Number
		{
			var r:Number=0;
			var c:Vector3=point;
			var minClearance:Number=Number.MAX_VALUE;
			for (var so:int=0; so < AllObstacles.length; so++)
			{
				minClearance=TestOneObstacleOverlap(minClearance,r,AllObstacles[so].Radius,c,AllObstacles[so].Center);
			}
			return minClearance;
		}

		private static function TestOneObstacleOverlap (minClearance:Number,r:Number,radius:Number,c:Vector3,center:Vector3):Number
		{
			var d:Number=Vector3.Distance(c,center);
			var clearance:Number=d - (r + radius);
			if (minClearance > clearance)
			{
				minClearance=clearance;
			}
			return minClearance;
		}
	}
}