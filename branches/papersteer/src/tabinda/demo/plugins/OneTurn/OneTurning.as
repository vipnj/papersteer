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

package tabinda.demo.plugins.OneTurn
{
	import flash.display.TriangleCulling;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class OneTurning extends SimpleVehicle
	{
		public var OneMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		public var triArr:Vector.<Triangle3D>;
		
		private var trail:Trail;

		// constructor
		public function OneTurning ()
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			triArr = new Vector.<Triangle3D>(6);
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			OneMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(OneMesh);
			
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 
			Speed=1.5;// speed along Forward direction.
			MaxForce=0.3;// steering force is clipped to this magnitude
			MaxSpeed=5;// velocity is clipped to this magnitude
			//trail=new Trail();
			//trail.Clear ();// prevent long streaks due to teleportation 
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			ApplySteeringForce (new Vector3(-2,0,-3),elapsedTime);
			annotation.VelocityAcceleration (this);
			//trail.Record (currentTime,Position);
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			OneMesh.geometry.vertices.splice(0);
			OneMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle (this,OneMesh,triArr,uvArr,Colors.Gray);
			//trail.Draw (Annotation.drawer);
		}
	}
}