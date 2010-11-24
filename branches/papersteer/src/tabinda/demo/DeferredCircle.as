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

package tabinda.demo
{
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.materials.special.LineMaterial;
	
	import tabinda.papersteer.*;
	
	/**
	 * Deferred Buffer for drawing circles
	 * @author Mohammad Haseeb
	 * @see Drawing Routines in plugins
	 */
	public class DeferredCircle
	{		
		/* static block */
		{
			deferredCircleArray = new Vector.<DeferredCircle>(size);
			private static var i:int = 0;
			
			for (i = 0; i < size; i++)
			{
				deferredCircleArray[i] = new DeferredCircle();
			}
		}

		public static function AddToBuffer(object:*,radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int,filled:Boolean, in3d:Boolean):void
		{
			
			if (index < size)
			{
				deferredCircleArray[index].object = object;
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
				//trace("overflow in deferredDrawCircle buffer");
			}
		}

		public static function DrawAll():void
		{
			// draw all circles in the buffer
			for (var i:int = 0; i < index; i++)
			{
				var dc:DeferredCircle = deferredCircleArray[i];
				DrawCircleOrDisk(dc.object,dc.radius, dc.axis, dc.center, dc.color, dc.segments, dc.filled, dc.in3d);
			}

			// reset buffer index
			index = 0;
		}
		
		public static function DrawCircleOrDisk(object:*,radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void
		{
			var temp : Number3D = new Number3D(radius,0,0);
			var tempcurve:Number3D = new Number3D(0,0,0);
			var joinends : Boolean;
			var i:int;
			var pointcount : int;

			var angle:Number = (0-360)/segments;
			var curveangle : Number = angle/2;

			tempcurve.x = radius/Math.cos(curveangle * Number3D.toRADIANS);
			tempcurve.rotateY(curveangle+0);

			if(360-0<360)
			{
				joinends = false;
				pointcount = segments+1;
			}
		    else
			{
				joinends = true;
				pointcount = segments;
			}
		   
			temp.rotateY(0);

			var vertices:Array = new Array();
			var curvepoints:Array = new Array();

			for(i = 0; i< pointcount;i++)
			{
				vertices.push(new Vertex3D(center.x+temp.x, center.y+temp.y, center.z+temp.z));
				curvepoints.push(new Vertex3D(center.x+tempcurve.x, center.y+tempcurve.y, center.z+tempcurve.z));
				temp.rotateY(angle);
				tempcurve.rotateY(angle);
			}

			for(i = 0; i < segments ;i++)
			{
				var line:Line3D = new Line3D(object, new LineMaterial(color), 2, vertices[i], vertices[(i+1)%vertices.length]);	
				line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
				object.addLine(line);
			}
		}
		
		private var object:*;
		private var radius:Number;
		private var axis:Vector3;
		private var center:Vector3;
		private var color:uint;
		private var segments:int;
		private var filled:Boolean;
		private var in3d:Boolean;

		private static var index:int = 0;
		private static const size:int = 500;
		private static var deferredCircleArray:Vector.<DeferredCircle>;
	}
}
