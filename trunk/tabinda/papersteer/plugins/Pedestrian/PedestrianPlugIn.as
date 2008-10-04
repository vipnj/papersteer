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

package tabinda.papersteer.plugins.Pedestrian
{
	//using ProximityDatabase = IProximityDatabase<IVehicle>;
	//using ProximityToken = ITokenForProximityDatabase<IVehicle>;

	public class PedestrianPlugIn extends PlugIn
	{
		public function PedestrianPlugIn()
		{
			super();
			crowd = new Array();
		}

		public override function get Name():String { return "Pedestrians"; }

		public override function get SelectionOrderSortKey():Number { return 0.02;  }

		public override function Open():void
		{
			// make the database used to accelerate proximity queries
			cyclePD = -1;
			NextPD();

			// create the specified number of Pedestrians
			population = 0;
			for (var i:int = 0; i < 100; i++) AddPedestrianToCrowd();

			// initialize camera and selectedVehicle
			var firstPedestrian:Pedestrian = crowd[0];
			Demo.Init3dCamera(firstPedestrian);
			Demo.Camera.Mode = Camera.CameraMode.FixedDistanceOffset;

			Demo.Camera.FixedTarget.X = 15;
            Demo.Camera.FixedTarget.Y = 0;
            Demo.Camera.FixedTarget.Z = 30;

			Demo.Camera.FixedPosition.X = 15;
            Demo.Camera.FixedPosition.Y = 70;
            Demo.Camera.FixedPosition.Z = -70;
		}

		public override function Update(currentTime:Number, elapsedTime:Number):void
		{
			// update each Pedestrian
			for (var i:int = 0; i < crowd.Count; i++)
			{
				crowd[i].Update(currentTime, elapsedTime);
			}
		}

		public override function Redraw(currentTime:Number, elapsedTime:Number):void
		{
			// selected Pedestrian (user can mouse click to select another)
			var selected:IVehicle = Demo.SelectedVehicle;

			// Pedestrian nearest mouse (to be highlighted)
			var nearMouse:IVehicle = Demo.VehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera(currentTime, elapsedTime, selected);

			// draw "ground plane"
			if (Demo.SelectedVehicle != null) gridCenter = selected.Position;
			Demo.GridUtility(gridCenter);

			// draw and annotate each Pedestrian
			for (var i:int = 0; i < crowd.Count; i++) crowd[i].Draw();

			// draw the path they follow and obstacles they avoid
			DrawPathAndObstacles();

			// highlight Pedestrian nearest mouse
			Demo.HighlightVehicleUtility(nearMouse);

			// textual annotation (at the vehicle's screen position)
			SerialNumberAnnotationUtility(selected, nearMouse);

			// textual annotation for selected Pedestrian
			if (Demo.SelectedVehicle != null)//FIXME: && annotation.IsEnabled)
			{
				var color:Color = new Color(int(255.0 * 0.8), int(255.0 * 0.8), int(255.0 * 1.0));
				var textOffset:Vector3 = new Vector3(0, 0.25, 0);
				var textPosition:Vector3 = selected.Position + textOffset;
				var camPosition:Vector3 = Demo.Camera.Position;
				var camDistance:Number = Vector3.Distance(selected.Position, camPosition);

				var sb:StringBuilder = new StringBuilder();
				sb.AppendFormat("1: speed: {0:0.00}\n", selected.Speed);
				sb.AppendFormat("2: cam dist: {0:0.0}\n", camDistance);
				Drawing.Draw2dTextAt3dLocation(sb.ToString(), textPosition, color);
			}

			// display status in the upper left corner of the window
			var status:StringBuilder = new StringBuilder();
			status.AppendFormat("[F1/F2] Crowd size: {0}\n", population);
			status.Append("[F3] PD type: ");
			switch (cyclePD)
			{
			case 0: status.Append("LQ bin lattice"); break;
			case 1: status.Append("brute force"); break;
			}
			status.Append("\n[F4] ");
			if (Globals.UseDirectedPathFollowing)
				status.Append("Directed path following.");
			else
				status.Append("Stay on the path.");
			status.Append("\n[F5] Wander: ");
			if (Globals.WanderSwitch) status.Append("yes");
			else status.Append("no");
			status.Append("\n");
			var screenLocation:Vector3 = new Vector3(15, 50, 0);
			Drawing.Draw2dTextAt2dLocation(status.ToString(), screenLocation, Color.LightGray);
		}

		public function SerialNumberAnnotationUtility(selected:IVehicle, nearMouse:IVehicle):void
		{
			// display a Pedestrian's serial number as a text label near its
			// screen position when it is near the selected vehicle or mouse.
			if (selected != null)//FIXME: && IsAnnotationEnabled)
			{
				for (var i:int = 0; i < crowd.Count; i++)
				{
					var vehicle:IVehicle = crowd[i];
					const nearDistance:Number = 6;
					var vp:Vector3 = vehicle.Position;
					//Vector3 np = nearMouse.Position;
					if ((Vector3.Distance(vp, selected.Position) < nearDistance)/* ||
						(nearMouse != null && (Vector3.Distance(vp, np) < nearDistance))*/)
					{
						//var sn:String = String.Format("#{0}", (Pedestrian(vehicle).SerialNumber);
						var textColor:Color = new Color(int(255.0 * 0.8), int(255.0 * 1), int(255.0 * 0.8));
						var textOffset:Vector3 = new Vector3(0, 0.25, 0);
						var textPos:Vector3 = vehicle.Position + textOffset;
						Drawing.Draw2dTextAt3dLocation(sn, textPos, textColor);
					}
				}
			}
		}

		public function DrawPathAndObstacles():void
		{
			// draw a line along each segment of path
			var path:PolylinePathway = Globals.GetTestPath();
			for (var i:int = 0; i < path.pointCount; i++)
				if (i > 0) Drawing.DrawLine(path.points[i], path.points[i - 1], Color.Red);

			// draw obstacles
			Drawing.DrawXZCircle(Globals.Obstacle1.Radius, Globals.Obstacle1.Center, Color.White, 40);
			Drawing.DrawXZCircle(Globals.Obstacle2.Radius, Globals.Obstacle2.Center, Color.White, 40);
		}

		public override function Close():void
		{
			// delete all Pedestrians
			while (population > 0) RemovePedestrianFromCrowd();
		}

		public override function Reset():void
		{
			// reset each Pedestrian
			for (var i:int = 0; i < crowd.Count; i++) crowd[i].Reset();

			// reset camera position
			Demo.Position2dCamera(Demo.SelectedVehicle);

			// make camera jump immediately to new position
			Demo.Camera.DoNotSmoothNextMove();
		}

		public override function HandleFunctionKeys(key:Keys):void
		{
			switch (key)
			{
			case Keys.F1: AddPedestrianToCrowd(); break;
			case Keys.F2: RemovePedestrianFromCrowd(); break;
			case Keys.F3: NextPD(); break;
			case Keys.F4: Globals.UseDirectedPathFollowing = !Globals.UseDirectedPathFollowing; break;
			case Keys.F5: Globals.WanderSwitch = !Globals.WanderSwitch; break;
			}
		}

		public override function PrintMiniHelpForFunctionKeys():void
		{
/*#if TODO
			std::ostringstream message;
			message << "Function keys handled by ";
			message << '"' << name() << '"' << ':' << std::ends;
			Demo.printMessage (message);
			Demo.printMessage (message);
			Demo.printMessage ("  F1     add a pedestrian to the crowd.");
			Demo.printMessage ("  F2     remove a pedestrian from crowd.");
			Demo.printMessage ("  F3     use next proximity database.");
			Demo.printMessage ("  F4     toggle directed path follow.");
			Demo.printMessage ("  F5     toggle wander component on/off.");
			Demo.printMessage ("");
#endif*/
		}

		function AddPedestrianToCrowd():void
		{
			population++;
			var pedestrian:Pedestrian = new Pedestrian(pd);
			crowd.Add(pedestrian);
			if (population == 1) Demo.SelectedVehicle = pedestrian;
		}

		function RemovePedestrianFromCrowd():void
		{
			if (population > 0)
			{
				// save pointer to last pedestrian, then remove it from the crowd
				population--;
				var pedestrian:Pedestrian = crowd[population];
				crowd.RemoveAt(population);

				// if it is OpenSteerDemo's selected vehicle, unselect it
				if (pedestrian == Demo.SelectedVehicle)
					Demo.SelectedVehicle = null;

				// delete the Pedestrian
				pedestrian = null;
			}
		}

		// for purposes of demonstration, allow cycling through various
		// types of proximity databases.  this routine is called when the
		// OpenSteerDemo user pushes a function key.
		function NextPD():void
		{
			// save pointer to old PD
			var oldPD:ProximityDatabase = pd;

			// allocate new PD
			const totalPD:int = 2;
			switch (cyclePD = (cyclePD + 1) % totalPD)
			{
			case 0:
				{
					var center:Vector3 = Vector3.Zero;
					var div:Number = 20.0;
					var divisions:Vector3 = new Vector3(div, 1.0, div);
					var diameter:Number = 80.0; //XXX need better way to get this
					var dimensions:Vector3 = new Vector3(diameter, diameter, diameter);
					pd = new LocalityQueryProximityDatabase<IVehicle>(center, dimensions, divisions);
					break;
				}
			case 1:
				{
					pd = new BruteForceProximityDatabase();
					break;
				}
			}

			// switch each boid to new PD
			for (var i:int = 0; i < crowd.Count; i++) crowd[i].NewPD(pd);

			// delete old PD (if any)
			oldPD = null;
		}

		public override function get Vehicles():Array
		{
			//get { return crowd.ConvertAll<IVehicle>(delegate(Pedestrian p) { return (IVehicle)p; }); }
		}

		// crowd: a group (STL vector) of all Pedestrians
		var crowd:Array;

		var gridCenter:Vector3;

		// pointer to database used to accelerate proximity queries
		var pd:ProximityDatabase;

		// keep track of current flock size
		var population:int;

		// which of the various proximity databases is currently in use
		var cyclePD:int;
	}
}
