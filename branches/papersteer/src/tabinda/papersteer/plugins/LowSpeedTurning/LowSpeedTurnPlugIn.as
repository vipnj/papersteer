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

package tabinda.papersteer.plugins.LowSpeedTurning
{
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	public class LowSpeedTurnPlugIn extends PlugIn
	{
		const lstCount:int=5;
		const lstLookDownDistance:Number=18;
		static var lstViewCenter:Vector3=new Vector3(7,0,-2);
		static var lstPlusZ:Vector3 = new Vector3(0, 0, 1);
		var all:Vector.<LowSpeedTurn>;// for allVehicles
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr1:Array;
		public var uvArr2:Array;

		public function LowSpeedTurnPlugIn ()
		{
			uvArr1 = new Array(new NumberUV(0, 0), new NumberUV(1, 1), new NumberUV(0, 1));
			uvArr2 = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(1, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(GridMesh);
			
			super ();
			all=new Vector.<LowSpeedTurn>();
		}

		public override  function get Name ():String
		{
			return "Low Speed Turn";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.05;
		}

		public override  function Open ():void
		{
			// create a given number of agents with stepped inital parameters,
			// store pointers to them in an array.
			LowSpeedTurn.ResetStarts ();
			
			for (var i:int=0; i < lstCount; i++)
			{
				all.push (new LowSpeedTurn());
			}

			// initial selected vehicle
			Demo.SelectedVehicle=all[0];

			// initialize camera
			Demo.camera.Mode=CameraMode.Fixed;
			Demo.camera.FixedUp=lstPlusZ;
			Demo.camera.FixedTarget=lstViewCenter;
			Demo.camera.FixedPosition=lstViewCenter;
			Demo.camera.FixedPosition.y+= lstLookDownDistance;
			Demo.camera.LookDownDistance=lstLookDownDistance;
			Demo.camera.FixedDistanceVerticalOffset=Demo.Camera2dElevation;
			Demo.camera.FixedDistanceDistance=Demo.CameraTargetDistance;
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update, draw and annotate each agent
			for (var i:int=0; i < all.length; i++)
			{
				all[i].Update (currentTime,elapsedTime);
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

			// draw "ground plane"
			Demo.GridUtility (selected.Position,GridMesh,uvArr1,uvArr2);

			// update, draw and annotate each agent
			for (var i:int=0; i < all.length; i++)
			{
				// draw this agent
				var agent:LowSpeedTurn=all[i];
				agent.Draw ();

				// display speed near agent's screen position
				var textColor:uint=Colors.toHex(0.8,0.8,1.0);
				var textOffset:Vector3=new Vector3(0,0.25,0);
				var textPosition:Vector3=Vector3.VectorAddition(agent.Position , textOffset);
				var annote:String=String(agent.Speed);
				Drawing.Draw2dTextAt3dLocation (annote,textPosition,textColor);
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
		}

		public override  function Close ():void
		{
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);
			
			all.splice(0,all.length);
		}

		public override  function Reset ():void
		{
			// reset each agent
			LowSpeedTurn.ResetStarts ();
			for (var i:int=0; i < all.length; i++)
			{
				all[i].Reset ();
			}
		}

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			return all.map(function(v:LowSpeedTurn):IVehicle { return IVehicle(v); } );
			//get { return all.ConvertAll<IVehicle>(delegate(LowSpeedTurn v) { return (IVehicle)v; }); }
		}
	}
}