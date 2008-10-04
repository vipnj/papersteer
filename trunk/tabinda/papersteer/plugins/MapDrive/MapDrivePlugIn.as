// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// Copyright (C) 2007 Michael Coles <michael@digini.com>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/*using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework;*/

package tabinda.papersteer.plugins.MapDrive
{
	public class MapDrivePlugIn extends PlugIn
	{
		public function MapDrivePlugIn ()
		{
			super ();
			vehicles=new Array  ;
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
			// make new MapDriver
			vehicle=new MapDriver  ;
			vehicles.Add (vehicle);
			Demo.SelectedVehicle=vehicle;

			// marks as obstacles map cells adjacent to the path
			usePathFences=true;

			// scatter random rock clumps over map
			useRandomRocks=true;

			// init Demo camera
			initCamDist=30;
			initCamElev=15;
			Demo.Init2dCamera (vehicle,initCamDist,initCamElev);
			// "look straight down at vehicle" camera mode parameters
			Demo.Camera.LookDownDistance=50;
			// "static" camera mode parameters
			Demo.Camera.FixedPosition=new Vector3(145);
			Demo.Camera.FixedTarget.X=40;
			Demo.Camera.FixedTarget.Y=0;
			Demo.Camera.FixedTarget.Z=40;
			Demo.Camera.FixedUp=Vector3.Up;

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
			if (vehicle.stuck && vehicle.RelativeSpeed() < 0.001)
			{
				vehicle.stuckCount++;
				Reset ();
			}
		}


		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// update camera, tracking test vehicle
			Demo.UpdateCamera (currentTime,elapsedTime,vehicle);

			// draw "ground plane"  (make it 4x map size)
			var s:Number=MapDriver.worldSize * 2;
			var u:Number=-0.2;
			Drawing.DrawQuadrangle (new Vector3(+ s,u,+ s),new Vector3(+ s,u,- s),new Vector3(- s,u,- s),new Vector3(- s,u,+ s),new Color(int(255.0 * 0.8),int(255.0 * 0.7),int(255.0 * 0.5)));// "sand"

			// draw map and path
			if (MapDriver.demoSelect == 2)
			{
				vehicle.DrawPath ();
			}
			vehicle.DrawMap ();

			// draw test vehicle
			vehicle.Draw ();

			// QQQ mark origin to help spot artifacts
			var tick:Number=2;
			Drawing.DrawLine (new Vector3(tick,0,0),new Vector3(- tick,0,0),Color.Green);
			Drawing.DrawLine (new Vector3(0,0,tick),new Vector3(0,0,- tick),Color.Green);

			// compute conversion factor miles-per-hour to meters-per-second
			var metersPerMile:Number=1609.344;
			var secondsPerHour:Number=3600;
			var MPSperMPH:Number=metersPerMile / secondsPerHour;

			// display status in the upper left corner of the window
			/*StringBuilder status = new StringBuilder();
			status.AppendFormat("Speed: {0} mps ({1} mph), average: {2:0.0} mps\n\n",
			   (int)vehicle.Speed,
			   (int)(vehicle.Speed / MPSperMPH),
			   vehicle.totalDistance / vehicle.totalTime);
			status.AppendFormat("collisions avoided for {0} seconds",
			   (int)(Demo.Clock.TotalSimulationTime - vehicle.timeOfLastCollision));
			if (vehicle.countOfCollisionFreeTimes > 0)
			{
			status.AppendFormat("\nmean time between collisions: {0} ({1}/{2})",
			   (int)(vehicle.sumOfCollisionFreeTimes / vehicle.countOfCollisionFreeTimes),
			   (int)vehicle.sumOfCollisionFreeTimes,
			   (int)vehicle.countOfCollisionFreeTimes);
			}
			
			status.AppendFormat("\n\nStuck count: {0} ({1} cycles, {2} off path)",
			vehicle.stuckCount,
			vehicle.stuckCycleCount,
			vehicle.stuckOffPathCount);
			status.Append("\n\n[F1] ");
			if (1 == MapDriver.demoSelect) status.Append("wander, ");
			if (2 == MapDriver.demoSelect) status.Append("follow path, ");
			status.Append("avoid obstacle");
			
			if (2 == MapDriver.demoSelect)
			{
			status.Append("\n[F2] path following direction: ");
			if (vehicle.pathFollowDirection > 0)
			status.Append("+1");
			else
			status.Append("-1");
			status.Append("\n[F3] path fence: ");
			if (usePathFences)
			status.Append("on");
			else
			status.Append("off");
			}
			
			status.Append("\n[F4] rocks: ");
			if (useRandomRocks)
			status.Append("on");
			else
			status.Append("off");
			status.Append("\n[F5] prediction: ");
			if (vehicle.curvedSteering)
			status.Append("curved");
			else
			status.Append("linear");
			if (2 == MapDriver.demoSelect)
			{
			status.AppendFormat("\n\nLap {0} (completed: {1}%)",
			vehicle.lapsStarted,
			   ((vehicle.lapsStarted < 2) ? 0 :
			   (int)(100 * ((float)vehicle.lapsFinished /
			 (float)(vehicle.lapsStarted - 1))))
			   );
			
			status.AppendFormat("\nHints given: {0}, taken: {1}",
			vehicle.hintGivenCount,
			vehicle.hintTakenCount);
			}
			status.Append("\n");
			qqqRange("WR ", MapDriver.savedNearestWR, status);
			qqqRange("R  ", MapDriver.savedNearestR, status);
			qqqRange("L  ", MapDriver.savedNearestL, status);
			qqqRange("WL ", MapDriver.savedNearestWL, status);*/
			var screenLocation:Vector3=new Vector3(15,50,0);
			var color:Vector3=new Vector3(0.15,0.15,0.5);
			Drawing.Draw2dTextAt2dLocation (status.ToString(),screenLocation,new Color(color));

			{
				var v:Number=Drawing.GetWindowHeight() - 5;
				var m:Number=10;
				var w:Number=Drawing.GetWindowWidth();
				var f:Number=w - 2 * m;
				var s2:Number=vehicle.RelativeSpeed();

				// limit tick mark
				var l:Number=vehicle.annoteMaxRelSpeed;
				Drawing.Draw2dLine (new Vector3(m + f * l,v - 3,0),new Vector3(m + f * l,v + 3,0),Color.Black);
				// two "inverse speedometers" showing limits due to curvature and
				// path alignment
				if (l != 0)
				{
					var c:Number=vehicle.annoteMaxRelSpeedCurve;
					var p:Number=vehicle.annoteMaxRelSpeedPath;
					Drawing.Draw2dLine (new Vector3(m + f * c,v + 1,0),new Vector3(w - m,v + 1,0),Color.Red);
					Drawing.Draw2dLine (new Vector3(m + f * p,v - 2,0),new Vector3(w - m,v - 1,0),Color.Green);
				}
				// speedometer: horizontal line with length proportional to speed
				Drawing.Draw2dLine (new Vector3(m,v,0),new Vector3(m + f * s,v,0),Color.White);
				// min and max tick marks
				Drawing.Draw2dLine (new Vector3(m,v,0),new Vector3(m,v - 2,0),Color.White);
				Drawing.Draw2dLine (new Vector3(w - m,v,0),new Vector3(w - m,v - 2,0),Color.White);
			}
		};

		function qqqRange (text:String,range:Number,status:StringBuilder):void
		{
			status.AppendFormat ("\n{0}",text);
			if (range == 9999.0)
			{
				status.Append ("--");
			}
			else
			{
				status.Append (int(range));
			}
		}

		public override  function Close ():void
		{
			vehicles.Clear ();
		}

		public override  function Reset ():void
		{
			RegenerateMap ();

			// reset vehicle
			vehicle.Reset ();

			// make camera jump immediately to new position
			Demo.Camera.DoNotSmoothNextMove ();

			// reset camera position
			Demo.Position2dCamera (vehicle,initCamDist,initCamElev);
		}

		public override  function HandleFunctionKeys (key:Keys):void
		{
			switch (key)
			{
				case Keys.F1 :
					SelectNextDemo ();
					break;
				case Keys.F2 :
					ReversePathFollowDirection ();
					break;
				case Keys.F3 :
					TogglePathFences ();
					break;
				case Keys.F4 :
					ToggleRandomRocks ();
					break;
				case Keys.F5 :
					ToggleCurvedSteering ();
					break;

				case Keys.F6 :// QQQ draw an enclosed "pen" of obstacles to test cycle-stuck
					{
						var m:Number=MapDriver.worldSize * 0.4;// main diamond size
						var n:Number=MapDriver.worldSize / 8;// notch size
						var q:Vector3=new Vector3(0,0,m - n);
						var s:Vector3=new Vector3(2 * n,0,0);
						var c:Vector3=s - q;
						var d:Vector3=s + q;
						var pathPointCount:int=2;
						var pathRadii:Array=new Array(10,10);
						var pathPoints=new Array(c,d);
						var r:GCRoute=new GCRoute(pathPointCount,pathPoints,pathRadii,false);
						DrawPathFencesOnMap (vehicle.map,r);
						break;

				}
			}
		};

		public override  function PrintMiniHelpForFunctionKeys ():void
		{
			/*#if TODO
			        std.ostringstream message;
			        message << "Function keys handled by ";
			        message << '"' << name() << '"' << ':' << std.ends;
			        Demo.printMessage (message);
			        Demo.printMessage ("  F1     select next driving demo.");
			        Demo.printMessage ("  F2     reverse path following direction.");
			        Demo.printMessage ("  F3     toggle path fences.");
			        Demo.printMessage ("  F4     toggle random rock clumps.");
			        Demo.printMessage ("  F5     toggle curved prediction.");
			        Demo.printMessage ("");
			#endif*/
		}

		function ReversePathFollowDirection ():void
		{
			vehicle.pathFollowDirection=vehicle.pathFollowDirection > 0?-1:+1;
		}

		function TogglePathFences ():void
		{
			usePathFences=! usePathFences;
			Reset ();
		}

		function ToggleRandomRocks ():void
		{
			useRandomRocks=! useRandomRocks;
			Reset ();
		}

		function ToggleCurvedSteering ():void
		{
			vehicle.curvedSteering=! vehicle.curvedSteering;
			vehicle.incrementalSteering=! vehicle.incrementalSteering;
			Reset ();
		}

		function SelectNextDemo ():void
		{
			var message:StringBuilder=new StringBuilder  ;
			message.AppendFormat ("{0}: ",Name);
			if (++MapDriver.demoSelect > 2)
			{
				MapDriver.demoSelect=0;
			}
			switch (MapDriver.demoSelect)
			{
				case 0 :
					message.Append ("obstacle avoidance and speed control");
					Reset ();
					break;
				case 1 :
					message.Append ("wander, obstacle avoidance and speed control");
					Reset ();
					break;
				case 2 :
					message.Append ("path following, obstacle avoidance and speed control");
					Reset ();
					break;
			}
			//FIXME: Demo.printMessage (message);
		}

		// random utility, worth moving to Utilities.h?
		function Random2 (min:int,max:int):int
		{
			return int(Utilities.Random(Number(min),Number(max)));
		}

		function RegenerateMap ():void
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
				var entryIndex:int=upstream?1:count - 1;
				var exitIndex:int=upstream?count - 1:1;
				var lastExitRadius:Number=vehicle.path.radii[exitIndex];
				for (var i:int=1; i < count; i++)
				{
					vehicle.path.radii[i]=Utilities.Random(4,19);
				}
				vehicle.path.radii[entryIndex]=lastExitRadius;
			}

			// mark path-boundary map cells as obstacles
			// (when in path following demo and appropriate mode is set)
			if (usePathFences && MapDriver.demoSelect == 2)
			{
				DrawPathFencesOnMap (vehicle.map,vehicle.path);
			}
		}

		function DrawRandomClumpsOfRocksOnMap (map:TerrainMap):void
		{
			if (useRandomRocks)
			{
				var spread:int=4;
				var r:int=map.Cellwidth();
				var k:int=Random2(50,150);

				for (var p:int=0; p < k; p++)
				{
					var i:int=Random2(0,r - spread);
					var j:int=Random2(0,r - spread);
					var c:int=Random2(0,10);

					for (var q:int=0; q < c; q++)
					{
						var m:int=Random2(0,spread);
						var n:int=Random2(0,spread);
						map.SetMapBit (i + m,j + n,true);
					}
				}
			}
		}


		function DrawBoundaryFencesOnMap (map:TerrainMap):void
		{
			// QQQ it would make more sense to do this with a "draw line
			// QQQ on map" primitive, may need that for other things too

			var cw:int=map.Cellwidth();
			var ch:int=map.Cellheight();

			var r:int=cw - 1;
			var a:int=cw >> 3;
			var b:int=cw - a;
			var o:int=cw >> 4;
			var p:int=cw - o >> 1;
			var q:int=cw + o >> 1;

			for (var i:int=0; i < cw; i++)
			{
				for (var j:int=0; j < ch; j++)
				{
					var c:Boolean=i > a && i < b && i < p || i > q;
					if (i == 0 || j == 0 || i == r || j == r || c && i == j || i + j == r)
					{
						map.SetMapBit (i,j,true);
					}
				}
			}
		}

		function ClearCenterOfMap (map:TerrainMap):void
		{
			var o:int=map.Cellwidth() >> 4;
			var p:int=map.Cellwidth() - o >> 1;
			var q:int=map.Cellwidth() + o >> 1;
			for (var i:int=p; i <= q; i++)
			{
				for (var j:int=p; j <= q; j++)
				{
					map.SetMapBit (i,j,false);
				}
			}

		}
		function DrawPathFencesOnMap (map:TerrainMap,path:GCRoute):void
		{
			var xs:Number=map.xSize / Number(map.resolution);
			var zs:Number=map.zSize / Number(map.resolution);
			var alongRow:Vector3=new Vector3(xs,0,0);
			var nextRow:Vector3=new Vector3(- map.xSize,0,zs);
			var g:Vector3=new Vector3(map.xSize - xs / -2,0,map.zSize - zs / -2);
			for (var j:int=0; j < map.resolution; j++)
			{
				for (var i:int=0; i < map.resolution; i++)
				{
					var outside:Number=path.HowFarOutsidePath(g);
					var wallThickness:Number=1.0;

					// set map cells adjacent to the outside edge of the path
					if (outside > 0 && outside < wallThickness)
					{
						map.SetMapBit (i,j,true);
					}

					// clear all other off-path map cells 
					if (outside > wallThickness)
					{
						map.SetMapBit (i,j,false);
					}

					g+= alongRow;
				}
				g+= nextRow;
			}
		}

		public override  function get Vehicles ():Array
		{
			//get { return vehicles.ConvertAll<IVehicle>(delegate(MapDriver v) { return (IVehicle)v; }); }
		}

		var vehicle:MapDriver;
		var vehicles:Array;// for allVehicles

		var initCamDist:Number,initCamElev:Number;

		var usePathFences:Boolean;
		var useRandomRocks:Boolean;
	}
}