// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// Copyright (C) 2007 Michael Coles <michael@digini.com>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/*using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;*/

package tabinda.papersteer.plugins.OneTurning
{
	public class OneTurningPlugIn extends PlugIn
	{
		public function OneTurningPlugIn ()
		{
			theVehicle=Array();
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
			oneTurning=new OneTurning  ;
			Demo.SelectedVehicle=oneTurning;
			theVehicle.Add (oneTurning);

			// initialize camera
			Demo.Init2dCamera (oneTurning);
			Demo.Camera.SetPosition (10,Demo.Camera2dElevation,10);
			Demo.Camera.FixedPosition=new Vector3(40);
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update simulation of test vehicle
			oneTurning.Update (currentTime,elapsedTime);
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// draw "ground plane"
			Demo.GridUtility (oneTurning.Position);

			// draw test vehicle
			oneTurning.Draw ();

			// textual annotation (following the test vehicle's screen position)
			var annote:String="      speed: {0:0.00}" + oneTurning.Speed;
			Drawing.Draw2dTextAt3dLocation (annote,oneTurning.Position,Color.Red);
			Drawing.Draw2dTextAt3dLocation ("start",Vector3.Zero,Color.Green);

			// update camera, tracking test vehicle
			Demo.UpdateCamera (currentTime,elapsedTime,oneTurning);
		}

		public override  function Close ():void
		{
			theVehicle.Clear ();
			oneTurning=null;
		}

		public override  function Reset ():void
		{
			// reset vehicle
			oneTurning.Reset ();
		}

		public override  function get Vehicles ():Array
		{
			//get { return theVehicle.ConvertAll<IVehicle>(delegate(OneTurning v) { return (IVehicle)v; }); }
		}

		var oneTurning:OneTurning;
		var theVehicle:Array;// for allVehicles
	}
}