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
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	public class MpPlugIn extends PlugIn
	{
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr1:Array;
		public var uvArr2:Array;
		
		public function MpPlugIn ()
		{
			uvArr1 = new Array(new NumberUV(0, 0), new NumberUV(1, 1), new NumberUV(0, 1));
			uvArr2 = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(1, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(GridMesh);
			
			allMP=new Vector.<MpBase>();
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
			wanderer=new MpWanderer() ;
			allMP.push (wanderer);

			// create the specified number of pursuers, save pointers to them
			const pursuerCount:int=30;
			for (var i:int=0; i < pursuerCount; i++)
			{
				allMP.push (new MpPursuer(wanderer));
			}//pBegin = allMP.begin() + 1;  // iterator pointing to first pursuer
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
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// selected vehicle (user can mouse click to select another)
			var selected:IVehicle=Demo.SelectedVehicle;

			// vehicle nearest mouse (to be highlighted)
			var nearMouse:IVehicle=null;//Demo.vehicleNearestToMouse ();

			// update camera
			Demo.UpdateCamera (currentTime,elapsedTime,selected);

			// draw "ground plane"
			Demo.GridUtility (selected.Position,GridMesh);

			// draw each vehicles
			for (var i:int=0; i < allMP.length; i++)
			{
				allMP[i].Draw ();
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
			Demo.CircleHighlightVehicleUtility (selected);
		}

		public override  function Close ():void
		{
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);
			
			// delete wanderer, all pursuers, and clear list
			allMP.splice(0,allMP.length);
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