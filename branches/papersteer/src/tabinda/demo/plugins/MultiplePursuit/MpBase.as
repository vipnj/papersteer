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

package tabinda.demo.plugins.MultiplePursuit
{
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class MpBase extends SimpleVehicle
	{
		protected var trail:Trail;
		
		public var MapMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		public var triArr:Vector.<Triangle3D>;
		
		// constructor
		public function MpBase ()
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			triArr = new Vector.<Triangle3D>(6);
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			MapMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(MapMesh);
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 

			Speed=0;// speed along Forward direction.
			MaxForce=5.0;// steering force is clipped to this magnitude
			MaxSpeed=3.0;// velocity is clipped to this magnitude
			//trail=new Trail();
			//trail.Clear ();// prevent long streaks due to teleportation 
			GaudyPursuitAnnotation=true;// select use of 9-color annotation
		}

		// draw into the scene
		public function Draw ():void
		{
			MapMesh.geometry.vertices.splice(0);
			MapMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle (this,MapMesh,triArr,uvArr,bodyColor);
			//trail.Draw (Annotation.drawer);
		}

		// for draw method
		protected var bodyColor:uint;
	}
}