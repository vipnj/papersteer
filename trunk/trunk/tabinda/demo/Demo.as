// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>

package tabinda.demo
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import org.papervision3d.cameras.*;
	import org.papervision3d.render.*;
	import org.papervision3d.scenes.*;
	import org.papervision3d.view.*;
	import org.papervision3d.events.*;
	
	import tabinda.papersteer.*;
	
	import tabinda.papersteer.plugins.Boids.*;
	import tabinda.papersteer.plugins.LowSpeedTurn.*;
	import tabinda.papersteer.plugins.Pedestrian.*;
	import tabinda.papersteer.plugins.Ctf.*;
	import tabinda.papersteer.plugins.MapDrive.*;
	import tabinda.papersteer.plugins.MultiplePursuit.*;
	import tabinda.papersteer.plugins.Soccer.*;
	import tabinda.papersteer.plugins.OneTurning.*;
	
	/// <summary>
	/// This is the main type for your game
	/// </summary>
	public class Demo extends Sprite
	{
		// these are the size of the offscreen drawing surface
		// in general, no one wants to change these as there
		// are all kinds of UI calculations and positions based
		// on these dimensions.
		const FixedDrawingWidth:int = 1280;
		const FixedDrawingHeight:int = 720;

		private var preferredWindowWidth:int = 1024;
		private var preferredWindowHeight:int = 640;
		
		var viewport:Viewport3D;
		var scene:Scene3D;
		var camera:FreeCamera3D;
		var renderer:BasicRenderEngine;

		var boids:BoidsPlugIn;
		var lowSpeedTurn:LowSpeedTurnPlugIn;
		var pedestrian:PedestrianPlugIn;
		var ctf:CtfPlugIn;
		var mapDrive:MapDrivePlugIn;
		var muliplepersuit:MpPlugIn;
		var soccer:SoccerPlugIn;
		var oneTurning:OneTurningPlugIn;

		// currently selected plug-in (user can choose or cycle through them)
		public static var SelectedPlugIn:PlugIn = null;

		// currently selected vehicle.  Generally the one the camera follows and
		// for which additional information may be displayed.  Clicking the mouse
		// near a vehicle causes it to become the Selected Vehicle.
		public static var SelectedVehicle:IVehicle = null;

		public static var Clock:Clock= new Clock();

		// some camera-related default constants
		public const Camera2dElevation:Number = 8;
		public const CameraTargetDistance:Number = 13;
		public static var CameraTargetOffset:Vector3 = new Vector3(0, Camera2dElevation, 0);

		public function Demo()
		{
			Drawing.game = this;

			viewport=new Viewport3D(0,0,true,true);
			addChild(viewport);
			
			renderer=new BasicRenderEngine();
			scene = new Scene3D();
			camera = new Camera3D();
			camera.zoom = 8;
			camera.z = 0;

			texts = new Array();

			//FIXME: eijeijei.
			Annotation.drawer = new Drawing();

			boids = new BoidsPlugIn();
			lowSpeedTurn = new LowSpeedTurnPlugIn();
			pedestrian = new PedestrianPlugIn();
			ctf = new CtfPlugIn();
			mapDrive = new MapDrivePlugIn();
			multiplePersuit = new MpPlugIn();
			soccer = new SoccerPlugIn();
			oneTurning = new OneTurningPlugIn();

			IsFixedTimeStep = false;
			
			renderer.renderScene(scene,camera,viewport);
		}
		
		public static function Init2dCamera(...args):void
		{
			if(args.length == 1)
			{
				Position2dCamera(args[0], CameraTargetDistance, Camera2dElevation);
				Camera.FixedDistanceDistance = CameraTargetDistance;
				Camera.FixedDistanceVerticalOffset = Camera2dElevation;
				Camera.Mode = Camera.CameraMode.FixedDistanceOffset;
			}
			else if(args.length == 3)
			{
				Position2dCamera(args[0], args[1], args[2]);
				Camera.FixedDistanceDistance = args[1];
				Camera.FixedDistanceVerticalOffset = args[2];
				Camera.Mode = Camera.CameraMode.FixedDistanceOffset;
			}
		}

		public static function Init3dCamera(...args):void
		{
			if(args.length == 1)
			{
				Position3dCamera(args[0], CameraTargetDistance, Camera2dElevation);
				Camera.FixedDistanceDistance = CameraTargetDistance;
				Camera.FixedDistanceVerticalOffset = Camera2dElevation;
				Camera.Mode = Camera.CameraMode.FixedDistanceOffset;
			}
			if(args.length == 3)
			{
				Position3dCamera(args[0], args[1], args[2]);
				Camera.FixedDistanceDistance = args[1];
				Camera.FixedDistanceVerticalOffset = args[2];
				Camera.Mode = Camera.CameraMode.FixedDistanceOffset;
			}
		}

		public static function Position2dCamera(...args)
		{
			if(args.length == 1)
			{
				// position the camera as if in 3d:
				Position3dCamera(args[0], CameraTargetDistance, Camera2dElevation);

				// then adjust for 3d:
				var position3d:Vector3 = Camera.Position;
				position3d.Y += Camera2dElevation;
				Camera.Position = (position3d);
			}
			else if(args.length == 3)
			{
				// position the camera as if in 3d:
				Position3dCamera(args[0], args[1], args[2]);

				// then adjust for 3d:
				var position3d:Vector3 = Camera.Position;
				position3d.Y += args[2];
				Camera.Position = (position3d);
			}
		}

		public static function Position3dCamera(...args):void
		{
			SelectedVehicle = args[0];
			
			if(args.length == 1)
			{
				if (args[0] != null)
				{
					var behind:Vector3 = args[0].Forward * -distance;
					Camera.Position = (args[0].Position + behind);
					Camera.Target = args[0].Position;
				}
			}
			else if(args.length == 3)
			{
				if (args[0] != null)
				{
					var behind:Vector3 = args[0].Forward * -args[1];
					Camera.Position = (args[0].Position + behind);
					Camera.Target = args[0].Position;
				}
			}
		}

		// camera updating utility used by several (all?) plug-ins
		public static function UpdateCamera(currentTime:Number,elapsedTime:Number, selected:IVehicle):void
		{
			Camera.VehicleToTrack = selected;
			Camera.Update(currentTime, elapsedTime, Clock.PausedState);
		}

		// ground plane grid-drawing utility used by several plug-ins
		public static function GridUtility(gridTarget:Vector3):void
		{
			// Math.Round off target to the nearest multiple of 2 (because the
			// checkboard grid with a pitch of 1 tiles with a period of 2)
			// then lower the grid a bit to put it under 2d annotation lines
			var gridCenter:Vector3 = new Vector3(Number(Math.round(gridTarget.X * 0.5) * 2),
								   Number(Math.round(gridTarget.Y * 0.5) * 2) - .05,
								   Number(Math.round(gridTarget.Z * 0.5) * 2));

			// colors for checkboard
			var gray1:Color = new Color(new Vector3(0.27));
			var gray2:Color = new Color(new Vector3(0.30));

			// draw 50x50 checkerboard grid with 50 squares along each side
			Drawing.DrawXZCheckerboardGrid(50, 50, gridCenter, gray1, gray2);

			// alternate style
			//Bnoerj.AI.Steering.Draw.drawXZLineGrid(50, 50, gridCenter, Color.Black);
		}

		// draws a gray disk on the XZ plane under a given vehicle
		public static function HighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				Drawing.DrawXZDisk(vehicle.Radius, vehicle.Position, Color.LightGray, 20);
			}
		}

		// draws a gray circle on the XZ plane under a given vehicle
		public static function CircleHighlightVehicleUtility(vehicle:IVehicle):void
		{
			if (vehicle != null)
			{
				Drawing.DrawXZCircle(vehicle.Radius * 1.1, vehicle.Position, Color.LightGray, 20);
			}
		}

		// draw a box around a vehicle aligned with its local space
		// xxx not used as of 11-20-02
		public static function DrawBoxHighlightOnVehicle(v:IVehicle, color:Color):void
		{
			if (v != null)
			{
				var diameter:Number = v.Radius * 2;
				var size:Vector3 = new Vector3(diameter, diameter, diameter);
				Drawing.DrawBoxOutline(v, size, color);
			}
		}

		// draws a colored circle (perpendicular to view axis) around the center
		// of a given vehicle.  The circle's radius is the vehicle's radius times
		// radiusMultiplier.
		public static function DrawCircleHighlightOnVehicle(v:IVehicle, radiusMultiplier:Number, color:Color):void
		{
			if (v != null)
			{
				var cPosition:Vector3 = Camera.Position;
				Drawing.Draw3dCircle(
					v.Radius * radiusMultiplier,  // adjusted radius
					v.Position,                   // center
					v.Position - cPosition,       // view axis
					color,                        // drawing color
					20);                          // circle segments
			}
		}

		// Find the AbstractVehicle whose screen position is nearest the current the
		// mouse position.  Returns NULL if mouse is outside this window or if
		// there are no AbstractVehicle.
		internal static function VehicleNearestToMouse():IVehicle
		{
			return null;//findVehicleNearestScreenPosition(mouseX, mouseY);
		}

		// Find the AbstractVehicle whose screen position is nearest the given window
		// coordinates, typically the mouse position.  Returns NULL if there are no
		// AbstractVehicles.
		//
		// This works by constructing a line in 3d space between the camera location
		// and the "mouse point".  Then it measures the distance from that line to the
		// centers of each AbstractVehicle.  It returns the AbstractVehicle whose
		// distance is smallest.
		//
		// xxx Issues: Should the distanceFromLine test happen in "perspective space"
		// xxx or in "screen space"?  Also: I think this would be happy to select a
		// xxx vehicle BEHIND the camera location.
		internal static function findVehicleNearestScreenPosition(x:int, y:int):IVehicle
		{
			// find the direction from the camera position to the given pixel
			var direction:Vector3 = DirectionFromCameraToScreenPosition(x, y);

			// iterate over all vehicles to find the one whose center is nearest the
			// "eye-mouse" selection line
			var minDistance:Number = Number.MAX_VALUE;       // smallest distance found so far
			var nearest:IVehicle = null;   // vehicle whose distance is smallest
			var vehicles:Array = AllVehiclesOfSelectedPlugIn();
			for each (var vehicle:IVehicle in vehicles)
			{
				// distance from this vehicle's center to the selection line:
				var d:Number = Vector3Helpers.DistanceFromLine(vehicle.Position, Camera.Position, direction);

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

		// return a normalized direction vector pointing from the camera towards a
		// given point on the screen: the ray that would be traced for that pixel
		static function DirectionFromCameraToScreenPosition(x:int, y:int):Vector3
		{
/*#if TODO
			// Get window height, viewport, modelview and projection matrices
			// Unproject mouse position at near and far clipping planes
			gluUnProject(x, h - y, 0, mMat, pMat, vp, &un0x, &un0y, &un0z);
			gluUnProject(x, h - y, 1, mMat, pMat, vp, &un1x, &un1y, &un1z);

			// "direction" is the normalized difference between these far and near
			// unprojected points.  Its parallel to the "eye-mouse" selection line.
			Vector3 diffNearFar = new Vector3(un1x - un0x, un1y - un0y, un1z - un0z);
			Vector3 direction = diffNearFar.normalize();
			return direction;
#else
			return Vector3.Up;
#endif*/
		}

		// select the "next" plug-in, cycling through "plug-in selection order"
		static function SelectDefaultPlugIn():void
		{
			PlugIn.SortBySelectionOrder();
			SelectedPlugIn = PlugIn.FindDefault();
		}

		// open the currently selected plug-in
		static function OpenSelectedPlugIn():void
		{
			Camera.Reset();
			SelectedVehicle = null;
			SelectedPlugIn.Open();
		}

		static function ResetSelectedPlugIn():void
		{
			SelectedPlugIn.Reset();
		}

		static function CloseSelectedPlugIn():void
		{
			SelectedPlugIn.Close();
			SelectedVehicle = null;
		}

		// return a group (an STL vector of AbstractVehicle pointers) of all
		// vehicles(/agents/characters) defined by the currently selected PlugIn
		static function AllVehiclesOfSelectedPlugIn():Array
		{
			return SelectedPlugIn.Vehicles;
		}

		// select the "next" vehicle: the one listed after the currently selected one
		// in allVehiclesOfSelectedPlugIn
		static function SelectNextVehicle():void
		{
			if (SelectedVehicle != null)
			{
				// get a container of all vehicles
				var all:Array = AllVehiclesOfSelectedPlugIn();

				// find selected vehicle in container
				var i:int = all.indexOf(SelectedVehicle);// return v != null && v == SelectedVehicle; });
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

		function UpdateSelectedPlugIn(currentTime:Number, elapsedTime:Number):void
		{
			// switch to Update phase
			PushPhase(Phase.Update);

			// service queued reset request, if any
			DoDelayedResetPlugInXXX();

			// if no vehicle is selected, and some exist, select the first one
			if (SelectedVehicle == null)
			{
				var all:Array = AllVehiclesOfSelectedPlugIn();
				if (all.length > 0)
					SelectedVehicle = all[0];
			}

			// invoke selected PlugIn's Update method
			SelectedPlugIn.Update(currentTime, elapsedTime);

			// return to previous phase
			PopPhase();
		}

		static var delayedResetPlugInXXX:Boolean = false;
		internal static function QueueDelayedResetPlugInXXX():void
		{
			delayedResetPlugInXXX = true;
		}

		static function DoDelayedResetPlugInXXX():void
		{
			if (delayedResetPlugInXXX)
			{
				ResetSelectedPlugIn();
				delayedResetPlugInXXX = false;
			}
		}

		function PushPhase(newPhase:Phase):void
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
				throw new Error("phaseStack overflow");
			}
		}

		function PopPhase():void
		{
			// update timer for current (old) phase: add in time since last switch
			UpdatePhaseTimers();

			// restore old phase
			phase = phaseStack[--phaseStackIndex];
		}

		// redraw graphics for the currently selected plug-in
		function RedrawSelectedPlugIn(currentTime:Number, elapsedTime:Number):void
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

		var frameRatePresetIndex:int = 0;

		// cycle through frame rate presets  (XXX move this to OpenSteerDemo)
		function SelectNextPresetFrameRate():void
		{
			// note that the cases are listed in reverse order, and that 
			// the default is case 0 which causes the index to wrap around
			switch (++frameRatePresetIndex)
			{
			case 3:
				// animation mode at 60 fps
				Clock.FixedFrameRate = 60;
				Clock.AnimationMode = true;
				Clock.VariableFrameRateMode = false;
				break;
			case 2:
				// real-time fixed frame rate mode at 60 fps
				Clock.FixedFrameRate = 60;
				Clock.AnimationMode = false;
				Clock.VariableFrameRateMode = false;
				break;
			case 1:
				// real-time fixed frame rate mode at 24 fps
				Clock.FixedFrameRate = 24;
				Clock.AnimationMode = false;
				Clock.VariableFrameRateMode = false;
				break;
			case 0:
			default:
				// real-time variable frame rate mode ("as fast as possible")
				frameRatePresetIndex = 0;
				Clock.FixedFrameRate = 0;
				Clock.AnimationMode = false;
				Clock.VariableFrameRateMode = true;
				break;
			}
		}

		private function SelectNextPlugin():void
		{
			CloseSelectedPlugIn();
			SelectedPlugIn = SelectedPlugIn.Next();
			OpenSelectedPlugIn();
		}

		/// <summary>
		/// Allows the game to perform any initialization it needs to before starting to run.
		/// This is where it can query for any required services and load any non-graphic
		/// related content.  Calling base.Initialize will enumerate through any components
		/// and initialize them as well.
		/// </summary>
		protected override function Initialize():void
		{
			// TODO: Add your initialization logic here
			SelectDefaultPlugIn();
			OpenSelectedPlugIn();

			//super.Initialize();
			addEventListener(Event.ENTER_FRAME, Update);
		}

		/// <summary>
		/// Load your graphics content.  If loadAllContent is true, you should
		/// load content from both ResourceManagementMode pools.  Otherwise, just
		/// load ResourceManagementMode.Manual content.
		/// </summary>
		/// <param name="loadAllContent">Which type of content to load.</param>
		protected override function LoadGraphicsContent(loadAllContent:Boolean):void
		{
			/*if (loadAllContent)
			{
				// TODO: Load any ResourceManagementMode.Automatic content
				//courierFont = new FixedFont(content.Load<Texture2D>("Content/Fonts/Courier"));

				//spriteBatch = new SpriteBatch(graphics.GraphicsDevice);

				//effect = content.Load<Effect>("Content/Shaders/Simple");
				//effectParamWorldViewProjection = effect.Parameters["WorldViewProjection"];
			}*/

			// TODO: Load any ResourceManagementMode.Manual content
			//vertexDeclaration = new VertexDeclaration(graphics.GraphicsDevice, VertexPositionColor.VertexElements);
		}

		/// <summary>
		/// Unload your graphics content.  If unloadAllContent is true, you should
		/// unload content from both ResourceManagementMode pools.  Otherwise, just
		/// unload ResourceManagementMode.Manual content.  Manual content will get
		/// Disposed by the GraphicsDevice during a Reset.
		/// </summary>
		/// <param name="unloadAllContent">Which type of content to unload.</param>
		protected override function UnloadGraphicsContent(unloadAllContent:Boolean):void
		{
			if (unloadAllContent == true)
			{
				content.Unload();
			}
		}

		/// <summary>
		/// Allows the game to run logic such as updating the world,
		/// checking for collisions, gathering input and playing audio.
		/// </summary>
		/// <param name="gameTime">Provides a snapshot of timing values.</param>
		var prevKeyState:KeyboardState = new KeyboardState();

		function IsKeyDown(keyState:KeyboardState, key:Keys):Boolean
		{
			return prevKeyState.IsKeyDown(key) == false && keyState.IsKeyDown(key) == true;
		}

		protected override function Update(gameTime:GameTime):void
		{
			// Allows the default game to exit on Xbox 360 and Windows
			/*GamePadState padState = GamePad.GetState(PlayerIndex.One);
			KeyboardState keyState = Keyboard.GetState();
			if (padState.Buttons.Back == ButtonState.Pressed ||
				keyState.IsKeyDown(Keys.Escape) == true)
			{
				this.stop();
			}

			if (IsKeyDown(keyState, Keys.R) == true)
			{
				ResetSelectedPlugIn();
			}
			if (IsKeyDown(keyState, Keys.S) == true)
			{
				SelectNextVehicle();
			}
			if (IsKeyDown(keyState, Keys.A) == true)
			{
				SteerLibrary.annotation.IsEnabled = !SteerLibrary.annotation.IsEnabled;
			}
			if (IsKeyDown(keyState, Keys.Space) == true)
			{
				Clock.TogglePausedState();
			}
			if (IsKeyDown(keyState, Keys.C) == true)
			{
				Camera.SelectNextMode();
			}
			if (IsKeyDown(keyState, Keys.F) == true)
			{
				SelectNextPresetFrameRate();
			}
			if (IsKeyDown(keyState, Keys.Tab) == true)
			{
				SelectNextPlugin();
			}

			for (Keys key = Keys.F1; key <= Keys.F10; key++)
			{
				if (IsKeyDown(keyState, key) == true)
				{
					SelectedPlugIn.HandleFunctionKeys(key);
				}
			}*/

			//prevKeyState = keyState;

			// TODO: Add your update logic here

			// update global simulation clock
			Clock.Update();

			//  start the phase timer (XXX to accurately measure "overhead" time this
			//  should be in displayFunc, or somehow account for time outside this
			//  routine)
			InitPhaseTimers();

			// run selected PlugIn (with simulation's current time and step size)
			UpdateSelectedPlugIn(Clock.TotalSimulationTime, Clock.ElapsedSimulationTime);

			//worldMatrix = Matrix.Identity;

			var pos:Vector3 = Camera.Position;
			var lookAt:Vector3 = Camera.Target;
			var up:Vector3= Camera.Up;
			viewMatrix = Matrix.CreateLookAt(new Vector3(pos.X, pos.Y, pos.Z), new Vector3(lookAt.X, lookAt.Y, lookAt.Z), new Vector3(up.X, up.Y, up.Z));

			projectionMatrix = Matrix.CreatePerspectiveFieldOfView(
				MathHelper.ToRadians(45),  // 45 degree angle
				Number(viewport.width) / Number(viewport.height),
				1.0, 400.0);

			renderer.renderScene(scene,camera,viewport);
		}

		/// <summary>
		/// This is called when the game should draw itself.
		/// </summary>
		/// <param name="gameTime">Provides a snapshot of timing values.</param>
		protected override function Draw(gameTime:GameTime):void
		{
			//graphics.GraphicsDevice.Clear(Color.CornflowerBlue);
			graphics.clear();
			graphics.drawRect(0, 0, viewport.width, viewport.height);

			// redraw selected PlugIn (based on real time)
			RedrawSelectedPlugIn(Clock.TotalRealTime, Clock.ElapsedRealTime);

			/*for each (var text:TextField in texts)
			{
				courierFont.Draw(text.text, text.Position, 1.0, text.Color, spriteBatch);
			}*/
			texts.splice(0, null);

			// get smoothed phase timer information
			var ptd:Number = PhaseTimerDraw;
			var ptu:Number = PhaseTimerUpdate;
			var pto:Number = PhaseTimerOverhead;
			var smoothRate:Number = Clock.SmoothingRate;
			Utilities.BlendIntoAccumulator(smoothRate, ptd,  smoothedTimerDraw);
			Utilities.BlendIntoAccumulator(smoothRate, ptu,  smoothedTimerUpdate);
			Utilities.BlendIntoAccumulator(smoothRate, pto,  smoothedTimerOverhead);

			// keep track of font metrics and start of next line
			var screenLocation:Point = new Point(lh, lh);

			var strField:TextField;
			var strField2:TextField;
			var strField3:TextField;
			var strField4:TextField;
			var strField5:TextField;
			var strFormat:TextFormat;
			
			strFormat.align = "left";
			strFormat.size=8;
			strFormat.color = Colors.White;
			
			strField.x = screenLocation.x;
			strField.y = screenLocation.y;
			strField.autoSize = true;
			strField.alpha = 1.0;
			strField.defaultTextFormat = strFormat;
			strField.text = "Camera: {0} " + Camera.ModeName;
			addChild(strField);
			
			screenLocation.y += lh;
			strField2.x = screenLocation.x;
			strField2.y = screenLocation.y;
			strField2.autoSize = true;
			strField2.alpha = 1.0;
			strField2.defaultTextFormat = strFormat;
			strField2.text = "PlugIn: {0} " + SelectedPlugIn.Name;
			addChild(strField2);
			
			screenLocation = new Point(lh, preferredWindowHeight - 5.5 * lh);

			strField3.x = screenLocation.x;
			strField3.y = screenLocation.y;
			strField3.autoSize = true;
			strField3.alpha = 1.0;
			strField3.defaultTextFormat = strFormat;
			strField3.text = "Update: {0} " + GetPhaseTimerFps(smoothedTimerUpdate);
			addChild(strField3);
				
			screenLocation.Y += lh;
			strField4.x = screenLocation.x;
			strField4.y = screenLocation.y;
			strField4.autoSize = true;
			strField4.alpha = 1.0;
			strField4.defaultTextFormat = strFormat;
			strField4.text = "Draw:   {0} "+ GetPhaseTimerFps(smoothedTimerDraw);
			addChild(strField4);
			
			screenLocation.Y += lh;
			
			strField5.x = screenLocation.x;
			strField5.y = screenLocation.y;
			strField5.autoSize = true;
			strField5.alpha = 1.0;
			strField5.defaultTextFormat = strFormat;
			strField5.text = "Other:  {0}", GetPhaseTimerFps(smoothedTimerOverhead);
			addChild(strField5);
			
			screenLocation.Y += 1.5 * lh;

			// target and recent average frame rates
			var targetFPS:int = Clock.FixedFrameRate;
			var smoothedFPS:Number = Clock.SmoothedFPS;

			// describe clock mode and frame rate statistics
			var sb:TextField = new TextField();
			sb.appendText("Clock: ");
			if (Clock.AnimationMode == true)
			{
				var ratio:Number = smoothedFPS / targetFPS;
				sb.text("animation mode ({0} fps, display {1} fps {2}% of nominal speed)",	targetFPS, Math.round(smoothedFPS), int((100 * ratio));
				addChild(sb);
			}
			else
			{
				sb.appendText("real-time mode, ");
				if (Clock.VariableFrameRateMode == true)
				{
					sb.text("variable frame rate ({0} fps)", Math.round(smoothedFPS));
				}
				else
				{
					sb.text("fixed frame rate (target: {0} actual: {1}, ", targetFPS, Math.round(smoothedFPS));

					// create usage description character string
					strField.text = "usage: {0:0}% " + Clock.SmoothedUsage;
					var x:Number = screenLocation.X + sb.Length * cw;

					for (var i:int = 0; i < strField.length; i++) sb.appendText(" ");
					sb.appendText(")");

					// display message in lower left corner of window
					// (draw in red if the instantaneous usage is 100% or more)
					var usage:Number = Clock.Usage;
					var color:Color = (usage >= 100) ? Color.Red : Color.White;
					//courierFont.Draw(str, new Vector2(x, screenLocation.Y), 1, color, spriteBatch);
				}
			}
			str = sb;
			//courierFont.Draw(str, screenLocation, 1.0, Color.White, spriteBatch);

			//spriteBatch.End();

			//base.Draw(gameTime);
			Draw(gameTime);
		}

		static function GetPhaseTimerFps(phaseTimer:Number):String 
		{
			// different notation for variable and fixed frame rate
			if (Clock.VariableFrameRateMode == true)
			{
				// express as FPS (inverse of phase time)
				return String("{0:0.00000} ({1:0} FPS)" +  phaseTimer + 1 / phaseTimer);
			}
			else
			{
				// quantify time as a percentage of frame time
				var fps:Number = Clock.FixedFrameRate;// 1.0f / TargetElapsedTime.TotalSeconds;
				return String("{0:0.00000} ({1:0}% of 1/{2}sec)" +  phaseTimer + (100.0 * phaseTimer) / (1.0 / fps) +  int(fps));
			}
		}
		
		static var phase:Phase;
		const phaseStackSize:int = 5;
		static var phaseStack:Array = new Array(phaseStackSize);
		static var phaseStackIndex:int = 0;
		static var phaseTimers:Array = new Array(int(Phase.Count));
		static var phaseTimerBase:Number = 0;

		// draw text showing (smoothed, rounded) "frames per second" rate
		// (and later a bunch of related stuff was dumped here, a reorg would be nice)
		static var smoothedTimerDraw:Number = 0;
		static var smoothedTimerUpdate:Number = 0;
		static var smoothedTimerOverhead:Number = 0;

		public static function IsDrawPhase():Boolean
		{
			return phase == Phase.Draw;
		}

		function get PhaseTimerDraw():Number
		{
			return phaseTimers[int(Phase.Draw)];
		}
		function get PhaseTimerUpdate():Number
		{
			return phaseTimers[int(Phase.Update)]; }
		}
		// XXX get around shortcomings in current implementation, see note
		// XXX in updateSimulationAndRedraw
/*#if IGNORE
		float phaseTimerOverhead
		{
			get { return phaseTimers[(int)Phase.overheadPhase]; }
		}
#else
		float PhaseTimerOverhead
		{
			get { return Clock.ElapsedRealTime - (PhaseTimerDraw + PhaseTimerUpdate); }
		}
#endif*/

		function InitPhaseTimers():void
		{
			phaseTimers[int(Phase.Draw)] = 0;
			phaseTimers[int(Phase.Update)] = 0;
			phaseTimers[int(Phase.Overhead)] = 0;
			phaseTimerBase = Clock.TotalRealTime;
		}

		 function UpdatePhaseTimers():void
		{
			var currentRealTime:Number = Clock.RealTimeSinceFirstClockUpdate();
			phaseTimers[int(phase)] += currentRealTime - phaseTimerBase;
			phaseTimerBase = currentRealTime;
		}

		var texts:Array;
		public functionAddText(text:TextEntry):void
		{
			texts.Add(text);
		}
	};
	
	public final class Phase
	{
		public static const Overhead:String = "Overhead";
		public static const Update:String = "Update";
		public static const Draw:String = "Draw";
		public static const Count:String = "Count";
	};
}
