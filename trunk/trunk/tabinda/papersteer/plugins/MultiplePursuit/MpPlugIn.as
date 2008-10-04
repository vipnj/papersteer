// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/**using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework.Graphics;*/

package tabinda.papersteer.plugins.MultiplePursuit
{
	public class MpPlugIn extends PlugIn
	{
		public function MpPlugIn ()
		{
			allMP=new Array  ;
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
			wanderer=new MpWanderer  ;
			allMP.Add (wanderer);

			// create the specified number of pursuers, save pointers to them
			const pursuerCount:int=30;
			for (var i:int=0; i < pursuerCount; i++)
			{
				allMP.Add (new MpPursuer(wanderer));
			}//pBegin = allMP.begin() + 1;  // iterator pointing to first pursuer
			//pEnd = allMP.end();          // iterator pointing to last pursuer

			// initialize camera
			Demo.SelectedVehicle=wanderer;
			Demo.Camera.Mode=Camera.CameraMode.StraightDown;
			Demo.Camera.FixedDistanceDistance=Demo.CameraTargetDistance;
			Demo.Camera.FixedDistanceVerticalOffset=Demo.Camera2dElevation;
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update the wanderer
			wanderer.Update (currentTime,elapsedTime);

			// update each pursuer
			for (var i:int=1; i < allMP.Count; i++)
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
			Demo.GridUtility (selected.Position);

			// draw each vehicles
			for (var i:int=0; i < allMP.Count; i++)
			{
				allMP[i].Draw ();
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
			Demo.CircleHighlightVehicleUtility (selected);
		}

		public override  function Close ():void
		{
			// delete wanderer, all pursuers, and clear list
			allMP.Clear ();
		}

		public override  function Reset ():void
		{
			// reset wanderer and pursuers
			wanderer.Reset ();
			for (var i:int=1; i < allMP.Count; i++)
			{
				MpPursuer(allMP[i]).Reset ();
			}

			// immediately jump to default camera position
			Demo.Camera.DoNotSmoothNextMove ();
			Demo.Camera.ResetLocalSpace ();
		}

		//const AVGroup& allVehicles () {return (const AVGroup&) allMP;}
		public override  function get Vehicles ():Array
		{
			//get { return allMP.ConvertAll<IVehicle>(delegate(MpBase m) { return (IVehicle)m; }); }
		}

		// a group (STL vector) of all vehicles
		var allMP:Array;

		var wanderer:MpWanderer;
	}
}