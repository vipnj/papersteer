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

package tabinda.papersteer.plugins.Pedester
{
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	import flash.ui.Keyboard;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;

	public class PedestrianPlugIn extends PlugIn
	{
		// crowd: a group (STL vector) of all Pedestrians
		var crowd:Vector.<Pedestrian>;

		var gridCenter:Vector3;

		// pointer to database used to accelerate proximity queries
		var pd:IProximityDatabase;

		// keep track of current flock size
		var population:int;

		// which of the various proximity databases is currently in use
		var cyclePD:int;
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr1:Array;
		public var uvArr2:Array;
		
		public function PedestrianPlugIn()
		{
			uvArr1 = new Array(new NumberUV(0, 0), new NumberUV(1, 1), new NumberUV(0, 1));
			uvArr2 = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(1, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(GridMesh);
			
			super();
			crowd = new Vector.<Pedestrian>();
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
			for (var i:int = 0; i < 100; i++)
			{
				AddPedestrianToCrowd();
			}

			// initialize camera and selectedVehicle
			var firstPedestrian:Pedestrian = crowd[0];
			Demo.Init3dCamera(firstPedestrian);
			Demo.camera.Mode = CameraMode.FixedDistanceOffset;
			Demo.camera.FixedTarget.x = 15;
            Demo.camera.FixedTarget.y = 0;
            Demo.camera.FixedTarget.z = 30;
			Demo.camera.FixedPosition.x = 15;
            Demo.camera.FixedPosition.y = 70;
            Demo.camera.FixedPosition.z = -70;
		}

		public override function Update(currentTime:Number, elapsedTime:Number):void
		{
			// update each Pedestrian
			for (var i:int = 0; i < crowd.length; i++)
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
			Demo.GridUtility(gridCenter,GridMesh,uvArr1,uvArr2);

			// draw and annotate each Pedestrian
			for (var i:int = 0; i < crowd.length; i++) crowd[i].Draw();

			// draw the path they follow and obstacles they avoid
			DrawPathAndObstacles();

			// highlight Pedestrian nearest mouse
			Demo.HighlightVehicleUtility(nearMouse);

			// textual annotation (at the vehicle's screen position)
			SerialNumberAnnotationUtility(selected, nearMouse);

			// textual annotation for selected Pedestrian
			if (Demo.SelectedVehicle != null)//FIXME: && annotation.IsEnabled)
			{
				var color:uint = Colors.toHex(int(255.0 * 0.8), int(255.0 * 0.8), int(255.0 * 1.0));
				var textOffset:Vector3 = new Vector3(0, 0.25, 0);
				var textPosition:Vector3 = Vector3.VectorAddition(selected.Position , textOffset);
				var camPosition:Vector3 = Demo.camera.Position;
				var camDistance:Number = Vector3.Distance(selected.Position, camPosition);

				var sb:String = new String();
				sb +="1: speed: "+selected.Speed+"\n";
				sb +="2: cam dist: "+camDistance+"\n";
				Drawing.Draw2dTextAt3dLocation(sb, textPosition, color);
			}

			// display status in the upper left corner of the window
			var status:String = new String();
			status +="[F1/F2] Crowd size: "+population+"\n";
			status +="[F3] PD type: ";
			switch (cyclePD)
			{
				case 0: status +="LQ bin lattice"; break;
				case 1: status +="brute force"; break;
			}
			
			status +="\n[F4] ";
			if (Globals.UseDirectedPathFollowing)
			{
				status +="Directed path following.";
			}
			else
			{
				status +="Stay on the path.";
			}
			status +="\n[F5] Wander: ";
			if (Globals.WanderSwitch)
			{
				status +="yes";
			}
			else
			{
				status +="no";
			}
			status +="\n";
			var screenLocation:Vector3 = new Vector3(15, 50, 0);
			Drawing.Draw2dTextAt2dLocation(status, screenLocation, Colors.LightGray);
		}

		public function SerialNumberAnnotationUtility(selected:IVehicle, nearMouse:IVehicle):void
		{
			// display a Pedestrian's serial number as a text label near its
			// screen position when it is near the selected vehicle or mouse.
			if (selected != null)//FIXME: && IsAnnotationEnabled)
			{
				for (var i:int = 0; i < crowd.length; i++)
				{
					var vehicle:IVehicle = crowd[i];
					var nearDistance:Number = 6;
					var vp:Vector3 = vehicle.Position;
					//Vector3 np = nearMouse.Position;
					if ((Vector3.Distance(vp, selected.Position) < nearDistance)/* ||
						(nearMouse != null && (Vector3.Distance(vp, np) < nearDistance))*/)
					{
						var sn:String ="#"+ Pedestrian(vehicle).SerialNumber;
						var textColor:uint = Colors.toHex(int(255.0 * 0.8), int(255.0 * 1), int(255.0 * 0.8));
						var textOffset:Vector3 = new Vector3(0, 0.25, 0);
						var textPos:Vector3 = Vector3.VectorAddition(vehicle.Position , textOffset);
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
				if (i > 0) Drawing.DrawLine(path.points[i], path.points[i - 1], Colors.Red);

			// draw obstacles
			Drawing.DrawXZCircle(Globals.Obstacle1.Radius, Globals.Obstacle1.Center, Colors.White, 40);
			Drawing.DrawXZCircle(Globals.Obstacle2.Radius, Globals.Obstacle2.Center, Colors.White, 40);
		}

		public override function Close():void
		{
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);
			
			// delete all Pedestrians
			while (population > 0) RemovePedestrianFromCrowd();
		}

		public override function Reset():void
		{
			// reset each Pedestrian
			for (var i:int = 0; i < crowd.length; i++) crowd[i].Reset();

			// reset camera position
			Demo.Position2dCamera(Demo.SelectedVehicle);

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove();
		}

		public override function HandleFunctionKeys(key:uint):void
		{
			switch (key)
			{
			case Keyboard.F1: AddPedestrianToCrowd(); break;
			case Keyboard.F2: RemovePedestrianFromCrowd(); break;
			case Keyboard.F3: NextPD(); break;
			case Keyboard.F4: Globals.UseDirectedPathFollowing = !Globals.UseDirectedPathFollowing; break;
			case Keyboard.F5: Globals.WanderSwitch = !Globals.WanderSwitch; break;
			}
		}

		public override function PrintMiniHelpForFunctionKeys():void
		{
			var message:String;
			message = "Function keys handled by "+ Name +":";
			Demo.printMessage (message);
			Demo.printMessage (message);
			Demo.printMessage ("  F1     add a pedestrian to the crowd.");
			Demo.printMessage ("  F2     remove a pedestrian from crowd.");
			Demo.printMessage ("  F3     use next proximity database.");
			Demo.printMessage ("  F4     toggle directed path follow.");
			Demo.printMessage ("  F5     toggle wander component on/off.");
			Demo.printMessage ("");
		}

		function AddPedestrianToCrowd():void
		{
			population++;
			var pedestrian:Pedestrian = new Pedestrian(pd);
			crowd.push(pedestrian);
			if (population == 1)
			{
				Demo.SelectedVehicle = pedestrian;
			}
		}

		function RemovePedestrianFromCrowd():void
		{
			if (population > 0)
			{
				// save pointer to last pedestrian, then remove it from the crowd
				population--;
				var pedestrian:Pedestrian = crowd[population];
				crowd.splice(population,1);

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
			var oldPD:IProximityDatabase = pd;

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
					pd = new LQProximityDatabase(center, dimensions, divisions);
					break;
				}
			case 1:
				{
					pd = new BruteForceProximityDatabase();
					break;
				}
			}

			// switch each boid to new PD
			for (var i:int = 0; i < crowd.length; i++) crowd[i].NewPD(pd);

			// delete old PD (if any)
			oldPD = null;
		}

		public override function get Vehicles():Vector.<IVehicle>
		{
			return( crowd.map(function(p:Pedestrian):IVehicle { return IVehicle(p); } ));
		}
	}
}
