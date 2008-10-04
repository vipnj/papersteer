// ----------------------------------------------------------------------------
//
// OpenSteer - Action Script 3 Port
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

package tabinda.papersteer.plugins.Boids
{
	import flash.text.TextField;
	import tabinda.demo.Demo;
	import tabinda.papersteer.*;
	
	import flash.ui.Keyboard;
	/*using ProximityDatabase = IProximityDatabase<IVehicle>;
	using ProximityToken = ITokenForProximityDatabase<IVehicle>;
	using SOG = List<SphericalObstacle>;  // spherical obstacle group*/

	public class BoidsPlugIn extends PlugIn
	{
		public function BoidsPlugIn()
		{
			super();
			flock = new Array();
		}

		public override function get Name():String 
		{ return "Boids";}

		public override function get SelectionOrderSortKey():Number
		{
			return -0.03; 
		}

		public override function Open():void
		{
			// make the database used to accelerate proximity queries
			cyclePD = -1;
			NextPD();

			// make default-sized flock
			population = 0;
			for (var i:int = 0; i < 200; i++) AddBoidToFlock();

			// initialize camera
			Demo.Init3dCamera(Demo.SelectedVehicle);
			Demo.Camera.Mode = CameraMode.Fixed;
			/*Bnoerj.AI.Steering.Demo.Init3dCamera(Bnoerj.AI.Steering.Demo.SelectedVehicle);
			Bnoerj.AI.Steering.Demo.Camera.Mode = Camera.CameraMode.Fixed;
			Bnoerj.AI.Steering.Demo.Camera.FixedDistanceDistance = Bnoerj.AI.Steering.Demo.CameraTargetDistance;
			Bnoerj.AI.Steering.Demo.Camera.FixedDistanceVerticalOffset = 0;
			Bnoerj.AI.Steering.Demo.Camera.LookDownDistance = 20;
			Bnoerj.AI.Steering.Demo.Camera.AimLeadTime = 0.5f;
			Bnoerj.AI.Steering.Demo.Camera.PovOffset.X =0;
            Bnoerj.AI.Steering.Demo.Camera.PovOffset.Y = 0.5f;
            Bnoerj.AI.Steering.Demo.Camera.PovOffset.Z = -2;*/

			Boid.InitializeObstacles();
		}

		public override function Update(currentTime:Number, elapsedTime:Number):void
		{
			// update flock simulation for each boid
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].Update(currentTime, elapsedTime);
			}
		}

		public override function Redraw(currentTime:Number, elapsedTime:Number):void
		{
			// selected vehicle (user can mouse click to select another)
			var selected:IVehicle = Demo.SelectedVehicle;

			// vehicle nearest mouse (to be highlighted)
			var nearMouse:IVehicle = null;// Demo.vehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera(currentTime, elapsedTime, selected);

			DrawObstacles();

			// draw each boid in flock
			for (var i:int = 0; i < flock.length; i++) flock[i].Draw();

			// highlight vehicle nearest mouse
			Demo.DrawCircleHighlightOnVehicle(nearMouse, 1, Colors.LightGray);

			// highlight selected vehicle
			Demo.DrawCircleHighlightOnVehicle(selected, 1, Colors.DarkGray);

			// display status in the upper left corner of the window
			var status:TextField = new TextField();
			status.AppendFormat("[F1/F2] {0} boids", population);
			status.appendText("\n[F3]    PD type: ");
			switch (cyclePD)
			{
			case 0: status.appendText("LQ bin lattice"); break;
			case 1: status.appendText("brute force"); break;
			}
			status.appendText("\n[F4]    Boundary: ");
			switch (Boid.boundaryCondition)
			{
			case 0: status.appendText("steer back when outside"); break;
			case 1: status.appendText("wrap around (teleport)"); break;
			}*/
			var screenLocation:Vector3D = new Vector3D(15, 50, 0);
			Drawing.Draw2dTextAt2dLocation(status.text, screenLocation, Colors.LightGray);
		}

		public override function Close():void
		{
			// delete each member of the flock
			while (population > 0) RemoveBoidFromFlock();

			// delete the proximity database
			pd = null;
		}

		public override function Reset():void
		{
			// reset each boid in flock
			for (var i:int = 0; i < flock.length; i++) flock[i].Reset();

			// reset camera position
			Demo.Position3dCamera(Demo.SelectedVehicle);

			// make camera jump immediately to new position
			Demo.Camera.DoNotSmoothNextMove();
		}

		// for purposes of demonstration, allow cycling through various
		// types of proximity databases.  this routine is called when the
		// Demo user pushes a function key.
		public function NextPD():void
		{
			// save pointer to old PD
			var oldPD:IProximityDatabase = pd;

			// allocate new PD
			const totalPD:int = 2;
			switch (cyclePD = (cyclePD + 1) % totalPD)
			{
			case 0:
				{
					var center:Vector3D = Vector3D.Zero;
					const div:Number = 10.0;
					var divisions:Vector3D = new Vector3D(div, div, div);
					var diameter:Number = Boid.worldRadius * 1.1 * 2;
					var dimensions:Vector3D = new Vector3D(diameter, diameter, diameter);
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
			for (var i:int = 0; i < flock.length; i++) flock[i].NewPD(pd);

			// delete old PD (if any)
			oldPD = null;
		}

		public override function HandleFunctionKeys(key:Keys):void
		{
			switch (key)
			{
			case key.isDown(Keyboard.F1): AddBoidToFlock(); break;
			case key.isDown(Keyboard.F2): RemoveBoidFromFlock(); break;
			case key.isDown(Keyboard.F3): NextPD(); break;
			case key.isDown(Keyboard.F4): Boid.NextBoundaryCondition(); break;
			}
		}

		public override function PrintMiniHelpForFunctionKeys():void
		{
			COMPILE::IGNORED
			{
				var message:String = "Function keys handled by \n" + "\"" + name() + "\"" + ":";
				Demo.printMessage (message);
				Demo.printMessage ("  F1     add a boid to the flock.");
				Demo.printMessage ("  F2     remove a boid from the flock.");
				Demo.printMessage ("  F3     use next proximity database.");
				Demo.printMessage ("  F4     next flock boundary condition.");
				Demo.printMessage ("");
			}
		}

		public function AddBoidToFlock():void
		{
			population++;
			var boid:Boid = new Boid(pd);
			flock.push(boid);
			if (population == 1) Demo.SelectedVehicle = boid;
		}

		public function RemoveBoidFromFlock():void
		{
			if (population > 0)
			{
				// save a pointer to the last boid, then remove it from the flock
				population--;
				var boid:boid = flock[population];
				flock.splice(population,1);

				// if it is Demo's selected vehicle, unselect it
				if (boid == Demo.SelectedVehicle)
					Demo.SelectedVehicle = null;

				// delete the Boid
				boid = null;
			}
		}

		// return an AVGroup containing each boid of the flock
		public override function get Vehicles():IVehicle
		{
			return flock.map(function(Boid v) { return (IVehicle) v; } );
			//return flock.ConvertAll(delegate(Boid v) { return (IVehicle)v; });
		}

		// flock: a group (STL vector) of pointers to all boids
		public var flock:Array;

		// pointer to database used to accelerate proximity queries
		public var pd:IProximityDatabase;

		// keep track of current flock size
		public var population:int;

		// which of the various proximity databases is currently in use
		public var cyclePD:int;

		public function DrawObstacles():void
		{
			//Color color = new Color((byte)(255.0f * 0.8f), (byte)(255.0f * 0.6f), (byte)(255.0f * 0.4f));
			var allSO:Array = Boid.AllObstacles;
			for (var so:int = 0; so < allSO.length; so++)
			{
				//Drawing.DrawBasic3dSphere(allSO[so].Center, allSO[so].Radius, Color.Red);
				Drawing.Draw3dCircleOrDisk(allSO[so].Radius, allSO[so].Center, Vector3D.UnitY, Colors.Red, 10, true);
				Drawing.Draw3dCircleOrDisk(allSO[so].Radius, allSO[so].Center, Vector3D.UnitX, Colors.Red, 10, true);
				Drawing.Draw3dCircleOrDisk(allSO[so].Radius, allSO[so].Center, Vector3D.UnitZ, Colors.Red, 10, true);
			}
		}
	}
}
