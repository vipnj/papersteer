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
	import org.papervision3d.materials.special.Letter3DMaterial;
	import org.papervision3d.typography.Font3D;
	import org.papervision3d.typography.Text3D;
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	public class OneTurningPlugIn extends PlugIn
	{
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr1:Array;
		public var uvArr2:Array;
		
		// Text3D Mesh to render Text on Vehicles
		private var text3D1:Text3D;
		private var text3D2:Text3D;
		private var textFont:Font3D;
		private var textMat:Letter3DMaterial;
		
		private var oneTurning:OneTurning;
		private var theVehicle:Vector.<OneTurning>;				// for allVehicles
				
		public function OneTurningPlugIn ()
		{
			uvArr1 = new Array(new NumberUV(0, 0), new NumberUV(1, 1), new NumberUV(0, 1));
			uvArr2 = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(1, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			textMat = new Letter3DMaterial(0xffffff);
			textMat.doubleSided = true;
			textFont = new Font3D();
			text3D1 = new Text3D("", new Eurostile, textMat);
			text3D2 = new Text3D("", new Eurostile, textMat);
			text3D1.scale = text3D2.scale = 1;
			
			Demo.scene.addChild(text3D1);
			Demo.scene.addChild(text3D2);
			Demo.scene.addChild(GridMesh);
			
			theVehicle= new Vector.<OneTurning>();
		}

		public override  function get Name ():String
		{
			return "One Turning Away";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.06;
		}

		public override  function Open ():void
		{
			oneTurning=new OneTurning();
			Demo.SelectedVehicle=oneTurning;
			theVehicle.push(oneTurning);

			// initialize camera
			Demo.Init2dCamera (oneTurning);
			Demo.camera.SetPosition (10,Demo.Camera2dElevation,10);
			Demo.camera.FixedPosition=new Vector3(40);
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update simulation of test vehicle
			oneTurning.Update (currentTime,elapsedTime);
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// draw "ground plane"
			Demo.GridUtility (oneTurning.Position,GridMesh);

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

		public override  function Close ():void
		{
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);
			
			theVehicle.splice(0, theVehicle.length);
			oneTurning=null;
		}

		public override  function Reset ():void
		{
			// reset vehicle
			oneTurning.Reset ();
		}

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(theVehicle);
			return vehicles;
		}
	}
}