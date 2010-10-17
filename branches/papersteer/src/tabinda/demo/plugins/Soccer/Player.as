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

package tabinda.demo.plugins.Soccer
{
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class Player extends SimpleVehicle
	{
		public var PlayerMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		public var triArr:Vector.<Triangle3D>;
		
		private var trail:Trail;

		// constructor
		public function Player (others:Vector.<Player>,allplayers:Vector.<Player>,ball:Ball,isTeamA:Boolean,id:int)
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			triArr = new Vector.<Triangle3D>(6);
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			PlayerMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(PlayerMesh);
			
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
			SetPosition (b_ImTeamA?Math.random() * 20:- Math.random() * 20,0,Math.random() - 0.5 * 20);
			if (m_MyID < 9)
			{
				if (b_ImTeamA)
				{
					Position=Globals.PlayerPosition[m_MyID];
				}
				else
				{
					Position=new Vector3(- Globals.PlayerPosition[m_MyID].x,Globals.PlayerPosition[m_MyID].y,Globals.PlayerPosition[m_MyID].z);
				}
			}
			m_home=Position;

			if (trail == null)
			{
				//trail=new Trail(10,60);
			}
			//trail.Clear ();// prevent long streaks due to teleportation 
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			// if I hit the ball, kick it.
			var distToBall:Number=Vector3.Distance(Position,m_Ball.Position);
			var sumOfRadii:Number=Radius + m_Ball.Radius;
			if (distToBall < sumOfRadii)
			{
				m_Ball.Kick (Vector3.VectorSubtraction(m_Ball.Position , Vector3.ScalarMultiplication(50,Position)),elapsedTime);
			}

			// otherwise consider avoiding collisions with others
			var collisionAvoidance:Vector3=SteerToAvoidNeighbors(1,Vector.<IVehicle>(m_AllPlayers));
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
					if (b_ImTeamA?Position.x > m_Ball.Position.x:Position.x < m_Ball.Position.x)
					{
						var seekTarget:Vector3=xxxSteerForSeek(m_Ball.Position);
						ApplySteeringForce (seekTarget,elapsedTime);
					}
					else
					{
						if (distHomeToBall < 12)
						{
							var Z:Number=m_Ball.Position.z - Position.z > 0?-1.0:1.0;
							var behindBall:Vector3=m_Ball.Position + b_ImTeamA?new Vector3(2,0,Z):new Vector3(-2,0,Z);
							var behindBallForce:Vector3=xxxSteerForSeek(behindBall);
							annotation.Line (Position,behindBall,Colors.Green);
							var evadeTarget:Vector3=xxxSteerForFlee(m_Ball.Position);
							ApplySteeringForce (Vector3.VectorAddition(Vector3.ScalarMultiplication(10,behindBallForce), evadeTarget),elapsedTime);
						}
					}
				}
				else
				{
					seekTarget=xxxSteerForSeek(m_home);
					var seekHome:Vector3=xxxSteerForSeek(m_home);
					ApplySteeringForce (Vector3.VectorAddition(seekTarget , seekHome),elapsedTime);
				}

			}
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			PlayerMesh.geometry.vertices.splice(0);
			PlayerMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle (this, PlayerMesh,triArr,uvArr, b_ImTeamA?Colors.Red:Colors.Blue);
			//trail.Draw (Annotation.drawer);
		}

		// per-instance reference to its group
		private var m_others:Vector.<Player>;
		private var m_AllPlayers:Vector.<Player>;
		private var m_Ball:Ball;
		private var b_ImTeamA:Boolean;
		private var m_MyID:int;
		private var m_home:Vector3;
	}
}