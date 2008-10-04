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
	public class Ball extends SimpleVehicle
	{
		var trail:Trail;

		public function Ball (bbox:AABBox)
		{
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
				RegenerateOrthonormalBasis (new Vector3(- d.X,d.Y,d.Z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			if (! m_bbox.IsInsideZ(Position))
			{
				var d:Vector3=Velocity;
				RegenerateOrthonormalBasis (new Vector3(d.X,d.Y,- d.Z));
				ApplySteeringForce (Velocity,elapsedTime);
			}
			trail.Record (currentTime,Position);
		}

		public function Kick (dir:Vector3,elapsedTime:Number):void
		{
			Speed=dir.Length();
			RegenerateOrthonormalBasis (dir);
		}

		// draw this character/vehicle into the scene
		public function Draw ():void
		{
			Drawing.DrawBasic2dCircularVehicle (this,Color.Green);
			trail.Draw (Annotation.drawer);
		}

		var m_bbox:AABBox;
	}
}