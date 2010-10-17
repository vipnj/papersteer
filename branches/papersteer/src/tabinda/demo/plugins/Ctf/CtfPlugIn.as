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
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
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
		// a group (STL vector) of all vehicles in the PlugIn
		private var all:Vector.<CtfBase>;
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		
		public function CtfPlugIn ()
		{
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(GridMesh);
			
			super ();
			all=new Vector.<CtfBase>();
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
			Demo.scene.addChild(Globals.ctfSeeker.CtfMesh);

			// create the specified number of enemies, 
			// storing pointers to them in an array.
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Globals.CtfEnemies[i]=new CtfEnemy();
				all.push (Globals.CtfEnemies[i]);
				Demo.scene.addChild(Globals.CtfEnemies[i].CtfMesh);
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
			var nearMouse:IVehicle=null;//FIXME: Demo.vehicleNearestToMouse ();

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
			
			GridMesh.geometry.faces = [];
			GridMesh.geometry.vertices = [];
			Demo.GridUtility(gridCenter,GridMesh);

			// draw the seeker, obstacles and home base
			Globals.ctfSeeker.Draw ();
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
			Demo.scene.removeChild(Globals.ctfSeeker.CtfMesh);
			Globals.ctfSeeker = null;
			

			// delete each enemy
			for (var i:int=0; i < Globals.CtfEnemyCount; i++)
			{
				Demo.scene.removeChild(Globals.CtfEnemies[i].CtfMesh);
				Globals.CtfEnemies[i] = null;
				
			}
			
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);

			// clear the group of all vehicles
			all.splice(0,all.length);
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
		}

		public override  function HandleFunctionKeys (key:uint):void
		{
			switch (key)
			{
				case Keyboard.F1:
					CtfBase.AddOneObstacle ();
					break;
				case Keyboard.F2:
					CtfBase.RemoveOneObstacle ();
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

		public function DrawHomeBase ():void
		{
			var up:Vector3=new Vector3(0,0.01,0);
			var atColor:uint=Colors.toHex(int(255.0 * 0.3),int(255.0 * 0.3),int(255.0 * 0.5));
			var noColor:uint=Colors.Gray;
			var reached:Boolean=Globals.ctfSeeker.State == SeekerState.AtGoal;
			var baseColor:uint=reached?atColor:noColor;
			Drawing.DrawXZDisk (Globals.HomeBaseRadius,Globals.HomeBaseCenter,baseColor,40);
			Drawing.DrawXZDisk (Globals.HomeBaseRadius / 15,Vector3.VectorAddition(Globals.HomeBaseCenter , up),Colors.Black,20);
		}

		public function DrawObstacles ():void
		{
			var color:uint=Colors.toHex(int(255.0 * 0.8),int(255.0 * 0.6),int(255.0 * 0.4));
			var allSO:Vector.<SphericalObstacle>=Vector.<SphericalObstacle>(CtfBase.AllObstacles);
			for (var so:int=0; so < allSO.length; so++)
			{
				Drawing.DrawXZCircle (allSO[so].Radius,allSO[so].Center,color,40);
			}
		}
	}
}