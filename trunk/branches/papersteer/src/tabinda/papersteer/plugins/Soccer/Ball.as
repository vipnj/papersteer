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
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class Ball extends SimpleVehicle
	{
		var trail:Trail;
		
		public var BallMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;

		public function Ball (bbox:AABBox)
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			BallMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			m_bbox=bbox;
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 
			Speed=0.0;// speed along Forward direction.
			MaxForce=9.0;// steering force is clipped to this magnitude
			MaxSpeed=9.0;// velocity is clipped to this magnitude

			SetPosition (0,0,0);
			if (trail == null)
			{
				trail=new Trail(100,6000);
			}
			trail.Clear ();// prevent long streaks due to teleportation 
		}

		// per frame simulation update
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			ApplyBrakingForce (1.5,elapsedTime);
			ApplySteeringForce (Velocity,elapsedTime);
			// are we now outside the field?
			if (! m_bbox.IsInsideX(Position))
			{
				var d:Vector3=Velocity;
				RegenerateOrthonormalBasis (new Vector3(- d.x,d.y,d.z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			if (! m_bbox.IsInsideZ(Position))
			{
				 d=Velocity;
				RegenerateOrthonormalBasis (new Vector3(d.x,d.y,- d.z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			trail.Record (currentTime,Position);
		}

		public function Kick (dir:Vector3,elapsedTime:Number):void
		{
			Speed=dir.Magnitude();
			RegenerateOrthonormalBasis (dir);
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			BallMesh.geometry.vertices.splice(0);
			BallMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle (this,BallMesh,uvArr,Colors.Green);
			trail.Draw (Annotation.drawer);
		}

		var m_bbox:AABBox;
	}
}