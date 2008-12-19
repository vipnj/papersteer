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

package tabinda.papersteer.plugins.Soccer
{
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	public class SoccerPlugIn extends PlugIn
	{
		var teamA:Vector.<Player>;
		var teamB:Vector.<Player>;
		var allPlayers:Vector.<Player>;

		var ball:Ball;
		var bbox:AABBox;
		var teamAGoal:AABBox;
		var teamBGoal:AABBox;
		var redScore:int;
		var blueScore:int;
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr1:Array;
		public var uvArr2:Array;
		
		public function SoccerPlugIn()
		{
			uvArr1 = new Array(new NumberUV(0, 0), new NumberUV(1, 1), new NumberUV(0, 1));
			uvArr2 = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(1, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(GridMesh);
			
			teamA = new Vector.<Player>();
			teamB = new Vector.<Player>();
			allPlayers = new Vector.<Player>();
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
				teamA.push(pMicTest);
				allPlayers.push(pMicTest);
			}
			// Build Team B
			const  PlayerCountB:int = 8;
			for (i = 0; i < PlayerCountB; i++)
			{
				pMicTest = new Player(teamB, allPlayers, ball, false, i);
				Demo.SelectedVehicle = pMicTest;
				teamB.push(pMicTest);
				allPlayers.push(pMicTest);
			}
			// initialize camera
			Demo.Init2dCamera(ball);
			Demo.camera.SetPosition(10, Demo.Camera2dElevation, 10);
			Demo.camera.FixedPosition = new Vector3(40);
			Demo.camera.Mode = CameraMode.Fixed;
			redScore = 0;
			blueScore = 0;
		}

		public override function Update(currentTime:Number, elapsedTime:Number):void
		{
			// update simulation of test vehicle
			for (var i:int = 0; i < teamA.length; i++)
			{
				teamA[i].Update(currentTime, elapsedTime);
			}
			for (i = 0; i < teamB.length; i++)
			{
				teamB[i].Update(currentTime, elapsedTime);
			}
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
			Demo.GridUtility(Vector3.Zero,GridMesh,uvArr1,uvArr2);

			// draw test vehicle
			for (var i:int = 0; i < teamA.length; i++)
			{
				teamA[i].Draw();
			}
			for (i = 0; i < teamB.length; i++)
			{
				teamB[i].Draw();
			}
			ball.Draw();
			bbox.Draw();
			teamAGoal.Draw();
			teamBGoal.Draw();

			var annote:String = new String();
			annote +="Red: "+redScore;
			//Drawing.Draw2dTextAt3dLocation(annote.ToString(), new Vector3(23, 0, 0), new Color((byte)(255.0 * 1), (byte)(255.0f * 0.7), (byte)(255.0f * 0.7f)));

			annote = new String();
			annote +="Blue: "+blueScore;
			//Drawing.Draw2dTextAt3dLocation(annote.ToString(), new Vector3(-23, 0, 0), new Color((byte)(255.0f * 0.7f), (byte)(255.0f * 0.7f), (byte)(255.0f * 1)));

			// update camera, tracking test vehicle
			Demo.UpdateCamera(currentTime, elapsedTime, Demo.SelectedVehicle);
		}

		public override function Close():void
		{
			//TODO: Remove scene object once the plugin closes
			//Demo.scene.objects.splice(0);
			
			teamA.splice(0,teamA.length);
			teamB.splice(0,teamB.length);
			allPlayers.splice(0,allPlayers.length);
		}

		public override function Reset():void
		{
			// reset vehicle
			for (var i:int = 0; i < teamA.length; i++)
			{
					teamA[i].Reset();
			}
			for (i = 0; i < teamB.length; i++)
			{
				teamB[i].Reset();
			}
			ball.Reset();
		}

		//const AVGroup& allVehicles () {return (const AVGroup&) TeamA;}
		public override function get Vehicles():Vector.<IVehicle>
		{
			return teamA.map(function(p:Player):IVehicle { return IVehicle(p); } );
		}
	}
}
