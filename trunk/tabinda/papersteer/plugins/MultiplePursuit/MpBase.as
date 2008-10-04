// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/*using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework.Graphics;*/

package tabinda.papersteer.plugins.MultiplePursuit
{
	public class MpBase extends SimpleVehicle
	{
		protected var trail:Trail;

		// constructor
		public function MpBase ()
		{
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();// reset the vehicle 

			Speed=0;// speed along Forward direction.
			MaxForce=5.0;// steering force is clipped to this magnitude
			MaxSpeed=3.0;// velocity is clipped to this magnitude
			trail=new Trail  ;
			trail.Clear ();// prevent long streaks due to teleportation 
			GaudyPursuitAnnotation=true;// select use of 9-color annotation
		}

		// draw into the scene
		public function Draw ():void
		{
			Drawing.DrawBasic2dCircularVehicle (this,bodyColor);
			trail.Draw (Annotation.drawer);
		}

		// for draw method
		protected var bodyColor:Color;
	}
}