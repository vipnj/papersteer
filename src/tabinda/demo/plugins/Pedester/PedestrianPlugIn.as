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

package tabinda.demo.plugins.Pedester
{
	import flash.ui.Keyboard;
	import org.papervision3d.typography.fonts.HelveticaMedium;
	
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.*;
	import org.papervision3d.Papervision3D;
	import org.papervision3d.typography.*;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;

	public class PedestrianPlugIn extends PlugIn
	{
		// crowd: a group (STL vector) of all Pedestrians
		private var crowd:Vector.<Pedestrian>;

		private var gridCenter:Vector3;

		// pointer to database used to accelerate proximity queries
		private var pd:IProximityDatabase;

		// keep track of current flock size
		private var population:int;

		// which of the various proximity databases is currently in use
		private var cyclePD:int;
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var pathAndObsGeometry:Lines3D;
		public var highlightGeometry:Lines3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		
		private var text3D:Text3D;
		private var textFont:Font3D;
		private var textMat:Letter3DMaterial;
		
		public var ForceRedraw:Boolean;
		
		public function PedestrianPlugIn()
		{			
			super();
			crowd = new Vector.<Pedestrian>();
		}

		public override function get Name():String { return "Pedestrians"; }

		public override function get SelectionOrderSortKey():Number { return 0.02;  }
		
		public function initPV3D():void
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
		
			pathAndObsGeometry = new Lines3D(new LineMaterial(0x000000,1));
			highlightGeometry = new Lines3D(new LineMaterial(0x000000,1));
			
			textMat = new Letter3DMaterial(0xffffff);
			textMat.doubleSided = true;
			textFont = new Font3D();
			text3D = new Text3D("", new HelveticaMedium, textMat);
			text3D.scale = 1;
			
			//Demo.container.addChild(text3D);
			addPV3DObject(GridMesh);
			addPV3DObject(pathAndObsGeometry);
			addPV3DObject(highlightGeometry);
		}

		public override function Open():void
		{
			initPV3D();
			ForceRedraw = true;
			
			// make the database used to accelerate proximity queries
			cyclePD = -1;
			NextPD();

			// create the specified number of Pedestrians
			population = 0;
			for (var i:int = 0; i < 20; i++)
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
			
			// We do  this because PV3D and AS3 are not Canvas based Drawers
			if(ForceRedraw)
			{
				pathAndObsGeometry.geometry.faces = [];
				pathAndObsGeometry.geometry.vertices = [];
				pathAndObsGeometry.removeAllLines();
				
				// Should be drawn once per restart or obstacle insertion/removal, PV3D is clumsy on constant Redrawing
				// draw the path they follow and obstacles they avoid
				DrawPathAndObstacles();
				
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
				
				Grid(gridCenter);
				
				ForceRedraw = false;
			}
			
			highlightGeometry.geometry.faces = [];
			highlightGeometry.geometry.vertices = [];
			highlightGeometry.removeAllLines();

			// draw and annotate each Pedestrian
			for (var i:int = 0; i < crowd.length; i++) crowd[i].Draw();

			// highlight Pedestrian nearest mouse
			HighlightVehicleUtility(nearMouse);
			
			// textual annotation (at the vehicle's screen position)
			SerialNumberAnnotationUtility(selected, nearMouse);

			// textual annotation for selected Pedestrian
			if (Demo.SelectedVehicle != null)//FIXME: && annotation.IsEnabled)
			{
				var color:uint = Colors.RGBToHex(int(255.0 * 0.8), int(255.0 * 0.8), int(255.0 * 1.0));
				var textOffset:Vector3 = new Vector3(0, 0.25, 0);
				var textPosition:Vector3 = Vector3.VectorAddition(selected.Position , textOffset);
				var camPosition:Vector3 = Demo.camera.Position;
				var camDistance:Number = Vector3.Distance(selected.Position, camPosition);

				var sb:String = new String();
				sb +="1: speed: "+selected.Speed+"\n";
				sb += "2: cam dist: " + camDistance + "\n";
				text3D.text = sb;
				text3D.position = textPosition.ToNumber3D();
				//Drawing.Draw2dTextAt3dLocation(sb, textPosition, color);
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
			Demo.Draw2dTextAt2dLocation(status, screenLocation, Colors.LightGray);
		}
		
		/**
		 * Draws a gray disk on the XZ plane under a given vehicle
		 * @param	vehicle
		 */
		public function HighlightVehicleUtility(v:IVehicle):void
		{
			if (v != null)
			{
				var cPosition:Vector3 = Demo.camera.Position;
				var radius:Number = v.Radius;  							 					 // adjusted radius
				var	center:Vector3 = v.Position;                   							 // center
				var axis:Vector3 = 	Vector3.VectorSubtraction(v.Position , cPosition);       // view axis
				var color:uint = 	Colors.LightGray;                        				 // drawing color
				var	segments:int = 7;                          						 	 // circle segments
				var filled:Boolean = true;
				var in3d:Boolean = false;
				
				DrawCircleOrDisk(highlightGeometry,radius, axis, center, color, segments, filled, in3d);
			}
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
												 Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
												 Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.Gray;
			var gray2:uint = Colors.DarkGray;
			
			var size:int = 50;
			var subsquares:int = 50;
			
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			var flag1:Boolean = false;
			var p:Number = -half;
			var corner:Vector3 = new Vector3();
			
			for (var i:int = 0; i < subsquares; i++)
			{
				var flag2:Boolean = flag1;
				var q:Number = -half;
				for (var j:int = 0; j < subsquares; j++)
				{
					corner.x = p;
					corner.y = 0;
					corner.z = q;

					corner = Vector3.VectorAddition(corner, center);
					
					var vertA:Vertex3D = corner.ToVertex3D();
					var vertB:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, 0)).ToVertex3D();
					var vertC:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, spacing)).ToVertex3D();
					var vertD:Vertex3D = Vector3.VectorAddition(corner, new Vector3(0, 0, spacing)).ToVertex3D();
					
					GridMesh.geometry.vertices.push(vertA, vertB, vertC, vertD);
					var colMaterial:ColorMaterial = new ColorMaterial(color, 1);
					colMaterial.doubleSided = true;
					
					var color:uint = flag2 ? gray1 : gray2;
					var t1:Triangle3D = new Triangle3D(GridMesh, [vertA,vertB,vertC], colMaterial);
					var t2:Triangle3D = new Triangle3D(GridMesh, [vertD,vertA,vertC], colMaterial);
					
					GridMesh.geometry.faces.push(t1);
					GridMesh.geometry.faces.push(t2);
					
					flag2 = !flag2;
					q += spacing;
				}
				flag1 = !flag1;
				p += spacing;
			}
			GridMesh.geometry.ready = true;
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
						var sn:String = "#" + Pedestrian(vehicle).SerialNumber;
						var textColor:uint = Colors.RGBToHex(int(255.0 * 0.8), int(255.0 * 1), int(255.0 * 0.8));
						var textOffset:Vector3 = new Vector3(0, 0.25, 0);
						var textPos:Vector3 = Vector3.VectorAddition(vehicle.Position , textOffset);
						text3D.text = sn;
						text3D.position = textPos.ToNumber3D();
						//Drawing.Draw2dTextAt3dLocation(sn, textPos, textColor);
					}
				}
			}
		}

		public function DrawPathAndObstacles():void
		{
			// draw a line along each segment of path
			var path:PolylinePathway = Globals.GetTestPath();
			for (var i:int = 0; i < path.pointCount; i++)
				if (i > 0) DrawLine(path.points[i], path.points[i - 1], Colors.Red);
				//if (i > 0) Drawing.DrawLine(path.points[i], path.points[i - 1], Colors.Red);

			// draw obstacles			
			DrawCircleOrDisk(pathAndObsGeometry,Globals.Obstacle1.Radius, Vector3.Zero,Globals.Obstacle1.Center, Colors.White, 7,false,false);
			DrawCircleOrDisk(pathAndObsGeometry,Globals.Obstacle2.Radius, Vector3.Zero,Globals.Obstacle2.Center, Colors.White, 7,false,false);
		}
		
		private function DrawLine(startPoint:Vector3, endPoint:Vector3, color:uint):void
		{
			pathAndObsGeometry.addLine(new Line3D(pathAndObsGeometry, new LineMaterial(color,1),1,new Vertex3D(startPoint.x,startPoint.y,startPoint.z),new Vertex3D(endPoint.x,endPoint.y,endPoint.z)));
		}
		
		private function DrawCircleOrDisk(lines:Lines3D,radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void
		{
			if (Demo.IsDrawPhase())
			{
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
					var line:Line3D = new Line3D(lines, new LineMaterial(Colors.White), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					lines.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(lines,radius, axis, center, color, segments, filled, in3d);
			}
		}

		public override function Close():void
		{
			//TODO: Remove scene object once the plugin closes
			destoryPV3DObject(GridMesh);
			//Demo.container.removeChild(text3D);
			destoryPV3DObject(highlightGeometry);
			destoryPV3DObject(pathAndObsGeometry);
			
			// delete all Pedestrians
			while (population > 0) RemovePedestrianFromCrowd();
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

		public override function Reset():void
		{
			// reset each Pedestrian
			for (var i:int = 0; i < crowd.length; i++) crowd[i].Reset();

			// reset camera position
			Demo.Position2dCamera(Demo.SelectedVehicle);

			// make camera jump immediately to new position
			Demo.camera.DoNotSmoothNextMove();
			
			ForceRedraw = true;
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

		private function AddPedestrianToCrowd():void
		{
			population++;
			var pedestrian:Pedestrian = new Pedestrian(pd);
			crowd.push(pedestrian);
			
			addPV3DObject(pedestrian.VehicleMesh);
			pedestrian.removeTrail();
			addPV3DObject(pedestrian.lines);
			
			if (population == 1)
			{
				Demo.SelectedVehicle = pedestrian;
			}
		}

		private function RemovePedestrianFromCrowd():void
		{
			if (population > 0)
			{
				// save pointer to last pedestrian, then remove it from the crowd
				population--;
				var pedestrian:Pedestrian = crowd[population];
				
				destoryPV3DObject(pedestrian.VehicleMesh);
				destoryPV3DObject(pedestrian.lines);
				
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
		private function NextPD():void
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
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(crowd);
			return vehicles;
		}
	}
}
