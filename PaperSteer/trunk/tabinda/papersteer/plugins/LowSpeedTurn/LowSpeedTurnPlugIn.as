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


package tabinda.papersteer.plugins.LowSpeedTurn
{
	class LowSpeedTurnPlugIn extends PlugIn
	{
		const lstCount:int=5;
		const lstLookDownDistance:Number=18;
		static var lstViewCenter:Vector3=new Vector3(7,0,-2);
		static var lstPlusZ:Vector3=new Vector3(0,0,1);

		public function LowSpeedTurnPlugIn ()
		{
			super ();
			all=new Array  ;
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
				all.Add (new LowSpeedTurn  );
			}

			// initial selected vehicle
			Demo.SelectedVehicle=all[0];

			// initialize camera
			Demo.Camera.Mode=Camera.CameraMode.Fixed;
			Demo.Camera.FixedUp=lstPlusZ;
			Demo.Camera.FixedTarget=lstViewCenter;
			Demo.Camera.FixedPosition=lstViewCenter;
			Demo.Camera.FixedPosition.Y+= lstLookDownDistance;
			Demo.Camera.LookDownDistance=lstLookDownDistance;
			Demo.Camera.FixedDistanceVerticalOffset=Demo.Camera2dElevation;
			Demo.Camera.FixedDistanceDistance=Demo.CameraTargetDistance;
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update, draw and annotate each agent
			for (var i:int=0; i < all.Count; i++)
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
			Demo.GridUtility (selected.Position);

			// update, draw and annotate each agent
			for (var i:int=0; i < all.Count; i++)
			{
				// draw this agent
				var agent:LowSpeedTurn=all[i];
				agent.Draw ();

				// display speed near agent's screen position
				var textColor:Color=new Color(new Vector3(0.8,0.8,1.0));
				var textOffset:Vector3=new Vector3(0,0.25,0);
				var textPosition:Vector3=agent.Position + textOffset;
				var annote:String=String.Format("{0:0.00}",agent.Speed);
				Drawing.Draw2dTextAt3dLocation (annote,textPosition,textColor);
			}

			// highlight vehicle nearest mouse
			Demo.HighlightVehicleUtility (nearMouse);
		}

		public override  function Close ():void
		{
			all.Clear ();
		}

		public override  function Reset ():void
		{
			// reset each agent
			LowSpeedTurn.ResetStarts ();
			for (var i:int=0; i < all.Count; i++)
			{
				all[i].Reset ();
			}
		}

		public override  function get Vehicles ():Array
		{
			//get { return all.ConvertAll<IVehicle>(delegate(LowSpeedTurn v) { return (IVehicle)v; }); }
		}

		var all:Array;// for allVehicles
	}
}