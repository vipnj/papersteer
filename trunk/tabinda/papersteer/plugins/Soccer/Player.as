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
	public class Player extends SimpleVehicle
	{
		var trail:Trail;

		// constructor
		public function Player (others:Array,allplayers:Array,ball:Ball,isTeamA:Boolean,id:int)
		{
			m_others=others;
			m_AllPlayers=allplayers;
			m_Ball=ball;
			b_ImTeamA=isTeamA;
			m_MyID=id;

			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 
			Speed=0.0;// speed along Forward direction.
			MaxForce=3000.7;// steering force is clipped to this magnitude
			MaxSpeed=10;// velocity is clipped to this magnitude

			// Place me on my part of the field, looking at oponnents goal
			SetPosition (b_ImTeamA?Utilities.Random() * 20:- Utilities.Random() * 20,0,Utilities.Random() - 0.5 * 20);
			if (m_MyID < 9)
			{
				if (b_ImTeamA)
				{
					Position=Globals.PlayerPosition[m_MyID];
				}
				else
				{
					Position=new Vector3(- Globals.PlayerPosition[m_MyID].X,Globals.PlayerPosition[m_MyID].Y,Globals.PlayerPosition[m_MyID].Z);
				}
			}
			m_home=Position;

			if (trail == null)
			{
				trail=new Trail(10,60);
			}
			trail.Clear ();// prevent long streaks due to teleportation 
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// if I hit the ball, kick it.
			var distToBall:Number=Vector3.Distance(Position,m_Ball.Position);
			var sumOfRadii:Number=Radius + m_Ball.Radius;
			if (distToBall < sumOfRadii)
			{
				m_Ball.Kick (m_Ball.Position - Position * 50,elapsedTime);
			}

			// otherwise consider avoiding collisions with others
			var collisionAvoidance:Vector3=SteerToAvoidNeighbors(1,m_AllPlayers);
			if (collisionAvoidance != Vector3.Zero)
			{
				ApplySteeringForce (collisionAvoidance,elapsedTime);
			}
			else
			{
				var distHomeToBall:Number=Vector3.Distance(m_home,m_Ball.Position);
				if (distHomeToBall < 12)
				{
					// go for ball if I'm on the 'right' side of the ball
					if (b_ImTeamA?Position.X > m_Ball.Position.X:Position.X < m_Ball.Position.X)
					{
						var seekTarget:Vector3=xxxSteerForSeek(m_Ball.Position);
						ApplySteeringForce (seekTarget,elapsedTime);
					}
					else
					{
						if (distHomeToBall < 12)
						{
							var Z:Number=m_Ball.Position.Z - Position.Z > 0?-1.0:1.0;
							var behindBall:Vector3=m_Ball.Position + b_ImTeamA?new Vector3(2,0,Z):new Vector3(-2,0,Z);
							var behindBallForce:Vector3=xxxSteerForSeek(behindBall);
							annotation.Line (Position,behindBall,Color.Green);
							var evadeTarget:Vector3=xxxSteerForFlee(m_Ball.Position);
							ApplySteeringForce (behindBallForce * 10 + evadeTarget,elapsedTime);
						}
					}
				}
				else
				{
					var seekTarget:Vector3=xxxSteerForSeek(m_home);
					var seekHome:Vector3=xxxSteerForSeek(m_home);
					ApplySteeringForce (seekTarget + seekHome,elapsedTime);
				}

			}
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			Drawing.DrawBasic2dCircularVehicle (this,b_ImTeamA?Color.Red:Color.Blue);
			trail.Draw (Annotation.drawer);
		}

		// per-instance reference to its group
		var m_others:Array;
		var m_AllPlayers:Array;
		var m_Ball:Ball;
		var b_ImTeamA:Boolean;
		var m_MyID:int;
		var m_home:Vector3;
	}
}