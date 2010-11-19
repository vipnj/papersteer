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

package tabinda.demo.plugins.Boids
{
	import flash.ui.Keyboard;
	import org.papervision3d.core.proto.DisplayObjectContainer3D;
	import org.papervision3d.objects.DisplayObject3D;
	
	import org.papervision3d.core.geom.Lines3D;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.typography.*;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;

	public class BoidsPlugIn extends PlugIn
	{
		public var lines:Lines3D;
		
		// flock: a group (STL vector) of pointers to all boids
		public var flock:Vector.<Boid>;

		// pointer to database used to accelerate proximity queries
		public var pd:IProximityDatabase;

		// keep track of current flock size
		public var population:int;

		// which of the various proximity databases is currently in use
		public var cyclePD:int;
		
		public function BoidsPlugIn()
		{			
			super();
			flock = new Vector.<Boid>();
		}
		
		public override function get Name():String 
		{ return "Boids";}

		public override function get SelectionOrderSortKey():Number
		{
			return -0.03; 
		}

		public override function Open():void
		{
			initPV3D();
			
			// make the database used to accelerate proximity queries
			cyclePD = -1;
			NextPD();

			// make default-sized flock
			population = 0;
			
			for (var i:int = 0; i < 100; i++) 
			{
				AddBoidToFlock();
			}

			// initialize camera
			Demo.Init3dCamera(Demo.SelectedVehicle);
			Demo.camera.Mode = CameraMode.Fixed;
			Demo.camera.FixedDistanceDistance = Demo.CameraTargetDistance;
			Demo.camera.FixedDistanceVerticalOffset = 0;
			Demo.camera.LookDownDistance = 20;
			Demo.camera.AimLeadTime = 0.5;
			Demo.camera.PovOffset.x =0;
            Demo.camera.PovOffset.y = 0.5;
            Demo.camera.PovOffset.z = -2;
		}
		
		public function initPV3D():void
		{
			lines = new Lines3D(new LineMaterial(0x000000,1));
			Demo.container.addChild(lines);
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
			var nearMouse:IVehicle = Demo.VehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera(currentTime, elapsedTime, selected);

			// draw each boid in flock
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].Draw();
			}

			// Refresh PV3D Lines Object
			lines.geometry.faces = [];
            lines.geometry.vertices = [];
            lines.removeAllLines();
			
			// highlight vehicle nearest mouse
			DrawCircleHighlightOnVehicle(nearMouse, 1, Colors.LightGray);
			
			// highlight selected vehicle
			DrawCircleHighlightOnVehicle(selected, 1, Colors.Gray);

			// display status in the upper left corner of the window
			var stats:String = new String();
			stats = "[F1/F2] " + population + " boids";
			stats += "\n[F3] PD type: ";
			switch (cyclePD)
			{
				case 0: stats +="LQ bin lattice"; break;
				case 1: stats += "brute force"; break;
			}
			stats +="\n[F4] Boundary: ";
			switch (Boid.boundaryCondition)
			{
				case 0: stats +="steer back when outside"; break;
				case 1: stats +="wrap around (teleport)"; break;
			}
			var screenLocation:Vector3 = new Vector3(15, 50, 0);
			Demo.Draw2dTextAt2dLocation(stats, screenLocation, Colors.LightGray);
		}
		
		/**
		 * Draws a colored circle (perpendicular to view axis) around the center
		 * of a given vehicle.  The circle's radius is the vehicle's radius times
		 * radiusMultiplier.
		 * 
		 * @param	v is a Vehicle
		 * @param	radiusMultiplier is a Number
		 * @param	color is an unsigned integer representing a color in Hex Format RGB
		 */
		public function DrawCircleHighlightOnVehicle(v:IVehicle,radiusMultiplier:Number,color:uint):void
		{
			if (v != null)
			{
				var cPosition:Vector3 = Demo.camera.Position;
				var radius:Number = v.Radius * radiusMultiplier;  							 // adjusted radius
				var	center:Vector3 = v.Position;                   							 // center
				var axis:Vector3 = 	Vector3.VectorSubtraction(v.Position , cPosition);       // view axis
				var	segments:int = 20;                          						 	 // circle segments
				var filled:Boolean = false;
				var in3d:Boolean = false;
				
				if (Demo.IsDrawPhase())
				{
					var ls:LocalSpace = new LocalSpace();
					
					if (in3d)
					{
						// define a local space with "axis" as the Y/up direction
						// (XXX should this be a method on  LocalSpace?)
						var unitAxis:Vector3 = axis;
						unitAxis.Normalize();
						var unitPerp:Vector3 = VHelper.FindPerpendicularIn3d(axis);
						unitPerp.Normalize();
						ls.Up = unitAxis;
						ls.Forward = unitPerp;
						ls.Position = (center);
						ls.SetUnitSideFromForwardAndUp();
					}
					
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
		}

		public override function Close():void
		{
			// delete each member of the flock
			while (population > 0)
			{
				RemoveBoidFromFlock();
			}
			
			destoryPV3DObject(lines);
			
			// delete the proximity database
			pd = null;
		}
		
		private function destoryPV3DObject(object:*):void 
		{
			Demo.container.removeChild(object);
			object.material.destroy();
			object = null;
		}

		public override function Reset():void
		{
			// reset each boid in flock
			for (var i:int = 0; i < flock.length; i++) flock[i].Reset();

			// reset camera position
			Demo.Position3dCamera(Demo.SelectedVehicle);

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove();
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
					var center:Vector3 = Vector3.Zero;
					var div:Number = 10.0;
					var divisions:Vector3 = new Vector3(div, div, div);
					var diameter:Number = Boid.worldRadius * 1.1 * 2;
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
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].NewPD(pd);
			}

			// delete old PD (if any)
			oldPD = null;
		}

		public override function HandleFunctionKeys(key:uint):void
		{
			switch (key)
			{
			case (Keyboard.F1): AddBoidToFlock(); break;
			case (Keyboard.F2): RemoveBoidFromFlock(); break;
			case (Keyboard.F3): NextPD(); break;
			case (Keyboard.F4): Boid.NextBoundaryCondition(); break;
			}
		}

		public override function PrintMiniHelpForFunctionKeys():void
		{
			var message:String = "Function keys handled by \n" + "\"" + Name + "\"" + ":";
			Demo.printMessage (message);
			Demo.printMessage ("  F1     add a boid to the flock.");
			Demo.printMessage ("  F2     remove a boid from the flock.");
			Demo.printMessage ("  F3     use next proximity database.");
			Demo.printMessage ("  F4     next flock boundary condition.");
			Demo.printMessage ("");
		}

		public function AddBoidToFlock():void
		{
			population++;
			var boid:Boid = new Boid(pd);
			flock.push(boid);
			
			// PV3D Mesh being added to DisplayList
			Demo.container.addChild(boid.objectMesh);
			
			if (population == 1)
			{
				Demo.SelectedVehicle = boid;
			}
		}

		public function RemoveBoidFromFlock():void
		{
			if (population > 0)
			{
				// save a pointer to the last boid, then remove it from the flock
				population--;
				var boid:Boid = flock[population];
				flock.splice(population, 1);
				
				// PV3D Mesh being Removed from DisplayList
				destoryPV3DObject(boid.objectMesh);
				
				// if it is Demo's selected vehicle, unselect it
				if (boid == Demo.SelectedVehicle)
				{
					Demo.SelectedVehicle = null;
				}

				// delete the Boid
				boid = null;
			}
		}

		// return an AVGroup containing each boid of the flock
		public override function get Vehicles():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(flock);
			return vehicles;
		}
	}
}
