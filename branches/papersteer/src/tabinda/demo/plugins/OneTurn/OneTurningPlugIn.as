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

package tabinda.demo.plugins.OneTurn
{
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.Letter3DMaterial;
	import org.papervision3d.Papervision3D;
	import org.papervision3d.typography.*;
	import org.papervision3d.typography.fonts.HelveticaMedium;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	
	public class OneTurningPlugIn extends PlugIn
	{
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		
		// Text3D Mesh to render Text on Vehicles
		private var text3D1:Text3D;
		private var text3D2:Text3D;
		private var textFont:Font3D;
		private var textMat:Letter3DMaterial;
		
		private var oneTurning:OneTurning;
		private var theVehicle:Vector.<OneTurning>;				// for allVehicles
		
		public var pluginReset:Boolean;
				
		public function OneTurningPlugIn ()
		{
			super();
			theVehicle = new Vector.<OneTurning>();
		}

		public override  function get Name ():String
		{
			return "One Turning Away";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.06;
		}
		
		public function initPV3D():void
		{
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
	
			Demo.container.addChild(GridMesh);
			
			textMat = new Letter3DMaterial(0xffffff);
			textMat.doubleSided = true;
			textFont = new Font3D();
			text3D1 = new Text3D("", new HelveticaMedium, textMat);
			text3D2 = new Text3D("", new HelveticaMedium, textMat);
			text3D1.scale = text3D2.scale = 1;
			
			//Demo.container.addChild(text3D1);
			//Demo.container.addChild(text3D2);
		}

		public override  function Open ():void
		{
			initPV3D();
			pluginReset = true;
			
			oneTurning = new OneTurning();
			Demo.container.addChild(oneTurning.objectMesh);
			Demo.container.addChild(oneTurning.lines);
			
			Demo.SelectedVehicle=oneTurning;
			theVehicle.push(oneTurning);

			// initialize camera
			Demo.Init2dCamera (oneTurning);
			Demo.camera.SetPosition (10,Demo.Camera2dElevation,10);
			Demo.camera.FixedPosition=new Vector3(40,40,40);
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update simulation of test vehicle
			oneTurning.Update (currentTime,elapsedTime);
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// draw "ground plane"
			//Demo.GridUtility (oneTurning.Position,GridMesh);
			// We do  this because PV3D and AS3 are not Canvas based Drawers
			if(pluginReset)
			{				
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
				//Demo.GridUtility(gridCenter,GridMesh);
				Grid(oneTurning.Position);
				
				pluginReset = false;
			}

			// draw test vehicle
			oneTurning.Draw ();

			// textual annotation (following the test vehicle's screen position)
			var annote:String = "      speed: " + oneTurning.Speed;
			text3D1.text = annote;
			text3D1.position = oneTurning.Position.ToNumber3D();
			text3D2.text = "start";
			text3D2.position = Vector3.Zero.ToNumber3D();
			
			//Drawing.Draw2dTextAt3dLocation (annote, oneTurning.Position, Colors.Red);
			//Drawing.Draw2dTextAt3dLocation ("start",Vector3.Zero,Colors.Green);

			// update camera, tracking test vehicle
			Demo.UpdateCamera (currentTime,elapsedTime,oneTurning);
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
			//TODO: Remove scene object once the plugin closes
			destoryPV3DObject(GridMesh);
			
			destoryPV3DObject(oneTurning.objectMesh);
			destoryPV3DObject(oneTurning.lines);
			
			theVehicle.splice(0, theVehicle.length);
			oneTurning=null;
		}
		
		private function destoryPV3DObject(object:*):void 
		{
			Demo.container.removeChild(object);
			object.material.destroy();
			object = null;
		}

		public override  function Reset ():void
		{
			// reset vehicle
			oneTurning.Reset ();
			pluginReset = true;
		}

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(theVehicle);
			return vehicles;
		}
	}
}