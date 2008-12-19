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
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*
	
	public class LowSpeedTurn extends SimpleVehicle
	{
		public var LSTMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		
		var trail:Trail;
		
		// for stepping the starting conditions for next vehicle
		static var startX:Number;
		static var startSpeed:Number;
		
		// constructor
		public function LowSpeedTurn ():void
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			LSTMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(LSTMesh);
			
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			// reset vehicle state
			super.Reset ();

			// speed along Forward direction.
			Speed=startSpeed;

			// initial position along X axis
			SetPosition (startX,0,0);

			// steering force clip magnitude
			MaxForce=0.3;

			// velocity  clip magnitude
			MaxSpeed=1.5;

			// for next instance: step starting location
			startX+= 2.0;

			// for next instance: step speed
			startSpeed+= 0.15;

			// 15 seconds and 150 points along the trail
			trail=new Trail(15,150);
		}

		// draw into the scene
		public function Draw ():void
		{
			LSTMesh.geometry.vertices.splice(0);
			LSTMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle (this,LSTMesh,uvArr,Colors.Gray);
			trail.Draw (Annotation.drawer);
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			ApplySteeringForce (Steering,elapsedTime);

			// annotation
			annotation.VelocityAcceleration (this);
			trail.Record (currentTime,Position);
		}

		// reset starting positions
		public static  function ResetStarts ():void
		{
			startX=0.0;
			startSpeed=0.0;
		}

		// constant steering force
		public function get Steering ():Vector3
		{
			return new Vector3(1,0,-1);
		}
	}
}