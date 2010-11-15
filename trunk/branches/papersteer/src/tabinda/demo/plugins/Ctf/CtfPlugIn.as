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
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var obstacleGeometry:Lines3D;
		public var highlightGeometry:Lines3D;
		public var colMat:ColorMaterial;
		
		public var count:int = 0;
		
		public var pluginReset:Boolean;
		
		public function CtfPlugIn ()
		{			
			initPV3D();
			
			pluginReset = true;
			
			super ();
			all=new Vector.<CtfBase>();
		}
		
		public function initPV3D():void
		{
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			colMat.interactive = false;
			
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			obstacleGeometry = new Lines3D(new LineMaterial(0x000000, 1));
			highlightGeometry= new Lines3D(new LineMaterial(0x000000, 1));
			
			Demo.container.addChild(obstacleGeometry);
			Demo.container.addChild(highlightGeometry);
			Demo.container.addChild(GridMesh);
		}

		public override  function get Name ():String
		{
			return "Capture the Flag";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.01;
		}

		public override  function Open ():void
		{
			// create the seeker ("hero"/"attacker")
			Globals.ctfSeeker=new CtfSeeker();
			all.push (Globals.ctfSeeker);
			
			Demo.container.addChild(Globals.ctfSeeker.objectMesh);
			Demo.container.addChild(Globals.ctfSeeker.lines);

			// create the specified number of enemies, 
			// storing pointers to them in an array.
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i]=new CtfEnemy();
				all.push (Globals.CtfEnemies[i]);
				Demo.container.addChild(Globals.CtfEnemies[i].objectMesh);
				Demo.container.addChild(Globals.CtfEnemies[i].lines);
			}

			// initialize camera
			Demo.Init2dCamera (Globals.ctfSeeker);
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
			Globals.ctfSeeker.Update (currentTime,elapsedTime);
			// update each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i].Update (currentTime,elapsedTime);
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
			goalDirection.fNormalize();
			var cameraForward:Vector3=Demo.camera.xxxls().Forward;
			var goalDot:Number=cameraForward.DotProduct(goalDirection);
			var blend:Number=Utilities.RemapIntervalClip(goalDot,1,0,0.5,0);
			var gridCenter:Vector3=Utilities.Interpolate2(blend,selected.Position,Globals.HomeBaseCenter);
			
			// draw the seeker, obstacles and home base
			Globals.ctfSeeker.Draw ();
		
			highlightGeometry.geometry.faces = [];
			highlightGeometry.geometry.vertices = [];
			highlightGeometry.removeAllLines();
				
			// We do  this because PV3D and AS3 are not Canvas based Drawers
			if(pluginReset)
			{
				obstacleGeometry.geometry.faces = [];
				obstacleGeometry.geometry.vertices = [];
				obstacleGeometry.removeAllLines();
				
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
				//Demo.GridUtility(gridCenter,GridMesh);
				Grid(gridCenter);
			
				// Should be drawn once per restart or obstacle insertion/removal, PV3D is clumsy on constant Redrawing
				DrawObstacles ();
				
				// Should be drawn once per restart, PV3D is clumsy on constant Redrawing
				DrawHomeBase ();
				
				pluginReset = false;
			}
			
			// draw each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i].Draw ();
			}

			// highlight vehicle nearest mouse
			//Demo.HighlightVehicleUtility (nearMouse);
			HighlightVehicleUtility (nearMouse);
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
											 Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
										     Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.LightGray
			var gray2:uint = Colors.DarkGray;
			
			var size:int = 500;
			var subsquares:int = 50;
			
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			var flag1:Boolean = false;
			var p:Number = -half;
			var corner:Vector3 = new Vector3();
			
			count = 0;
			
			for (var i:int = 0; i < subsquares; i++)
			{
				var flag2:Boolean = flag1;
				var q:Number = -half;
				for (var j:int = 0; j < subsquares; j++)
				{
					corner.x = p;
					corner.y = -1;
					corner.z = q;

					corner = Vector3.VectorAddition(corner, center);
					
					var vertA:Vertex3D = corner.ToVertex3D();
					var vertB:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, 0)).ToVertex3D();
					var vertC:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, spacing)).ToVertex3D();
					var vertD:Vertex3D = Vector3.VectorAddition(corner, new Vector3(0, 0, spacing)).ToVertex3D();
					
					GridMesh.geometry.vertices.push(vertA, vertB,vertC, vertD);
					
					var color:uint = flag2 ? gray1 : gray2;
					var t1:Triangle3D = new Triangle3D(GridMesh, [vertA,vertB,vertC], new ColorMaterial(color, 1));
					var t2:Triangle3D = new Triangle3D(GridMesh, [vertD,vertA,vertC], new ColorMaterial(color, 1));
			
					GridMesh.geometry.faces.push(t1);
					GridMesh.geometry.faces.push(t2);
					
					flag2 = !flag2;
					q += spacing;
				}
				flag1 = !flag1;
				p += spacing;
			}
			if (Papervision3D.useRIGHTHANDED)
			{
				GridMesh.geometry.flipFaces();
			}
			GridMesh.geometry.ready = true;
		}
		
		public function HighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				DrawCircleOrDisk(highlightGeometry,vehicle.Radius, Vector3.Zero, vehicle.Position, Colors.LightGray, 20, true, false );
			}
		}

		public override  function Close ():void
		{
			// delete seeker
			destoryPV3DObject(Globals.ctfSeeker.objectMesh);
			destoryPV3DObject(Globals.ctfSeeker.lines);
			
			Globals.ctfSeeker = null;
			
			//Remove PV3D Grid and Lines Mesh
			destoryPV3DObject(GridMesh);
			destoryPV3DObject(obstacleGeometry);
			destoryPV3DObject(highlightGeometry);

			// delete each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				destoryPV3DObject(Globals.CtfEnemies[i].objectMesh);
				destoryPV3DObject(Globals.CtfEnemies[i].lines);
				
				Globals.CtfEnemies[i] = null;
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

		public override  function Reset ():void
		{
			// count resets
			Globals.ResetCount++;

			// reset the seeker ("hero"/"attacker") and enemies
			Globals.ctfSeeker.Reset ();
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i].Reset ();
			}

			// reset camera position
			Demo.Position2dCamera (Globals.ctfSeeker);

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove ();
			
			pluginReset = true;
		}

		public override  function HandleFunctionKeys (key:uint):void
		{
			switch (key)
			{
				case Keyboard.F1:
					CtfBase.AddOneObstacle ();
					pluginReset = true;
					break;
				case Keyboard.F2:
					CtfBase.RemoveOneObstacle ();
					pluginReset = true;
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

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(all);
			return vehicles;
		}
		
		private function DrawCircleOrDisk(lines:Lines3D,radius:Number, axis:Vector3,center:Vector3, color:uint, segments:int,filled:Boolean,in3d:Boolean):void
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

				tempcurve.x = radius/Math.cos(curveangle * Number3D.toRADIANS);
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
					var line:Line3D = new Line3D(lines, new LineMaterial(color), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					lines.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(lines,radius, axis, center, color, segments, filled, in3d);
			}
		}

		public function DrawHomeBase ():void
		{
			var up:Vector3=new Vector3(0,0.01,0);
			var atColor:uint=Colors.toHex(int(255.0 * 0.3),int(255.0 * 0.3),int(255.0 * 0.5));
			var noColor:uint=Colors.Gray;
			var reached:Boolean=Globals.ctfSeeker.State == SeekerState.AtGoal;
			var baseColor:uint=reached?atColor:noColor;
			
			DrawCircleOrDisk (obstacleGeometry,Globals.HomeBaseRadius,Vector3.Zero,Globals.HomeBaseCenter,baseColor,40,true,false);
			DrawCircleOrDisk (obstacleGeometry,Globals.HomeBaseRadius / 15,Vector3.Zero,Vector3.VectorAddition(Globals.HomeBaseCenter , up),Colors.Black,20,true,false);
		}

		public function DrawObstacles ():void
		{
			var color:uint=Colors.toHex(int(255.0 * 0.8),int(255.0 * 0.6),int(255.0 * 0.4));
			var allSO:Vector.<SphericalObstacle>=Vector.<SphericalObstacle>(CtfBase.AllObstacles);
			for (var so:int=0; so < allSO.length; so++)
			{
				DrawCircleOrDisk (obstacleGeometry,allSO[so].Radius, Vector3.Zero, allSO[so].Center, color, 40, false,false );
			}
		}
	}
}