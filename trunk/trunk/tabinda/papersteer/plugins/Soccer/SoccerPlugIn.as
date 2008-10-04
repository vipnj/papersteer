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
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;*/

package tabinda.papersteer.plugins.Soccer
{
	public class SoccerPlugIn extends PlugIn
	{
		public function SoccerPlugIn()
		{
			teamA = new Array;
			teamB = new Array();
			allPlayers = new Array();
		}

		public override function get Name():String { return "Michael's Simple Soccer"; }

		public override function Open():void
		{
			// Make a field
			bbox = new AABBox(new Vector3(-20, 0, -10), new Vector3(20, 0, 10));
			// Red goal
			teamAGoal = new AABBox(new Vector3(-21, 0, -7), new Vector3(-19, 0, 7));
			// Blue Goal
			teamBGoal = new AABBox(new Vector3(19, 0, -7), new Vector3(21, 0, 7));
			// Make a ball
			ball = new Ball(bbox);
			// Build team A
			const PlayerCountA:int = 8;
			for (var i:int = 0; i < PlayerCountA; i++)
			{
				var pMicTest:Player = new Player(teamA, allPlayers, ball, true, i);
				Demo.SelectedVehicle = pMicTest;
				teamA.Add(pMicTest);
				allPlayers.Add(pMicTest);
			}
			// Build Team B
			const  PlayerCountB:int = 8;
			for (var i:int = 0; i < PlayerCountB; i++)
			{
				var pMicTest:Player = new Player(teamB, allPlayers, ball, false, i);
				Demo.SelectedVehicle = pMicTest;
				teamB.Add(pMicTest);
				allPlayers.Add(pMicTest);
			}
			// initialize camera
			Demo.Init2dCamera(ball);
			Demo.Camera.SetPosition(10, Demo.Camera2dElevation, 10);
			Demo.Camera.FixedPosition = new Vector3(40);
			Demo.Camera.Mode = Camera.CameraMode.Fixed;
			redScore = 0;
			blueScore = 0;
		}

		public override function Update(currentTime:Number, elapsedTime:Number):void
		{
			// update simulation of test vehicle
			for (var i:int = 0; i < teamA.Count; i++)
				teamA[i].Update(currentTime, elapsedTime);
			for (i = 0; i < teamB.Count; i++)
				teamB[i].Update(currentTime, elapsedTime);
			ball.Update(currentTime, elapsedTime);

			if (teamAGoal.IsInsideX(ball.Position) && teamAGoal.IsInsideZ(ball.Position))
			{
				ball.Reset();	// Ball in blue teams goal, red scores
				redScore++;
			}
			if (teamBGoal.IsInsideX(ball.Position) && teamBGoal.IsInsideZ(ball.Position))
			{
				ball.Reset();	// Ball in red teams goal, blue scores
				blueScore++;
			}
		}

		public override function Redraw(currentTime:Number, elapsedTime:Number):void
		{
			// draw "ground plane"
			Demo.GridUtility(Vector3.Zero);

			// draw test vehicle
			for (var i:int = 0; i < teamA.Count; i++)
				teamA[i].Draw();
			for (i = 0; i < teamB.Count; i++)
				teamB[i].Draw();
			ball.Draw();
			bbox.Draw();
			teamAGoal.Draw();
			teamBGoal.Draw();

			var annote:StringBuilder = new StringBuilder();
			annote.AppendFormat("Red: {0}", redScore);
			//Drawing.Draw2dTextAt3dLocation(annote.ToString(), new Vector3(23, 0, 0), new Color((byte)(255.0 * 1), (byte)(255.0f * 0.7), (byte)(255.0f * 0.7f)));

			annote = new StringBuilder();
			annote.AppendFormat("Blue: {0}", blueScore);
			//Drawing.Draw2dTextAt3dLocation(annote.ToString(), new Vector3(-23, 0, 0), new Color((byte)(255.0f * 0.7f), (byte)(255.0f * 0.7f), (byte)(255.0f * 1)));

			// textual annotation (following the test vehicle's screen position)
/*#if IGNORED
			for (int i = 0; i < TeamA.Count; i++)
			{
				String anno = String.Format("      speed: {0:0.00} ID: {1} ", TeamA[i].speed(), i);
				Drawing.Draw2dTextAt3dLocation(anno, TeamA[i].position(), Color.Red);
			}
			Drawing.Draw2dTextAt3dLocation("start", Vector3.zero, Color.Green);
#endif*/
			// update camera, tracking test vehicle
			Demo.UpdateCamera(currentTime, elapsedTime, Demo.SelectedVehicle);
		}

		public override function Close():void
		{
			teamA.Clear();
			teamB.Clear();
			allPlayers.Clear();
		}

		public override function Reset():void
		{
			// reset vehicle
			for (var i:int = 0; i < teamA.Count; i++)
				teamA[i].Reset();
			for (i = 0; i < teamB.Count; i++)
				teamB[i].Reset();
			ball.Reset();
		}

		//const AVGroup& allVehicles () {return (const AVGroup&) TeamA;}
		public override function get Vehicles():Array
		{
			//get { return teamA.ConvertAll<IVehicle>(delegate(Player p) { return (IVehicle)p; }); }
		}

		var teamA:Array;
		var teamB:Array;
		var allPlayers:Array;

		var ball:Ball;
		var bboxAABBox;
		var teamAGoalAABBox;
		var teamBGoalAABBox;
		var redScore:int;
		var blueScore:int;
	}
}
