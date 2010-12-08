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

package tabinda.demo.plugins.MultiplePursuit
{
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.Papervision3D;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	
	public class MpPlugIn extends PlugIn
	{
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var lines:Lines3D;
		public var colMat:ColorMaterial
		
		public var ForceRedraw:Boolean;
		
		public function MpPlugIn ()
		{
			super();			
			allMP = new Vector.<MpBase>();
		}

		public override  function get Name ():String
		{
			return "Multiple Pursuit";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.04;
		}
		
		public function initPV3D():void
		{
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			
			lines = new Lines3D(new LineMaterial(0x000000, 1));
			
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			addPV3DObject(lines);
			addPV3DObject(GridMesh);
		}

		public override  function Open ():void
		{
			initPV3D();
			ForceRedraw = true;
			
			// create the wanderer, saving a pointer to it
			wanderer = new MpWanderer() ;
			addPV3DObject(wanderer.VehicleMesh);
			addPV3DObject(wanderer.lines);
			
			allMP.push (wanderer);

			// create the specified number of pursuers, save pointers to them
			const pursuerCount:int=30;
			for (var i:int=0; i < pursuerCount; i++)
			{
				var mpPursuer:MpPursuer = new MpPursuer(wanderer);
				allMP.push (mpPursuer);
				addPV3DObject(mpPursuer.VehicleMesh);
				addPV3DObject(mpPursuer.lines);
			}
			
			//pBegin = allMP.begin() + 1;  // iterator pointing to first pursuer
			//pEnd = allMP.end();          // iterator pointing to last pursuer

			// initialize camera
			Demo.SelectedVehicle=wanderer;
			Demo.camera.Mode=CameraMode.StraightDown;
			Demo.camera.FixedDistanceDistance=Demo.CameraTargetDistance;
			Demo.camera.FixedDistanceVerticalOffset=Demo.Camera2dElevation;
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update the wanderer
			wanderer.Update (currentTime,elapsedTime);

			// update each pursuer
			for (var i:int=1; i < allMP.length; i++)
			{
				MpPursuer(allMP[i]).Update (currentTime,elapsedTime);
			}
			//pluginReset = true;
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// selected vehicle (user can mouse click to select another)
			var selected:IVehicle=Demo.SelectedVehicle;

			// vehicle nearest mouse (to be highlighted)
			var nearMouse:IVehicle = Demo.VehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera (currentTime, elapsedTime, selected);
			
			lines.geometry.vertices = [];
			lines.geometry.faces = [];
			lines.removeAllLines();

			if(ForceRedraw)
			{
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
			
				// draw "ground plane"
				//Demo.GridUtility (selected.Position,GridMesh);
				Grid(selected.Position);
				ForceRedraw = false;
			}
			// draw each vehicles
			for (var i:int=0; i < allMP.length; i++)
			{
				allMP[i].Draw ();
			}

			// highlight vehicle nearest mouse
			//Demo.HighlightVehicleUtility (nearMouse);
			//Demo.CircleHighlightVehicleUtility (selected);
			HighlightVehicleUtility(nearMouse);
			HighlightVehicleUtility(selected);
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
												 Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
												 Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.Gray
			var gray2:uint = Colors.DarkGray;
			
			var size:int = 100;
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
					corner.y = -1;
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

		public override  function Close ():void
		{			
			destoryPV3DObject(lines);
			destoryPV3DObject(GridMesh);
			
			destoryPV3DObject(wanderer.VehicleMesh);
			destoryPV3DObject(wanderer.lines);
			
			for (var i:int=1; i < allMP.length; i++)
			{
				destoryPV3DObject(MpPursuer(allMP[i]).VehicleMesh);
				destoryPV3DObject(MpPursuer(allMP[i]).lines);
			}

			// delete wanderer, all pursuers, and clear list
			allMP.splice(0,allMP.length);
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

		public override  function Reset ():void
		{
			// reset wanderer and pursuers
			wanderer.Reset ();
			for (var i:int=1; i < allMP.length; i++)
			{
				MpPursuer(allMP[i]).Reset ();
			}

			// immediately jump to default camera position
			Demo.camera.DoNotSmoothNextMove ();
			Demo.camera.ResetLocalSpace ();
			
			ForceRedraw = true;
		}

		//const AVGroup& allVehicles () {return (const AVGroup&) allMP;}
		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(allMP);
			return vehicles;
		}

		// a group (STL vector) of all vehicles
		private var allMP:Vector.<MpBase>;
		private var wanderer:MpWanderer;
	}
}