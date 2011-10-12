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
	import flash.filters.ColorMatrixFilter;
	import flash.ui.Keyboard;
	
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.Papervision3D;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;

	// Capture the Flag   (a portion of the traditional game)
	//
	// The "Capture the Flag" sample steering problem, proposed by Marcin
	// Chady of the Working Group on Steering of the IGDA's AI Interface
	// Standards Committee (http://www.igda.org/Committees/ai.htm) in this
	// message (http://sourceforge.net/forum/message.php?msg_id=1642243):
	//
	//     "An agent is trying to reach a physical location while trying
	//     to stay clear of a group of enemies who are actively seeking
	//     him. The environment is littered with obstacles, so collision
	//     avoidance is also necessary."
	//
	// Note that the enemies do not make use of their knowledge of the 
	// seeker's goal by "guarding" it.  
	//
	// XXX hmm, rename them "attacker" and "defender"?
	//
	// 08-12-02 cwr: created 
	public class CtfPlugIn extends PlugIn
	{
		// a group (STL vector) of all vehicles in the PlugIn
		private var all:Vector.<CtfBase>;
		
		public var GridMesh:TriangleMesh3D;						// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var HomeBaseOuterCircle:TriangleMesh3D;			// Home base outer circle
		public var HomeBaseInnerCircle:TriangleMesh3D;			// Home base inner circle
		public var HighlightDisk:TriangleMesh3D;				// Used to highlight the selected vehicle
		public var Obstacles:Lines3D;							// Used to draw obstacles
		public var ColorTexture:ColorMaterial;					// Color Texture to initialize Meshes
		public var UVCoordTop:Array;							// UV Coordinates for Grid Top Triangles - Not Needed?
		public var UVCoordBottom:Array;							// UV Coordinates for Grid Bottom Triangles - Not Needed?
	
		// state for OpenSteerDemo PlugIn
		//
		// TTT moved here from Globals
		// TTT using Vector for CtfEnemy, should be faster
		public static var Seeker:CtfSeeker;
		public static var CtfEnemyCount:int = 4;
		public static var CtfEnemies:Vector.<CtfEnemy> = new Vector.<CtfEnemy>(CtfEnemyCount);
		
		public var ForceRedraw:Boolean;
		
		public function CtfPlugIn ()
		{			
			super ();
			all=new Vector.<CtfBase>();
		}
		
		public function initPV3D():void
		{
			UVCoordTop = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
            UVCoordBottom = new Array(new NumberUV(1, 1), new NumberUV(0, 1), new NumberUV(1, 0));
			
			ColorTexture = new ColorMaterial(0x000000, 1);
			ColorTexture.doubleSided = false;
			
			GridMesh = new TriangleMesh3D(ColorTexture , new Array(), new Array());
			HighlightDisk = new TriangleMesh3D(ColorTexture , new Array(), new Array());
			HomeBaseOuterCircle = new TriangleMesh3D(ColorTexture , new Array(), new Array());
			HomeBaseInnerCircle = new TriangleMesh3D(ColorTexture , new Array(), new Array());
			Obstacles = new Lines3D(new LineMaterial(0x000000, 1));
			
			addPV3DObject(Obstacles);
			addPV3DObject(HighlightDisk);
			addPV3DObject(HomeBaseInnerCircle);
			addPV3DObject(HomeBaseOuterCircle);
			addPV3DObject(GridMesh);
		}

		public override  function get Name ():String { return "Capture the Flag"; }

		public override  function get SelectionOrderSortKey ():Number {	return 0.01; }
		
		public override  function Open ():void
		{
			initPV3D();
			
			ForceRedraw = true;
			
			// create the seeker ("hero"/"attacker")
			Seeker=new CtfSeeker();
			all.push (Seeker);
			
			addPV3DObject(Seeker.VehicleMesh);
			addPV3DObject(Seeker.LineList);
			Seeker.VehicleMesh.addChild(Seeker.text3D);
			
			// create the specified number of enemies, 
			// storing pointers to them in an array.
			for (var i:int=0; i < CtfEnemyCount; i++)
			{
				CtfEnemies[i]=new CtfEnemy();
				all.push (CtfEnemies[i]);
				addPV3DObject(CtfEnemies[i].VehicleMesh);
				addPV3DObject(CtfEnemies[i].LineList);
			}

			// initialize camera
			Demo.Init2dCamera (Seeker);
			Demo.camera.Mode=CameraMode.FixedDistanceOffset;
			Demo.camera.FixedTarget=Vector3.Zero;
			Demo.camera.FixedTarget.x=15;
			Demo.camera.FixedPosition.x=80;
			Demo.camera.FixedPosition.y=60;
			Demo.camera.FixedPosition.z=0;

			CtfBase.InitializeObstacles ();
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update the seeker
			Seeker.Update (currentTime, elapsedTime);
			
			// update each enemy
			for (var i:int=0; i < CtfEnemyCount; i++)
			{
				CtfEnemies[i].Update (currentTime, elapsedTime);
			}
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// selected vehicle (user can mouse click to select another)
			var selected:IVehicle=Demo.SelectedVehicle;

			// vehicle nearest mouse (to be highlighted)
			var nearMouse:IVehicle = Demo.VehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera (currentTime,elapsedTime,selected);
			
			// draw "ground plane" centered between base and selected vehicle
			var goalOffset:Vector3=Vector3.VectorSubtraction(Globals.HomeBaseCenter , Demo.camera.Position);
			var goalDirection:Vector3=goalOffset;
			goalDirection.Normalize();
			
			var cameraForward:Vector3=Demo.camera.xxxls().Forward;
			var goalDot:Number=cameraForward.DotProduct(goalDirection);
			var blend:Number=Utilities.RemapIntervalClip(goalDot,1,0,0.5,0);
			var gridCenter:Vector3=Utilities.Interpolate2(blend,selected.Position,Globals.HomeBaseCenter);
			
			// draw the seeker, obstacles and home base
			Seeker.Draw ();
		
			HighlightDisk.geometry.faces = [];
			HighlightDisk.geometry.vertices = [];
				
			// We do  this because PV3D and AS3 are not Canvas based Drawers
			if(ForceRedraw)
			{
				HomeBaseInnerCircle.geometry.faces = [];
				HomeBaseOuterCircle.geometry.faces = [];
				HomeBaseInnerCircle.geometry.vertices = [];
				HomeBaseOuterCircle.geometry.vertices = [];
				
				Obstacles.geometry.faces = [];
				Obstacles.geometry.vertices = [];
				Obstacles.removeAllLines();
				
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
				
				Grid(gridCenter);
			
				// Should be drawn once per restart or obstacle insertion/removal, PV3D is clumsy on constant Redrawing
				DrawObstacles ();
				
				// Should be drawn once per restart, PV3D is clumsy on constant Redrawing
				DrawHomeBase ();
				
				ForceRedraw = false;
			}
			
			// draw each enemy
			for (var i:int=0; i < CtfEnemyCount; i++)
			{
				CtfEnemies[i].Draw ();
			}

			// highlight vehicle nearest mouse
			HighlightVehicleUtility (nearMouse);
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
											 Number(Math.round(gridTarget.y * 0.5) * 2),
										     Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.DarkGray;
			var gray2:uint = 0x333333;
			
			var size:int = 50;
			var subsquares:int = 50;
			
			var half:int = int(size / 2);
			var spacing:int= int(size / subsquares);

			var flag1:Boolean = false;
			var p:int = -half;
			var corner:Vector3 = new Vector3();

			for (var i:int = 0; i < subsquares; i++)
			{
				var flag2:Boolean = flag1;
				var q:int = -half;
				for (var j:int = 0; j < subsquares; j++)
				{
					corner.x = p;
					corner.y = -.5;
					corner.z = q;

					corner = Vector3.VectorAddition(corner, center);
					
					var vertA:Vertex3D = corner.ToVertex3D();
					var vertB:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, 0)).ToVertex3D();
					var vertC:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, spacing)).ToVertex3D();
					var vertD:Vertex3D = Vector3.VectorAddition(corner, new Vector3(0, 0, spacing)).ToVertex3D();
					
					GridMesh.geometry.vertices.push(vertA, vertB, vertC, vertD);
					
					var color:uint = flag2 ? gray1 : gray2;
					var colMaterial:ColorMaterial = new ColorMaterial(color, 1);
					colMaterial.doubleSided = true;
			
					var t1:Triangle3D = new Triangle3D(GridMesh, [vertA,vertB,vertC], colMaterial,UVCoordTop);
					var t2:Triangle3D = new Triangle3D(GridMesh, [vertD,vertA,vertC], colMaterial,UVCoordBottom);
			
					GridMesh.geometry.faces.push(t1);
					GridMesh.geometry.faces.push(t2);
					
					flag2 = !flag2;
					q += spacing;
				}
				flag1 = !flag1;
				p += spacing;
			}
			GridMesh.geometry.ready = true;
		}
		
		/**
		 * Draws a colored circle (perpendicular to view axis) around the center
		 * of a given vehicle.  The circle's radius is the vehicle's radius times
		 * radiusMultiplier.
		 * @param	v is a Vehicle
		 */
		public function HighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				var cPosition:Vector3 = Demo.camera.Position;
				var radius:Number = vehicle.Radius;  							 					 	// adjusted radius
				var	center:Vector3 = vehicle.Position;                   							 	// center
				var axis:Vector3 = 	Vector3.VectorSubtraction(vehicle.Position , cPosition);       		// view axis
				var color:uint = 	Colors.LightGray;                        				 			// drawing color
				var	segments:int = 20;                          						 	 				// circle segments
				var filled:Boolean = true;
				var in3d:Boolean = false;
				
				DrawDisk(HighlightDisk, radius, axis, center, color, segments, filled, in3d);
			}
		}

		public override  function Close ():void
		{
			// delete seeker
			destoryPV3DObject(Seeker.VehicleMesh);
			destoryPV3DObject(Seeker.text3D);
			destoryPV3DObject(Seeker.LineList);
			Seeker.removeTrail();
			
			Seeker = null;
			
			//Remove PV3D Grid and Lines Mesh
			destoryPV3DObject(GridMesh);
			destoryPV3DObject(Obstacles);
			destoryPV3DObject(HighlightDisk);
			destoryPV3DObject(HomeBaseInnerCircle);
			destoryPV3DObject(HomeBaseOuterCircle);

			// delete each enemy
			for (var i:int=0; i < CtfEnemyCount; i++)
			{
				destoryPV3DObject(CtfEnemies[i].VehicleMesh);
				destoryPV3DObject(CtfEnemies[i].LineList);
				CtfEnemies[i].removeTrail();
				
				CtfEnemies[i] = null;
			}
			
			// clear the group of all vehicles
			all.splice(0,all.length);
		}
		
		private function destoryPV3DObject(object:*):void 
		{
			Demo.container.removeChild(object);
			object.material.destroy();
			object = null;
		}
		
		private function addPV3DObject(object:*):void
		{
			Demo.container.addChild(object);
		}

		public override  function Reset ():void
		{
			// count resets
			Globals.ResetCount++;

			// reset the seeker ("hero"/"attacker") and enemies
			Seeker.Reset ();
			
			for (var i:int=0; i < CtfEnemyCount; i++)
			{
				CtfEnemies[i].Reset ();
			}

			// reset camera position
			Demo.Position2dCamera (Seeker);

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove ();
			
			ForceRedraw = true;
		}

		public override  function HandleFunctionKeys (key:uint):void
		{
			switch (key)
			{
				case Keyboard.F1:
					CtfBase.AddOneObstacle ();
					ForceRedraw = true;
					break;
				case Keyboard.F2:
					CtfBase.RemoveOneObstacle ();
					ForceRedraw = true;
					break;
			}
		}

		public override  function PrintMiniHelpForFunctionKeys ():void
		{
			var message:String = "Function keys handled by " + "\"" + Name+ "\"" + ":";
			Demo.printMessage (message);
			Demo.printMessage ("  F1     add one obstacle.");
			Demo.printMessage ("  F2     remove one obstacle.");
			Demo.printMessage ("");
		}

		public override function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(all);
			return vehicles;
		}
		
		private function DrawDisk(drawUtil:TriangleMesh3D, radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void
		{
			var ls:LocalSpace = new LocalSpace();
				
			if (in3d)
			{
				// define a local space with "axis" as the Y/up direction
				// (XXX should this be a method on  LocalSpace?)
				var unitAxis:Vector3 = axis;
				unitAxis.Normalize();
				var unitPerp:Vector3 = VHelper.FindPerpendicularIn3d(axis);
				unitPerp.Normalize();
				ls.Up = unitAxis;
				ls.Forward = unitPerp;
				ls.Position = (center);
				ls.SetUnitSideFromForwardAndUp();
			}
			
			var colorMaterial:ColorMaterial = new ColorMaterial(color, 1);
			var cvertices:Array = drawUtil.geometry.vertices;
			var cfaces:Array = drawUtil.geometry.faces;
			
			// make disks visible (not culled) from both sides 
			if (filled) colorMaterial.doubleSided = true;

			// point to be rotated about the (local) Y axis, angular step size
			var pointOnCircle:Vector3 = new Vector3(radius, 0, 0);
			var step:Number = Number((2 * Math.PI)) / Number(segments);

			// for the filled case, first emit the center point
			var vertA:Vertex3D;
			if (filled) 
			{
				vertA = (in3d ? ls.Position.ToVertex3D() : center.ToVertex3D());
			}
			cvertices.push(vertA);
			
			// rotate p around the circle in "segments" steps
			var sin:Number = 0, cos:Number = 0;
			var vertexCount:int = filled ? segments + 1 : segments;
			
			for (var h:int = 0; h < vertexCount; h++)
			{
				// emit next point on circle, either in 3d (globalized out
				// of the local space), or in 2d (offset from the center)
				cvertices.push(in3d ? ls.GlobalizePosition(pointOnCircle).ToVertex3D() : Vector3.VectorAddition(pointOnCircle, center).ToVertex3D());

				// rotate point one more step around circle
				var tempResults:Array = VHelper.RotateAboutGlobalY(pointOnCircle, step, sin, cos);
				sin = tempResults[0]
				cos = tempResults[1]
				pointOnCircle = tempResults[2];
			}

			for (var g:int = 1; g != vertexCount; g++)
			{	
				var triangle:Triangle3D = new Triangle3D(drawUtil, [cvertices[0], cvertices[g], cvertices[g+1]], colorMaterial);
				cfaces.push(triangle);
			}
			drawUtil.geometry.faces = cfaces;
			drawUtil.geometry.vertices = cvertices;
			drawUtil.geometry.ready = true;
		}
		
		private function DrawCircle(drawUtil:Lines3D,radius:Number, axis:Vector3,center:Vector3, color:uint, segments:int,filled:Boolean,in3d:Boolean):void
		{
			if (Demo.IsDrawPhase())
			{
				var temp : Number3D = new Number3D(radius,0,0);
				var tempcurve:Number3D = new Number3D(0,0,0);
				var joinends : Boolean;
				var i:int;
				var pointcount : int;

				var angle:Number = (360)/segments;
				var curveangle : Number = angle/2;

				tempcurve.x = radius/Math.cos(curveangle * Number3D.toRADIANS);
				tempcurve.rotateY(curveangle);

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
					var line:Line3D = new Line3D(drawUtil, new LineMaterial(color), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					drawUtil.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(drawUtil,radius, axis, center, color, segments, filled, in3d);
			}
		}

		public function DrawHomeBase ():void
		{
			var up:Vector3=new Vector3(0,0.01,0);
			var atColor:uint=Colors.RGBToHex(int(255.0 * 0.3),int(255.0 * 0.3),int(255.0 * 0.5));
			var noColor:uint=Colors.Green;
			var reached:Boolean=Seeker.State == SeekerState.AtGoal;
			var baseColor:uint=reached?atColor:noColor;
			
			DrawDisk (HomeBaseOuterCircle,Globals.HomeBaseRadius,Vector3.Zero,Globals.HomeBaseCenter,baseColor,22,true,false);
			DrawDisk (HomeBaseInnerCircle,Globals.HomeBaseRadius / 15,Vector3.Zero,Vector3.VectorAddition(Globals.HomeBaseCenter , up),Colors.Black,8,true,false);
		}

		public function DrawObstacles ():void
		{
			var color:uint=Colors.RGBToHex(int(255.0 * 0.8),int(255.0 * 0.6),int(255.0 * 0.4));
			var allSO:Vector.<SphericalObstacle>=Vector.<SphericalObstacle>(CtfBase.AllObstacles);
			for (var so:int=0; so < allSO.length; so++)
			{
				DrawCircle (Obstacles,allSO[so].Radius, Vector3.Zero, allSO[so].Center, color, 7, false,false );
			}
		}
	}
}