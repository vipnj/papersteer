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
		
		public var pluginReset:Boolean;
		
		public function MpPlugIn ()
		{
			super();
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			
			lines = new Lines3D(new LineMaterial(0x000000, 1));
			
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			Demo.container.addChild(lines);
			Demo.container.addChild(GridMesh);
			
			allMP = new Vector.<MpBase>();
			pluginReset = true;
		}

		public override  function get Name ():String
		{
			return "Multiple Pursuit";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.04;
		}

		public override  function Open ():void
		{
			// create the wanderer, saving a pointer to it
			wanderer = new MpWanderer() ;
			Demo.container.addChild(wanderer.objectMesh);
			Demo.container.addChild(wanderer.lines);
			
			allMP.push (wanderer);

			// create the specified number of pursuers, save pointers to them
			const pursuerCount:int=30;
			for (var i:int=0; i < pursuerCount; i++)
			{
				var mpPursuer:MpPursuer = new MpPursuer(wanderer);
				allMP.push (mpPursuer);
				Demo.container.addChild(mpPursuer.objectMesh);
				Demo.container.addChild(mpPursuer.lines);
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
			Demo.UpdateCamera (currentTime,elapsedTime,selected);

			if(pluginReset)
			{
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
			
				// draw "ground plane"
				//Demo.GridUtility (selected.Position,GridMesh);
				Grid(selected.Position);
				pluginReset = false;
			}
			// draw each vehicles
			for (var i:int=0; i < allMP.length; i++)
			{
				allMP[i].Draw ();
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
			Demo.CircleHighlightVehicleUtility (selected);
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
												 Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
												 Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.LightGray
			var gray2:uint = Colors.DarkGray;
			
			var size:int = 500;
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
					
					GridMesh.geometry.vertices.push(vertA, vertB,vertC, vertD);
					
					var color:uint = flag2 ? gray1 : gray2;
					var t1:Triangle3D = new Triangle3D(GridMesh, [vertA,vertB,vertC], new ColorMaterial(color, 1));
					var t2:Triangle3D = new Triangle3D(GridMesh, [vertD,vertA,vertC], new ColorMaterial(color, 1));
					
					GridMesh.geometry.faces.push(t1);
					GridMesh.geometry.faces.push(t2);
					
					flag2 = !flag2;
					q += spacing;
				}
				flag1 = !flag1;
				p += spacing;
			}
			if (Papervision3D.useRIGHTHANDED)
			{
				GridMesh.geometry.flipFaces();
			}
			GridMesh.geometry.ready = true;
		}

		public override  function Close ():void
		{			
			destoryPV3DObject(lines);
			destoryPV3DObject(GridMesh);
			
			destoryPV3DObject(wanderer.objectMesh);
			destoryPV3DObject(wanderer.lines);
			
			for (var i:int=1; i < allMP.length; i++)
			{
				destoryPV3DObject(MpPursuer(allMP[i]).objectMesh);
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
			
			pluginReset = true;
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