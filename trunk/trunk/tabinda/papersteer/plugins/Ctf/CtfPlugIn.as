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

package tabinda.papersteer.plugins.Ctf
{
	import tabinda.papersteer.*;
	//using SOG = List<SphericalObstacle>;  // spherical obstacle group

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
		public function CtfPlugIn ()
		{
			super ();
			all=new Array();
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
			Globals.CtfSeeker=new CtfSeeker  ;
			all.Add (Globals.CtfSeeker);

			// create the specified number of enemies, 
			// storing pointers to them in an array.
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i]=new CtfEnemy();
				all.push (Globals.CtfEnemies[i]);
			}

			// initialize camera
			Demo.Init2dCamera (Globals.CtfSeeker);
			Demo.Camera.Mode=Camera.CameraMode.FixedDistanceOffset;
			Demo.Camera.FixedTarget=Vector3D.Zero;
			Demo.Camera.FixedTarget.x=15;
			Demo.Camera.FixedPosition.x=80;
			Demo.Camera.FixedPosition.y=60;
			Demo.Camera.FixedPosition.z=0;

			CtfBase.InitializeObstacles ();
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update the seeker
			Globals.CtfSeeker.Update (currentTime,elapsedTime);

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
			var nearMouse:IVehicle=null;//FIXME: Demo.vehicleNearestToMouse ();

			// update camera
			Demo.UpdateCamera (currentTime,elapsedTime,selected);

			// draw "ground plane" centered between base and selected vehicle
			var goalOffset:Vector3D=Vector3D.VectorSubtraction(Globals.HomeBaseCenter , Demo.Camera.Position);
			var goalDirection:Vector3D=goalOffset;
			goalDirection.fNormalize();
			var cameraForward:Vector3D=Demo.Camera.xxxls().Forward;
			var goalDot:Number=Vector3D.Dot(cameraForward,goalDirection);
			var blend:Number=Utilities.RemapIntervalClip(goalDot,1,0,0.5,0);
			var gridCenter:Vector3D=Utilities.Interpolate2(blend,selected.Position,Globals.HomeBaseCenter);
			Demo.GridUtility (gridCenter);

			// draw the seeker, obstacles and home base
			Globals.CtfSeeker.Draw ();
			DrawObstacles ();
			DrawHomeBase ();

			// draw each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i].Draw ();
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
		}

		public override  function Close ():void
		{
			// delete seeker
			Globals.CtfSeeker=null;

			// delete each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i]=null;
			}

			// clear the group of all vehicles
			all.splice(0);
		}

		public override  function Reset ():void
		{
			// count resets
			Globals.ResetCount++;

			// reset the seeker ("hero"/"attacker") and enemies
			Globals.CtfSeeker.Reset ();
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i].Reset ();
			}

			// reset camera position
			Demo.Position2dCamera (Globals.CtfSeeker);

			// make camera jump immediately to new position
			Demo.Camera.DoNotSmoothNextMove ();
		}

		public override  function HandleFunctionKeys (key:Keys):void
		{
			switch (key)
			{
				case key.isDown(Keyboard.F1):
					CtfBase.AddOneObstacle ();
					break;
				case key.isDown(Keyboard.F2):
					CtfBase.RemoveOneObstacle ();
					break;
			}
		}

		public override  function PrintMiniHelpForFunctionKeys ():void
		{
			COMPILE::TODO
			{
				var message:String = "Function keys handled by " + "\"" + name() + "\"" + ":";
				Demo.printMessage (message);
				Demo.printMessage ("  F1     add one obstacle.");
				Demo.printMessage ("  F2     remove one obstacle.");
				Demo.printMessage ("");
			}
		}

		public override  function get Vehicles ():Array
		{
			return all.map(function(CtfBase v) { return (IVehicle)v; });
		}

		public function DrawHomeBase ():void
		{
			var up:Vector3D=new Vector3D(0,0.01,0);
			var atColor:uint=Colors.toHex(int(255.0 * 0.3),int(255.0 * 0.3),int(255.0 * 0.5));
			var noColor:uint=Colors.DarkGray;
			var reached:Boolean=Globals.CtfSeeker.State == CtfSeeker.SeekerState.AtGoal;
			var baseColor:uint=reached?atColor:noColor;
			Drawing.DrawXZDisk (Globals.HomeBaseRadius,Globals.HomeBaseCenter,baseColor,40);
			Drawing.DrawXZDisk (Globals.HomeBaseRadius / 15,Globals.HomeBaseCenter + up,Colors.Black,20);
		}

		public function DrawObstacles ():void
		{
			var color:uint=Colors.toHex(int(255.0 * 0.8),int(255.0 * 0.6),int(255.0 * 0.4));
			var allSO:Array=CtfBase.AllObstacles;
			for (var so:int=0; so < allSO.length; so++)
			{
				Drawing.DrawXZCircle (allSO[so].Radius,allSO[so].Center,color,40);
			}
		}

		// a group (STL vector) of all vehicles in the PlugIn
		var all:Array;
	}
}