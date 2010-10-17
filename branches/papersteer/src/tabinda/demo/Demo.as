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

package tabinda.demo
{
	// Flash Imports
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.Timer;
	import flash.ui.Keyboard;
	import flash.text.TextField;
	import flash.system.System;
	
	
	// Papervision3D Imports
	import org.papervision3d.render.*;
	import org.papervision3d.scenes.*;
	import org.papervision3d.view.*;
	import org.papervision3d.events.*;
	import org.papervision3d.core.geom.TriangleMesh3D;
	
	// PaperSteer Imports
	import tabinda.papersteer.*;
	import tabinda.demo.plugins.Boids.*;
	import tabinda.demo.plugins.LowSpeedTurning.*;
	import tabinda.demo.plugins.Pedester.*;
	import tabinda.demo.plugins.Ctf.*;
	import tabinda.demo.plugins.MapDrive.*;
	import tabinda.demo.plugins.MultiplePursuit.*;
	import tabinda.demo.plugins.Soccer.*;
	import tabinda.demo.plugins.OneTurn.*;
	
	/**
	 * The Demo class is a big example that shows off multiple plugins that can be made with opensteer
	 * This port is entirely an exact port of the original OpenSteer Library and Demo. 
	 */
	public class Demo extends Sprite
	{
		// Used to get Display Window Width and Height
		private static var WindowWidth:int = 1024;
		private static var WindowHeight:int = 640;
		
		// Papervision3D essential vars
		public static var viewport:Viewport3D;
		public static var scene:Scene3D;
		public static var camera:PSCamera;
		public static var renderer:BasicRenderEngine;

		// All the plugins
		private var boids:BoidsPlugIn;
		private var lowSpeedTurn:LowSpeedTurnPlugIn;
		private var pedestrian:PedestrianPlugIn;
		private var ctf:CtfPlugIn;
		private var mapDrive:MapDrivePlugIn;
		private var multiplePursuit:MpPlugIn;
		private var soccer:SoccerPlugIn;
		private var oneTurning:OneTurningPlugIn;
		
		// Different Phases of Drawing
		private static var phase:int;
		private static var phaseStackSize:int = 5;
		private static var phaseStack:Array = new Array(phaseStackSize);
		private static var phaseStackIndex:int = 0;
		private static var phaseTimers:Array = new Array(Phase.Count);
		private static var phaseTimerBase:Number = 0.0;

		// Draw text showing (smoothed, rounded) "frames per second" rate
		// (and later a bunch of related stuff was dumped here, a reorg would be nice)
		private static var smoothedTimerDraw:Number = 0.0;
		private static var smoothedTimerUpdate:Number = 0.0;
		private static var smoothedTimerOverhead:Number = 0.0;

		// All the 2D text fields on the demo window showing different stats
		private var strField:TextField;				// Camera mode
		private var strField2:TextField;			// Current Plugin
		private var strField3:TextField;			// Update
		private var strField4:TextField;			// Draw
		private var strField5:TextField;			// Other
		private var strField6:TextField;			// Clock
		private var strCam:TextField;				// PV3D Camera Information
		private static var textEntry:TextField; 	// Plugin options
		private var strFormat:TextFormat;			// TextFormat Common for all Text
		
		// currently selected plug-in (user can choose or cycle through them)
		public static var SelectedPlugIn:PlugIn = null;

		// currently selected vehicle.  Generally the one the camera follows and
		// for which additional information may be displayed.  Clicking the mouse
		// near a vehicle causes it to become the Selected Vehicle.
		public static var SelectedVehicle:IVehicle = null;

		private var frameRatePresetIndex:int = 0;
		public static var clock:Clock = new Clock();
		private static var delayedResetPlugInXXX:Boolean = false;
		
		// some camera-related default constants
		public static const Camera2dElevation:Number = 8.0;
		public static const CameraTargetDistance:Number = 13.0;
		public static var CameraTargetOffset:Vector3 = new Vector3(0, Camera2dElevation, 0);

		public function Demo()
		{
			Drawing.demo = this;
			
			viewport=new Viewport3D(WindowWidth,WindowHeight,false,false);
			addChild(viewport);
		
			renderer = new BasicRenderEngine();
			scene = new Scene3D();
			camera = new PSCamera(viewport);
			
			scene.addChild(Drawing.lines);
			
			strField = new TextField();
			strField2 = new TextField();
			strField3 = new TextField();
			strField4 = new TextField();
			strField5 = new TextField();
			strField6 = new TextField();
			strCam = new TextField();
			textEntry = new TextField();
			strFormat = new TextFormat();
			addChild(strField);
			addChild(strField2);
			addChild(strField3);
			addChild(strField4);
			addChild(strField5);
			addChild(strField6);
			addChild(strCam);
			addChild(textEntry);

			//TODO: Fix here
			Annotation.drawer = new Drawing();

			boids = new BoidsPlugIn();
			lowSpeedTurn = new LowSpeedTurnPlugIn();
			pedestrian = new PedestrianPlugIn();
			ctf = new CtfPlugIn();
			mapDrive = new MapDrivePlugIn();
			multiplePursuit = new MpPlugIn();
			soccer = new SoccerPlugIn();
			oneTurning = new OneTurningPlugIn();

			init();
			renderer.renderScene(scene,camera.pv3dcamera,viewport);
		}
		
		/** Allows the game to perform any initialization it needs to before starting to run.
		* This is where it can query for any required services and load any non-graphic
		* related content.  Calling base.Initialize will enumerate through any components
		* and initialize them as well.
		*/
		public function init():void
		{
			// TODO: Any further initialization logic should rest here
           // stage.scaleMode = StageScaleMode.NO_SCALE;
            //stage.quality = StageQuality.LOW;
			
			SelectDefaultPlugIn();
			OpenSelectedPlugIn();
			
			Drawing.init();
			
			this.addEventListener(Event.ENTER_FRAME, Update);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeys);
		}
		
		/**
		 * Initiates a 2D Camera. Takes selected vehicle or elevation and distance in addition
		 * @param	...args vehicle:IVehicle, distance:Number, elevation:Number
		 */
		public static function Init2dCamera(...args):void
		{
			trace("Demo.Init2DCamera",args[0] is IVehicle, args[1] is Number, args[2] is Number);
			if(args.length == 1)
			{
				Position2dCamera(args[0], CameraTargetDistance, Camera2dElevation);
				camera.FixedDistanceDistance = CameraTargetDistance;
				camera.FixedDistanceVerticalOffset = Camera2dElevation;
				camera.Mode = CameraMode.FixedDistanceOffset;
			}
			else if(args.length == 3)
			{
				Position2dCamera(args[0], args[1], args[2]);
				camera.FixedDistanceDistance = args[1];
				camera.FixedDistanceVerticalOffset = args[2];
				camera.Mode = CameraMode.FixedDistanceOffset;
			}
		}

		/**
		 * Initiates a 3D Camera. Takes selected vehicle or elevation and distance in addition
		 * @param	...args vehicle:IVehicle, distance:Number, elevation:Number
		 */
		public static function Init3dCamera(...args):void
		{
			trace("Demo.Init3DCamera",args[0] is IVehicle, args[1] is Number, args[2] is Number);
			if(args.length == 1)
			{
				Position3dCamera(args[0], CameraTargetDistance, Camera2dElevation);
				camera.FixedDistanceDistance = CameraTargetDistance;
				camera.FixedDistanceVerticalOffset = Camera2dElevation;
				camera.Mode = CameraMode.FixedDistanceOffset;
			}
			if(args.length == 3)
			{
				Position3dCamera(args[0], args[1], args[2]);
				camera.FixedDistanceDistance = args[1];
				camera.FixedDistanceVerticalOffset = args[2];
				camera.Mode = CameraMode.FixedDistanceOffset;
			}
		}

		/**
		 * Positions the 2D Camera. Takes selected vehicle or elevation and distance in addition
		 * @param	...args vehicle:IVehicle, distance:Number, elevation:Number
		 */
		public static function Position2dCamera(...args):void
		{
			trace("Demo.Position2DCamera",args[0] is IVehicle, args[1] is Number, args[2] is Number);
			if(args.length == 1)
			{
				// position the camera as if in 3d:
				Position3dCamera(args[0], CameraTargetDistance, Camera2dElevation);

				// then adjust for 3d:
				var position3d:Vector3 = camera.Position;
				position3d.y += Camera2dElevation;
				camera.Position = (position3d);
			}
			else if(args.length == 3)
			{
				// position the camera as if in 3d:
				Position3dCamera(args[0], args[1], args[2]);

				// then adjust for 3d:
				position3d = camera.Position;
				position3d.y += args[2];
				camera.Position = (position3d);
			}
		}

		/**
		 * Positions the 3D Camera. Takes selected vehicle or elevation and distance in addition
		 * @param	...args vehicle:IVehicle, distance:Number, elevation:Number
		 */
		public static function Position3dCamera(...args):void
		{
			trace("Demo.Position3DCamera",args[0] is IVehicle, args[1] is Number, args[2] is Number);
			
			SelectedVehicle = args[0];
			
			if(args.length == 1)
			{
				if (args[0] != null)
				{
					var behind:Vector3 = Vector3.ScalarMultiplication(-args[1],args[0].Forward);
					camera.Position = Vector3.VectorAddition(args[0].Position , behind);
					camera.Target = args[0].Position;
				}
			}
			else if(args.length == 3)
			{
				if (args[0] != null)
				{
					behind = Vector3.ScalarMultiplication(-args[1],args[0].Forward);
					camera.Position = Vector3.VectorAddition(args[0].Position , behind);
					camera.Target = args[0].Position;
				}
			}
		}

		 
		/**
		 * Camera updating utility used by several (all?) plug-ins
		 * @param	currentTime
		 * @param	elapsedTime
		 * @param	selected
		 */
		public static function UpdateCamera(currentTime:Number,elapsedTime:Number, selected:IVehicle):void
		{
			camera.VehicleToTrack = selected;
			camera.Update(currentTime, elapsedTime, clock.PausedState);
		}

		/**
		 * Ground plane grid-drawing utility used by several plug-ins
		 * @param	gridTarget
		 */
		public static function GridUtility(gridTarget:Vector3,GridMesh:TriangleMesh3D):void
		{			
			// Math.Round off target to the nearest multiple of 2 (because the
			// checkboard grid with a pitch of 1 tiles with a period of 2)
			// then lower the grid a bit to put it under 2d annotation lines
			var gridCenter:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
								   Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
								   Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.toHex(new Vector3(0.27));
			var gray2:uint = Colors.toHex(new Vector3(0.30));

			// draw 50x50 checkerboard grid with 50 squares along each side
			Drawing.DrawXZCheckerboardGrid(GridMesh,5, 5, gridCenter, gray1, gray2);
		}

		/**
		 * Draws a gray disk on the XZ plane under a given vehicle
		 * @param	vehicle
		 */
		public static function HighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				Drawing.DrawXZDisk(vehicle.Radius, vehicle.Position, Colors.LightGray, 20);
			}
		}

		/**
		 * Draws a gray circle on the XZ plane under a given vehicle
		 * @param	vehicle
		 */
		public static function CircleHighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				Drawing.DrawXZCircle(vehicle.Radius * 1.1, vehicle.Position, Colors.LightGray, 20);
			}
		}

		/**
		 * Draw a box around a vehicle aligned with its local space
		 * xxx not used as of 11-20-02
		 * @param	v
		 * @param	color
		 */
		public static function DrawBoxHighlightOnVehicle(v:IVehicle, color:uint):void
		{
			if (v != null)
			{
				var diameter:Number = v.Radius * 2;
				var size:Vector3 = new Vector3(diameter, diameter, diameter);
				Drawing.DrawBoxOutline(v, size, color);
			}
		}

		/**
		 * Draws a colored circle (perpendicular to view axis) around the center
		 * of a given vehicle.  The circle's radius is the vehicle's radius times
		 * radiusMultiplier.
		 * @param	v is a Vehicle
		 * @param	radiusMultiplier is a Number
		 * @param	color is an unsigned integer representing a color
		 */
		public static function DrawCircleHighlightOnVehicle(v:IVehicle, radiusMultiplier:Number, color:uint):void
		{
			if (v != null)
			{
				var cPosition:Vector3 = camera.Position;
				Drawing.Draw3dCircle(
					v.Radius * radiusMultiplier,  // adjusted radius
					v.Position,                   // center
					Vector3.VectorSubtraction(v.Position , cPosition),       // view axis
					color,                        // drawing color
					20);                          // circle segments
			}
		}

		/**
		 * Find the AbstractVehicle whose screen position is nearest the current the
		 * mouse position.  Returns NULL if mouse is outside this window or if
		 * there are no AbstractVehicle.
		 * @return
		 */
		public static function VehicleNearestToMouse():IVehicle
		{
			return null;
		}
		
		/**
		 * Find the AbstractVehicle whose screen position is nearest the given window
		 * coordinates, typically the mouse position.  Returns NULL if there are no
		 * AbstractVehicles.
		 *
		 * This works by constructing a line in 3d space between the camera location
		 * and the "mouse point".  Then it measures the distance from that line to the
		 * centers of each AbstractVehicle.  It returns the AbstractVehicle whose
		 * distance is smallest.
		 *
		 * xxx Issues: Should the distanceFromLine test happen in "perspective space"
		 * xxx or in "screen space"?  Also: I think this would be happy to select a
		 * xxx vehicle BEHIND the camera location.
		 * @param	X
		 * @param	Y
		 * @return IVehicle
		 */
		internal static function findVehicleNearestScreenPosition(X:int, Y:int):IVehicle
		{
			// find the direction from the camera position to the given pixel
			var direction:Vector3 = DirectionFromCameraToScreenPosition(X, Y);

			// iterate over all vehicles to find the one whose center is nearest the
			// "eye-mouse" selection line
			var minDistance:Number = Number.MAX_VALUE;       // smallest distance found so far
			var nearest:IVehicle = null;   // vehicle whose distance is smallest
			var vehicles:Vector.<IVehicle> = AllVehiclesOfSelectedPlugIn();
			for each (var vehicle:IVehicle in vehicles)
			{
				// distance from this vehicle's center to the selection line:
				var d:Number = VHelper.DistanceFromLine(vehicle.Position, camera.Position, direction);

				// if this vehicle-to-line distance is the smallest so far,
				// store it and this vehicle in the selection registers.
				if (d < minDistance)
				{
					minDistance = d;
					nearest = vehicle;
				}
			}

			return nearest;
		}

		/**
		 * Return a normalized direction vector pointing from the camera towards a
		 * given point on the screen: the ray that would be traced for that pixel
		 * @param	x
		 * @param	y
		 * @return  an Up Vector for teh Camera
		 */
		private static function DirectionFromCameraToScreenPosition(x:int, y:int):Vector3
		{
			return Vector3.Up;
		}

		/**
		 * Select the "next" plug-in, cycling through "plug-in selection order"
		 */ 
		private static function SelectDefaultPlugIn():void
		{
			PlugIn.SortBySelectionOrder();
			SelectedPlugIn = PlugIn.FindDefault();
		}

		// 
		/**
		 * Open the currently selected plug-in
		 */
		private static function OpenSelectedPlugIn():void
		{
			camera.Reset();
			SelectedVehicle = null;
			SelectedPlugIn.Open();
		}

		private static function ResetSelectedPlugIn():void
		{
			SelectedPlugIn.Reset();
		}

		private static function CloseSelectedPlugIn():void
		{
			SelectedPlugIn.Close();
			SelectedVehicle = null;
		}

		/**
		 * Return a group (an STL vector of AbstractVehicle pointers) of all
		 * vehicles(/agents/characters) defined by the currently selected PlugIn
		 * @return
		 */
		private static function AllVehiclesOfSelectedPlugIn():Vector.<IVehicle>
		{
			return SelectedPlugIn.Vehicles;
		}

		/**
		 * Select the "next" vehicle: the one listed after the currently selected one
		 * in allVehiclesOfSelectedPlugIn
		 */ 
		private static function SelectNextVehicle():void
		{
			if (SelectedVehicle != null)
			{
				// get a container of all vehicles
				var all:Vector.<IVehicle> = AllVehiclesOfSelectedPlugIn();

				// find selected vehicle in container
				var i:int = all.indexOf(SelectedVehicle);
				if (i >= 0 && i < all.length)
				{
					if (i == all.length - 1)
					{
						// if we are at the end of the container, select the first vehicle
						SelectedVehicle = all[0];
					}
					else
					{
						// normally select the next vehicle in container
						SelectedVehicle = all[i + 1];
					}
				}
				else
				{
					// if the search failed, use NULL
					SelectedVehicle = null;
				}
			}
		}

		private function UpdateSelectedPlugIn(currentTime:Number, elapsedTime:Number):void
		{
			// switch to Update phase
			PushPhase(Phase.Update);

			// service queued reset request, if any
			DoDelayedResetPlugInXXX();

			// if no vehicle is selected, and some exist, select the first one
			if (SelectedVehicle == null)
			{
				var all:Vector.<IVehicle> = AllVehiclesOfSelectedPlugIn();
				if (all.length >= 0)
				{
					SelectedVehicle = all[0];
				}
			}

			// invoke selected PlugIn's Update method
			SelectedPlugIn.Update(currentTime, elapsedTime);

			// return to previous phase
			PopPhase();
		}
		
		public static function QueueDelayedResetPlugInXXX():void
		{
			delayedResetPlugInXXX = true;
		}

		private static function DoDelayedResetPlugInXXX():void
		{
			if (delayedResetPlugInXXX)
			{
				ResetSelectedPlugIn();
				delayedResetPlugInXXX = false;
			}
		}

		private function PushPhase(newPhase:int):void
		{
			// update timer for current (old) phase: add in time since last switch
			UpdatePhaseTimers();

			// save old phase
			phaseStack[phaseStackIndex++] = phase;

			// set new phase
			phase = newPhase;

			// check for stack overflow
			if (phaseStackIndex >= phaseStackSize)
			{
				throw new RangeError("phaseStack overflow");
			}
		}

		private function PopPhase():void
		{
			// update timer for current (old) phase: add in time since last switch
			UpdatePhaseTimers();

			// restore old phase
			phase = phaseStack[--phaseStackIndex];
		}

		/**
		 * Redraw graphics for the currently selected plug-in
		 * @param	currentTime
		 * @param	elapsedTime
		 */ 
		private function RedrawSelectedPlugIn(currentTime:Number, elapsedTime:Number):void
		{
			// switch to Draw phase
			PushPhase(Phase.Draw);

			// invoke selected PlugIn's Draw method
			SelectedPlugIn.Redraw(currentTime, elapsedTime);

			// draw any annotation queued up during selected PlugIn's Update method
			Drawing.AllDeferredLines();
			Drawing.AllDeferredCirclesOrDisks();

			// return to previous phase
			PopPhase();
		}

		/**
		 * Cycle through frame rate presets
		 */ 
		private function SelectNextPresetFrameRate():void
		{
			// note that the cases are listed in reverse order, and that 
			// the default is case 0 which causes the index to wrap around
			switch (++frameRatePresetIndex)
			{
			case 3:
				printMessage("running at 60 FPS");
				// animation mode at 60 fps
				clock.FixedFrameRate = 60;
				clock.AnimationMode = true;
				clock.VariableFrameRateMode = false;
				break;
			case 2:
				// real-time fixed frame rate mode at 60 fps
				printMessage("running at 60 FPS with no animation");
				clock.FixedFrameRate = 60;
				clock.AnimationMode = false;
				clock.VariableFrameRateMode = false;
				break;
			case 1:
				// real-time fixed frame rate mode at 24 fps
				printMessage("running at 24 FPS");
				clock.FixedFrameRate = 24;
				clock.AnimationMode = false;
				clock.VariableFrameRateMode = false;
				break;
			case 0:
			default:
				// real-time variable frame rate mode ("as fast as possible")
				printMessage("running as fast as possible");
				frameRatePresetIndex = 0;
				clock.FixedFrameRate = 0;
				clock.AnimationMode = false;
				clock.VariableFrameRateMode = true;
				break;
			}
		}

		public static function printMessage(str:String):void
		{
			trace("Demo.printMessage",str);
		}
		
		private function SelectNextPlugin():void
		{
			CloseSelectedPlugIn();
			SelectedPlugIn = SelectedPlugIn.Next();
			OpenSelectedPlugIn();
		}

		public function handleKeys(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case Keyboard.ESCAPE:		
					System.exit(0);
					break;
				case 82: //R
					ResetSelectedPlugIn();
					break;
				case 83: //S
					SelectNextVehicle();
					break;
				case 65: //A
					SteerLibrary.annotation.IsEnabled = !SteerLibrary.annotation.IsEnabled;
					break;
				case Keyboard.SPACE:
					clock.TogglePausedState();
					break;
				case 67: //C
					camera.SelectNextMode();
					break;
				case 70: //F
					SelectNextPresetFrameRate();
					break;
				case Keyboard.TAB:
					SelectNextPlugin();
					break;
				case Keyboard.F1:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F1);
					break;
				case Keyboard.F2:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F2);
					break;
				case Keyboard.F3:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F3);
					break;
				case Keyboard.F4:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F4);
					break;
				case Keyboard.F5:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F5);
					break;
				case Keyboard.F6:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F6);
					break;
				case Keyboard.F7:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F7);
					break;
				case Keyboard.F8:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F8);
					break;
				case Keyboard.F9:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F9);
					break;
				case Keyboard.F10:
					SelectedPlugIn.HandleFunctionKeys(Keyboard.F10);
					break;
			}
		}
		
		protected function Update(e:Event):void
		{
			// TODO: Add your update logic here
			// update global simulation clock
			clock.Update();

			//  start the phase timer (XXX to accurately measure "overhead" time this
			//  should be in displayFunc, or somehow account for time outside this
			//  routine)
			InitPhaseTimers();

			// run selected PlugIn (with simulation's current time and step size)
			UpdateSelectedPlugIn(clock.TotalSimulationTime, clock.ElapsedSimulationTime);

			var pos:Vector3 = camera.Position;
			var lookAt:Vector3 = camera.Target;
			var up:Vector3 = camera.Up;
			
			Drawing.lines.geometry.faces = [];
            Drawing.lines.geometry.vertices = [];
            Drawing.lines.removeAllLines();
			Draw();
		}

		/**
		 * A Render method called by the Update Method Event EnterFrame Listener
		 */
		protected function Draw():void
		{
			// redraw selected PlugIn (based on real time)
			RedrawSelectedPlugIn(clock.TotalRealTime, clock.ElapsedRealTime);

			// get smoothed phase timer information
			var ptd:Number = PhaseTimerDraw;
			var ptu:Number = PhaseTimerUpdate;
			var pto:Number = PhaseTimerOverhead;
			var smoothRate:Number = clock.SmoothingRate;
			smoothedTimerDraw = Utilities.BlendIntoAccumulator(smoothRate, ptd,  smoothedTimerDraw);
			smoothedTimerUpdate = Utilities.BlendIntoAccumulator(smoothRate, ptu,  smoothedTimerUpdate);
			smoothedTimerOverhead = Utilities.BlendIntoAccumulator(smoothRate, pto,  smoothedTimerOverhead)		
			
			// keep track of font metrics and start of next line
			var lh:Number = 15.0;
			var cw:Number = 8.0;
			
			var screenLocation:Point = new Point(lh, lh);
			
			strFormat.align = "left";
			strFormat.size=12;
			strFormat.color = Colors.White;
			strFormat.kerning = true;
			strFormat.font = "Arial";
			
			strCam.x = 700;
			strCam.y = 600;
			strCam.autoSize = TextFieldAutoSize.LEFT;
			strCam.alpha = 1.0;
			strCam.selectable = false;
			strCam.defaultTextFormat = strFormat;
			strCam.text = String("PV3D Camera Info:\nX: " + Math.round(camera.pv3dcamera.x) + " Y: " + Math.round(camera.pv3dcamera.y) + " Z: " + Math.round(camera.pv3dcamera.z)
								+" RotX: " + Math.round(camera.pv3dcamera.rotationX) + " RotY: " + Math.round(camera.pv3dcamera.rotationY) + " RotZ: " + Math.round(camera.pv3dcamera.rotationZ));
			
			strField.x = screenLocation.x;
			strField.y = screenLocation.y;
			strField.autoSize = TextFieldAutoSize.LEFT;
			strField.alpha = 1.0;
			strField.selectable = false;
			strField.defaultTextFormat = strFormat;
			strField.text = "Camera: " + camera.ModeName;
			
			screenLocation.y += lh;
			strField2.x = screenLocation.x;
			strField2.y = screenLocation.y;
			strField2.autoSize = TextFieldAutoSize.LEFT;
			strField2.alpha = 1.0;
			strField2.selectable = false;
			strField2.defaultTextFormat = strFormat;
			strField2.text = "PlugIn: "+ SelectedPlugIn.Name;
			
			screenLocation = new Point(lh, WindowHeight - 5.5 * lh);

			strField3.x = screenLocation.x;
			strField3.y = screenLocation.y;
			strField3.autoSize =TextFieldAutoSize.LEFT;
			strField3.alpha = 1.0;
			strField3.selectable = false;
			strField3.defaultTextFormat = strFormat;
			strField3.text = "Update: "+ GetPhaseTimerFps(smoothedTimerUpdate);
				
			screenLocation.y += lh;
			strField4.x = screenLocation.x;
			strField4.y = screenLocation.y;
			strField4.autoSize = TextFieldAutoSize.LEFT;
			strField4.alpha = 1.0;
			strField4.selectable = false;
			strField4.defaultTextFormat = strFormat;
			strField4.text = "Draw:   "+ GetPhaseTimerFps(smoothedTimerDraw);
			
			screenLocation.y += lh;
			
			strField5.x = screenLocation.x;
			strField5.y = screenLocation.y;
			strField5.autoSize = TextFieldAutoSize.LEFT;
			strField5.alpha = 1.0;
			strField5.selectable = false;
			strField5.defaultTextFormat = strFormat;
			strField5.text = "Other: "+ GetPhaseTimerFps(smoothedTimerOverhead);
			
			screenLocation.y += 1.5 * lh;

			strField6.x = screenLocation.x;
			strField6.y = screenLocation.y;
			strField6.autoSize = TextFieldAutoSize.LEFT;
			strField6.alpha = 1.0;
			strField6.selectable = false;
			strField6.defaultTextFormat = strFormat;

			// target and recent average frame rates
			var targetFPS:int = clock.FixedFrameRate;
			var smoothedFPS:Number = clock.SmoothedFPS;

			// describe clock mode and frame rate statistics
			var sb:String = new String();
			sb = "Clock: ";
			if (clock.AnimationMode == true)
			{
				var ratio:Number = smoothedFPS / targetFPS;
				sb +="animation mode ("+targetFPS+" fps, display "+Math.round(smoothedFPS)+" fps "+int((100 * ratio))+"% of nominal speed)";
			}
			else
			{
				sb +="real-time mode, ";
				if (clock.VariableFrameRateMode == true)
				{
					sb +="variable frame rate ("+Math.round(smoothedFPS)+" fps)";
				}
				else
				{
					sb +="fixed frame rate (target: "+targetFPS+" actual: "+Math.round(smoothedFPS);

					// create usage description character string
					sb +="usage: "+clock.SmoothedUsage.toPrecision(1)+"% ";
					strField6.text = sb;
					var xp:Number = screenLocation.x + sb.length * cw;

					for (var i:int = 0; i < strField6.length; i++)
					{
						sb +=" ";
					}
					sb +=")";

					// display message in lower left corner of window
					// (draw in red if the instantaneous usage is 100% or more)
					var usage:Number = clock.Usage;
					var color:uint = (usage >= 100) ? Colors.Red : Colors.White;
					
					strField6.x = xp;
					strField6.y = screenLocation.y;
					strField6.text = sb;
					}
			}
			strField6.text = sb;
			renderer.renderScene(scene,camera.pv3dcamera,viewport);
		}

		private static function GetPhaseTimerFps(phaseTimer:Number):String 
		{
			// different notation for variable and fixed frame rate
			if (clock.VariableFrameRateMode == true)
			{
				// express as FPS (inverse of phase time)
				return String(phaseTimer.toPrecision(5) +"("+ int(1 / phaseTimer)+" FPS)" );
			}
			else
			{
				// quantify time as a percentage of frame time
				var fps:Number = clock.FixedFrameRate;// 1.0f / TargetElapsedTime.TotalSeconds;
				return String(phaseTimer.toPrecision(5) +"("+(100.0 * phaseTimer) / (1.0 / fps)+"% of 1/"+int(fps)+"sec)");
			}
		}

		public static function IsDrawPhase():Boolean
		{
			return phase == Phase.Draw;
		}

		public function get PhaseTimerDraw():Number
		{
			return phaseTimers[Phase.Draw];
		}
		public function get PhaseTimerUpdate():Number
		{
			return phaseTimers[Phase.Update];
		}
		
		/**
		 * Get around shortcomings in current implementation, see note
		 * in updateSimulationAndRedraw
		 */
		public function get PhaseTimerOverhead():Number
		{
			return clock.ElapsedRealTime - (PhaseTimerDraw + PhaseTimerUpdate)+0.0;
		}

		public function InitPhaseTimers():void
		{
			phaseTimers[Phase.Draw] = 0;
			phaseTimers[Phase.Update] = 0;
			phaseTimers[Phase.Overhead] = 0;
			phaseTimerBase = clock.TotalRealTime;
		}

		public function UpdatePhaseTimers():void
		{
			var currentRealTime:Number = clock.RealTimeSinceFirstClockUpdate();
			phaseTimers[phase] += currentRealTime - phaseTimerBase;
			phaseTimerBase = currentRealTime;
		}
		
		public function getandDrawText(text:String, location:Vector3, color:uint):void
		{
			// set text color and raster position
			var strFormat:TextFormat = new TextFormat();
			strFormat.align = "left";
			strFormat.size=12;
			strFormat.kerning = true;
			strFormat.font = "Arial";
			strFormat.color = color;
			
			textEntry.defaultTextFormat = strFormat;
			textEntry.selectable = false;
			textEntry.x = location.x;
			textEntry.y = location.y;
			textEntry.alpha = 1.0;
			textEntry.text = text;
			textEntry.autoSize = TextFieldAutoSize.LEFT;
		}
	}
}
