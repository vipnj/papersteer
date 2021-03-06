﻿// ----------------------------------------------------------------------------
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
package tabinda.demo.plugins.MapDrive
{
	import flash.filters.ColorMatrixFilter;
	import flash.ui.Keyboard;
	
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.Papervision3D;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	public class MapDrivePlugIn extends PlugIn
	{		
		private var vehicle:MapDriver;
		private var vehicles:Vector.<MapDriver>;// for allVehicles

		private var initCamDist:Number,initCamElev:Number;

		private var usePathFences:Boolean;
		private var useRandomRocks:Boolean;
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var SandMesh:TriangleMesh3D;
		public var lines:Lines3D;
		public var colMat:ColorMaterial;
		
		public var ForceRedraw:Boolean;
		
		public function MapDrivePlugIn ()
		{
			vehicles = new Vector.<MapDriver>();
			super();
		}
		
		public function initPV3D():void
		{
			colMat = new ColorMaterial(0x000000, 1);

			lines = new Lines3D(new LineMaterial(0x000000, 1));
			SandMesh = new TriangleMesh3D(colMat, new Array(), new Array());

			Demo.container.addChild(SandMesh);
			Demo.container.addChild(lines);
		}

		public override  function get Name ():String
		{
			return "Driving through map based obstacles";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.07;
		}

		public override  function Open ():void
		{
			initPV3D();
			
			ForceRedraw = true;
			
			// make new MapDriver
			vehicle=new MapDriver();
			vehicles.push (vehicle);
			
			addPV3DObject(vehicle.VehicleMesh);
			addPV3DObject(vehicle.lines);
			addPV3DObject(vehicle.MapMesh);
			addPV3DObject(vehicle.PathMesh);
			
			Demo.SelectedVehicle=vehicle;

			// marks as obstacles map cells adjacent to the path
			usePathFences=true;

			// scatter random rock clumps over map
			useRandomRocks=true;

			// init Demo camera
			initCamDist=30.0;
			initCamElev=15.0;
			Demo.Init2dCamera (vehicle,initCamDist,initCamElev);
			// "look straight down at vehicle" camera mode parameters
			Demo.camera.LookDownDistance=50.0;
			// "static" camera mode parameters
			Demo.camera.FixedPosition=new Vector3(145,145,145);
			Demo.camera.FixedTarget.x=40;
			Demo.camera.FixedTarget.y=0;
			Demo.camera.FixedTarget.z=40;
			Demo.camera.FixedUp=Vector3.Up;

			// reset this plugin
			Reset ();
		}


		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update simulation of test vehicle
			vehicle.Update (currentTime,elapsedTime);

			// when vehicle drives outside the world
			if (vehicle.HandleExitFromMap())
			{
				RegenerateMap ();
			}

			// QQQ first pass at detecting "stuck" state
			if (vehicle.stuck && (vehicle.RelativeSpeed() < 0.001))
			{
				vehicle.stuckCount++;
				Reset ();
			}
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// update camera, tracking test vehicle
			Demo.UpdateCamera (currentTime,elapsedTime,vehicle);

			// We do  this because PV3D and AS3 are not Canvas based Drawers
			if(ForceRedraw)
			{
				SandMesh.geometry.faces = [];
				SandMesh.geometry.vertices = [];
			
				// draw "ground plane"  (make it 4x map size)
				var s:Number=MapDriver.worldSize * 2;
				var u:Number=-0.2;

				var vertA:Vertex3D = new Vertex3D( +s, u, +s);
				var vertB:Vertex3D = new Vertex3D( +s, u, -s);
				var vertC:Vertex3D = new Vertex3D( -s, u, -s);
				var vertD:Vertex3D = new Vertex3D( -s, u, +s);
				
				SandMesh.geometry.vertices.push(vertA, vertB, vertC, vertD);
				
				var color2:uint = Colors.RGBToHex((255.0 * 0.8), int(255.0 * 0.7), int(255.0 * 0.5));
				colMat.fillColor = color2;
				colMat.doubleSided = true;
				
				var t1:Triangle3D = new Triangle3D(SandMesh, [vertA, vertB, vertC], colMat);
				var t2:Triangle3D = new Triangle3D(SandMesh, [vertD, vertA, vertC], colMat);
				
				SandMesh.geometry.faces.push(t1);
				SandMesh.geometry.faces.push(t2);
				
				SandMesh.geometry.ready = true;
				
				vehicle.DrawMap ();
				
				// draw map and path
				if (MapDriver.demoSelect == 2)
				{
					vehicle.DrawPath ();
				}
				ForceRedraw = false;
			}
			
			lines.geometry.faces = [];
			lines.geometry.vertices = [];
			lines.removeAllLines();
				
			// draw test vehicle
			vehicle.Draw ();

			// QQQ mark origin to help spot artifacts
			var tick:Number=2;
			//Drawing.DrawLine (new Vector3(tick,0,0),new Vector3(- tick,0,0),Colors.Green);
			//Drawing.DrawLine (new Vector3(0,0,tick),new Vector3(0,0,- tick),Colors.Green);
			DrawLine (new Vector3(tick,0,0),new Vector3(- tick,0,0),Colors.Green);
			DrawLine (new Vector3(0,0,tick),new Vector3(0,0,- tick),Colors.Green);

			// compute conversion factor miles-per-hour to meters-per-second
			var metersPerMile:Number=1609.344;
			var secondsPerHour:Number=3600;
			var MPSperMPH:Number=metersPerMile / secondsPerHour;

			// display status in the upper left corner of the window
			var status:String = new String();
			status +="Speed: "+ int(vehicle.Speed) + "mps ("+int(vehicle.Speed / MPSperMPH)+ "mph), average: "+vehicle.totalDistance / vehicle.totalTime +"mps\n\n";
			status +="collisions avoided for "+int(Demo.clock.TotalSimulationTime - vehicle.timeOfLastCollision)+" seconds";
			if (vehicle.countOfCollisionFreeTimes > 0)
			{
				status +="\nmean time between collisions: "+int(vehicle.sumOfCollisionFreeTimes / vehicle.countOfCollisionFreeTimes)+"("+int(vehicle.sumOfCollisionFreeTimes)+"/"+int(vehicle.countOfCollisionFreeTimes);
			}
			
			status +="\n\nStuck count: " + vehicle.stuckCount + "(" + vehicle.stuckCycleCount + " cycles, " + vehicle.stuckOffPathCount + " off path)";
			status +="\n\n[F1] ";
			
			if (1 == MapDriver.demoSelect)
			{
				status +="wander, ";
			}
			if (2 == MapDriver.demoSelect)
			{
				status +="follow path, ";
			}
			status +="avoid obstacle";
			
			if (2 == MapDriver.demoSelect)
			{
				status +="\n[F2] path following direction: ";
				if (vehicle.pathFollowDirection > 0)
				{
					status +="+1";
				}
				else
				{
					status +="-1";
				}
				status +="\n[F3] path fence: ";
				
				if (usePathFences)
				{
					status +="on";
				}
				else
				{
					status +="off";
				}
			}
			
			status +="\n[F4] rocks: ";
			if (useRandomRocks)
			{
				status +="on";
			}
			else
			{
				status +="off";
			}
			
			status +="\n[F5] prediction: ";
			if (vehicle.curvedSteering)
			{
				status +="curved";
			}
			else
			{
				status +="linear";
			}
			if (2 == MapDriver.demoSelect)
			{
				status +="\n\nLap " + vehicle.lapsStarted + " (completed: " + ((vehicle.lapsStarted < 2) ? 0 : int((100 * (Number(vehicle.lapsFinished)) / Number(vehicle.lapsStarted - 1)))) + "%";
				status +="\nHints given: "+vehicle.hintGivenCount+", taken: "+vehicle.hintTakenCount;
			}
			
			status +="\n";
			qqqRange("WR ", MapDriver.savedNearestWR, status);
			qqqRange("R  ", MapDriver.savedNearestR, status);
			qqqRange("L  ", MapDriver.savedNearestL, status);
			qqqRange("WL ", MapDriver.savedNearestWL, status);
			
			var screenLocation:Vector3=new Vector3(15,50,0);
			var color:Vector3 = new Vector3(0.15, 0.15, 0.5);
			
			//Drawing.Draw2dTextAt2dLocation (status,screenLocation,Colors.toHex(0.15,0.15,0.5));
			Demo.Draw2dTextAt2dLocation (status, screenLocation, Colors.AntiqueWhite);
			{
				var v:Number=Demo.WindowHeight - 5.0;
				var m:Number=10.0;
				var w:Number = Demo.WindowWidth;
				var f:Number=w - 2.0 * m;
				var s2:Number=vehicle.RelativeSpeed();

				// limit tick mark
				var l:Number=vehicle.annoteMaxRelSpeed;
				//Drawing.Draw2dLine (new Vector3(m + f * l,v - 3,0),new Vector3(m + f * l,v + 3,0),Colors.Black);
				DrawLine (new Vector3(m + f * l,v - 3,0),new Vector3(m + f * l,v + 3,0),Colors.Black);
				// two "inverse speedometers" showing limits due to curvature and
				// path alignment
				if (l != 0)
				{
					var c:Number=vehicle.annoteMaxRelSpeedCurve;
					var p:Number=vehicle.annoteMaxRelSpeedPath;
					//Drawing.Draw2dLine (new Vector3(m + f * c,v + 1,0),new Vector3(w - m,v + 1,0),Colors.Red);
					//Drawing.Draw2dLine (new Vector3(m + f * p, v - 2, 0), new Vector3(w - m, v - 1, 0), Colors.Green);
					DrawLine (new Vector3(m + f * c,v + 1,0),new Vector3(w - m,v + 1,0),Colors.Red);
					DrawLine (new Vector3(m + f * p,v - 2,0),new Vector3(w - m,v - 1,0),Colors.Green);
				}
				// speedometer: horizontal line with length proportional to speed
				//Drawing.Draw2dLine (new Vector3(m,v,0),new Vector3(m + f * s,v,0),Colors.White);
				DrawLine (new Vector3(m,v,0),new Vector3(m + f * s,v,0),Colors.White);
				// min and max tick marks
				//Drawing.Draw2dLine (new Vector3(m,v,0),new Vector3(m,v - 2,0),Colors.White);
				//Drawing.Draw2dLine (new Vector3(w - m, v, 0), new Vector3(w - m, v - 2, 0), Colors.White);
				DrawLine (new Vector3(m,v,0),new Vector3(m,v - 2,0),Colors.White);
				DrawLine (new Vector3(w - m,v,0),new Vector3(w - m,v - 2,0),Colors.White);
			}
		}
		
		public function DrawLine(startPoint:Vector3,endPoint:Vector3,color:uint):void
		{
			lines.addLine(new Line3D(lines, new LineMaterial(color,1),1,new Vertex3D(startPoint.x,startPoint.y,startPoint.z),new Vertex3D(endPoint.x,endPoint.y,endPoint.z)));
		}

		private function qqqRange (text:String,range:Number,status:String):void
		{
			status.concat ("\n"+text);
			if (range == 9999.0)
			{
				status.concat ("--");
			}
			else
			{
				status.concat (int(range));
			}
		}

		public override  function Close ():void
		{
			//TODO: Remove scene object once the plugin closes
			destoryPV3DObject(SandMesh);
			destoryPV3DObject(lines);
			
			destoryPV3DObject(vehicle.VehicleMesh);
			destoryPV3DObject(vehicle.MapMesh);
			destoryPV3DObject(vehicle.PathMesh);
			destoryPV3DObject(vehicle.lines);
			vehicle.removeTrail();

			vehicles.splice(0,vehicles.length);
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
			RegenerateMap ();

			// reset vehicle
			vehicle.Reset ();

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove ();

			// reset camera position
			Demo.Position2dCamera (vehicle, initCamDist, initCamElev);
			
			ForceRedraw = true;
		}

		public override  function HandleFunctionKeys (key:uint):void
		{
			switch (key)
			{
				case Keyboard.F1:
					SelectNextDemo ();
					break;
				case Keyboard.F2 :
					ReversePathFollowDirection ();
					break;
				case Keyboard.F3 :
					TogglePathFences ();
					break;
				case Keyboard.F4 :
					ToggleRandomRocks ();
					break;
				case Keyboard.F5 :
					ToggleCurvedSteering ();
					break;

				case Keyboard.F6 :// QQQ draw an enclosed "pen" of obstacles to test cycle-stuck
						var m:Number=MapDriver.worldSize * 0.4;// main diamond size
						var n:Number=MapDriver.worldSize / 8.0;// notch size
						var q:Vector3=new Vector3(0,0,m - n);
						var s:Vector3=new Vector3(2 * n,0,0);
						var c:Vector3=Vector3.VectorSubtraction(s , q);
						var d:Vector3=Vector3.VectorAddition(s , q);
						var pathPointCount:int=2;
						var pathRadii:Vector.<Number> = new Vector.<Number>();
						pathRadii[0] = 10;
						pathRadii[1] = 10;
						var pathPoints:Vector.<Vector3> = new Vector.<Vector3>();
						pathPoints[0] = c;
						pathPoints[1] = d;
						var r:GCRoute=new GCRoute(pathPointCount,pathPoints,pathRadii,false);
						DrawPathFencesOnMap (vehicle.map,r);
						break;
			}
		}

		public override  function PrintMiniHelpForFunctionKeys ():void
		{    
			var message:String;
			message = "Function keys handled by " + '"' + Name + '"' + ':';
			Demo.printMessage (message);
			Demo.printMessage ("  F1     select next driving demo.");
			Demo.printMessage ("  F2     reverse path following direction.");
			Demo.printMessage ("  F3     toggle path fences.");
			Demo.printMessage ("  F4     toggle random rock clumps.");
			Demo.printMessage ("  F5     toggle curved prediction.");
			Demo.printMessage ("");
		}

		private function ReversePathFollowDirection ():void
		{
			vehicle.pathFollowDirection = (vehicle.pathFollowDirection > 0)? -1: +1;
		}

		private function TogglePathFences ():void
		{
			usePathFences=! usePathFences;
			Reset ();
		}

		private function ToggleRandomRocks ():void
		{
			useRandomRocks=! useRandomRocks;
			Reset ();
		}

		private function ToggleCurvedSteering ():void
		{
			vehicle.curvedSteering=! vehicle.curvedSteering;
			vehicle.incrementalSteering=! vehicle.incrementalSteering;
			Reset ();
		}

		private function SelectNextDemo ():void
		{
			var message:String = new String();
			message +=Name+": ";
			if (++MapDriver.demoSelect > 2)
			{
				MapDriver.demoSelect=0;
			}
			switch (MapDriver.demoSelect)
			{
				case 0 :
					message +="obstacle avoidance and speed control";
					Reset ();
					break;
				case 1 :
					message +="wander, obstacle avoidance and speed control";
					Reset ();
					break;
				case 2 :
					message+="path following, obstacle avoidance and speed control";
					Reset ();
					break;
			}
			ForceRedraw = true;
			Demo.printMessage (message);
		}
		
		private function RegenerateMap ():void
		{
			// regenerate map: clear and add random "rocks"
			vehicle.map.Clear ();
			DrawRandomClumpsOfRocksOnMap (vehicle.map);
			ClearCenterOfMap (vehicle.map);

			// draw fences for first two demo modes
			if (MapDriver.demoSelect < 2)
			{
				DrawBoundaryFencesOnMap (vehicle.map);
			}

			// randomize path widths
			if (MapDriver.demoSelect == 2)
			{
				var count:int=vehicle.path.pointCount;
				var upstream:Boolean=vehicle.pathFollowDirection > 0;
				var entryIndex:int = upstream?1:count - 1;
				var exitIndex:int = upstream?count - 1:1;
				var lastExitRadius:Number=vehicle.path.radii[exitIndex];
				for (var i:int=1; i < count; i++)
				{
					vehicle.path.radii[i]=Utilities.random(4,19);
				}
				vehicle.path.radii[entryIndex]=lastExitRadius;
			}

			// mark path-boundary map cells as obstacles
			// (when in path following demo and appropriate mode is set)
			if (usePathFences && (MapDriver.demoSelect == 2))
			{
				DrawPathFencesOnMap (vehicle.map,vehicle.path);
			}
		}

		private function DrawRandomClumpsOfRocksOnMap (map:TerrainMap):void
		{
			if (useRandomRocks)
			{
				var spread:int=4;
				var r:int=map.Cellwidth();
				var k:int=Utilities.random(50,150);

				for (var p:int=0; p < k; p++)
				{
					var i:int=Utilities.random(0,r - spread);
					var j:int=Utilities.random(0,r - spread);
					var c:int=Utilities.random(0,10);

					for (var q:int=0; q < c; q++)
					{
						var m:int=Utilities.random(0,spread);
						var n:int=Utilities.random(0,spread);
						map.SetMapBit (i + m,j + n,true);
					}
				}
			}
		}


		private function DrawBoundaryFencesOnMap (map:TerrainMap):void
		{
			// QQQ it would make more sense to do this with a "draw line
			// QQQ on map" primitive, may need that for other things too

			var cw:int=map.Cellwidth();
			var ch:int=map.Cellheight();

			var r:int=cw - 1;
			var a:int=cw >> 3;
			var b:int=cw - a;
			var o:int=cw >> 4;
			var p:int=(cw - o) >> 1;
			var q:int=(cw + o) >> 1;

			for (var i:int=0; i < cw; i++)
			{
				for (var j:int=0; j < ch; j++)
				{
					var c:Boolean=(i > a && i < b) && (i < p || i > q);
					if (i == 0 || j == 0 || i == r || j == r || (c && (i == j || i + j == r)))
					{
						map.SetMapBit (i,j,true);
					}
				}
			}
		}

		private function ClearCenterOfMap (map:TerrainMap):void
		{
			var o:int=map.Cellwidth() >> 4;
			var p:int=(map.Cellwidth() - o) >> 1;
			var q:int=(map.Cellwidth() + o) >> 1;
			for (var i:int=p; i <= q; i++)
			{
				for (var j:int=p; j <= q; j++)
				{
					map.SetMapBit (i,j,false);
				}
			}

		}
		private function DrawPathFencesOnMap (map:TerrainMap,path:GCRoute):void
		{
			var xs:Number=map.xSize / Number(map.resolution);
			var zs:Number=map.zSize / Number(map.resolution);
			var alongRow:Vector3=new Vector3(xs,0,0);
			var nextRow:Vector3=new Vector3(- map.xSize,0,zs);
			var g:Vector3=new Vector3((map.xSize - xs) / -2,0,(map.zSize - zs) / -2);
			for (var j:int=0; j < map.resolution; j++)
			{
				for (var i:int=0; i < map.resolution; i++)
				{
					var outside:Number=path.HowFarOutsidePath(g);
					var wallThickness:Number=1.0;

					// set map cells adjacent to the outside edge of the path
					if ((outside > 0) && (outside < wallThickness))
					{
						map.SetMapBit (i,j,true);
					}

					// clear all other off-path map cells 
					if (outside > wallThickness)
					{
						map.SetMapBit (i,j,false);
					}

					g = Vector3.VectorAddition(g,alongRow);
				}
				g= Vector3.VectorAddition(g,nextRow);
			}
		}

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var all:Vector.<IVehicle> = Vector.<IVehicle>(vehicles);
			return all;
		}
	}
}