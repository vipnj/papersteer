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
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;*/

package tabinda.papersteer.plugins.MultiplePursuit
{
	public class MpWanderer extends MpBase
	{
		// constructor
		public function MpWanderer ()
		{
			Reset ();
		}

		// reset state
		public override  function Reset ():void
		{
			super.Reset ();
			bodyColor=new Color(int(255.0 * 0.4),int(255.0 * 0.6),int(255.0 * 0.4));// greenish
		}

		// one simulation step
		public function Update (currentTime:Number,elapsedTime:Number):void
		{
			var wander2d:Vector3=SteerForWander(elapsedTime);
			wander2d.Y=0;

			var steer:Vector3=Forward + wander2d * 3;
			ApplySteeringForce (steer,elapsedTime);

			// for annotation
			trail.Record (currentTime,Position);
		}
	}
}