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
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;*/

package tabinda.demo
{
	public class DeferredCircle
	{
		public static function DeferredCircle()
		{
			deferredCircleArray = new Array(size);
			for (var i:int = 0; i < size; i++)
			{
				deferredCircleArray[i] = new DeferredCircle();
			}
		}

		public static function AddToBuffer(radius:Number, axis:Vector3, center:Vector3, color:Color, segments:int,filled:Boolean, in3d:Boolean):void
		{
			if (index < size)
			{
				deferredCircleArray[index].radius = radius;
				deferredCircleArray[index].axis = axis;
				deferredCircleArray[index].center = center;
				deferredCircleArray[index].color = color;
				deferredCircleArray[index].segments = segments;
				deferredCircleArray[index].filled = filled;
				deferredCircleArray[index].in3d = in3d;
				index++;
			}
			else
			{
				trace("overflow in deferredDrawCircle buffer");
			}
		}

		public static function DrawAll():void
		{
			// draw all circles in the buffer
			for (var i:int = 0; i < index; i++)
			{
				var dc:DeferredCircle = deferredCircleArray[i];
				Drawing.DrawCircleOrDisk(dc.radius, dc.axis, dc.center, dc.color, dc.segments, dc.filled, dc.in3d);
			}

			// reset buffer index
			index = 0;
		}

		var radius:Number;
		var axis:Vector3;
		var center:Vector3;
		var color:Color;
		var segments:int;
		var filled:Boolean;
		var in3d:Boolean;

		static var index:int = 0;
		const size:int = 500;
		static var deferredCircleArray:Array;
	}
}
