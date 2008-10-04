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
	public class MpPursuer extends MpBase
	{
		// constructor
		public function MpPursuer(w:MpWanderer)
		{
			wanderer = w;
			Reset();
		}

		// reset state
		public override function Reset():void
		{
			super.Reset();
			bodyColor = new Color(int(255.0 * 0.6), int(255.0 * 0.4), int(255.0 * 0.4)); // redish
			if(wanderer != null) RandomizeStartingPositionAndHeading();
		}

		// one simulation step
		public function Update(currentTime:Number, elapsedTime:Number):void
		{
			// when pursuer touches quarry ("wanderer"), reset its position
			var d:Number = Vector3.Distance(Position, wanderer.Position);
			var r:Number = Radius + wanderer.Radius;
			if (d < r) Reset();

			const maxTime:Number = 20; // xxx hard-to-justify value
			ApplySteeringForce(SteerForPursuit(wanderer, maxTime), elapsedTime);

			// for annotation
			trail.Record(currentTime, Position);
		}

		// reset position
		public function RandomizeStartingPositionAndHeading():void
		{
			// randomize position on a ring between inner and outer radii
			// centered around the home base
			const inner:Number = 20;
			const outer:Number = 30;
			var radius:Number = Utilities.Random(inner, outer);
			var randomOnRing:Vector3 = Vector3Helpers.RandomUnitVectorOnXZPlane() * radius;
			Position = (wanderer.Position + randomOnRing);

			// randomize 2D heading
			RandomizeHeadingOnXZPlane();
		}

		 var wanderer:MpWanderer;
	}
}
