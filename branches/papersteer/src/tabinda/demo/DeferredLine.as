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
	import org.papervision3d.core.geom.Lines3D;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.materials.special.LineMaterial;
	
	import tabinda.papersteer.*;
	
	/**
	 * Deferred Buffer for drawing circles
	 * @author Mohammad Haseeb
	 * @see Demo
	 */
		
	public class DeferredLine
	{		
		/* static block */
		{
			deferredLineArray = new Vector.<DeferredLine>(size);
			private static var i:int = 0;
			for (i = 0; i < size; i++)
			{
				deferredLineArray[i] = new DeferredLine();
			}
		}
			
		public static function AddToBuffer(drawer:Lines3D,s:Vector3, e:Vector3, c:uint):void
		{
			if (index < size)
			{
				deferredLineArray[index].drawer = drawer;
				deferredLineArray[index].startPoint = s;
				deferredLineArray[index].endPoint = e;
				deferredLineArray[index].color = c;
				index++;
			}
			else
			{
				//trace("overflow in deferredDrawLine buffer");
			}
		}

		public static function DrawAll():void
		{
			// draw all lines in the buffer
			for (var i:int = 0; i < index; i++)
			{
				var dl:DeferredLine = deferredLineArray[i];
				DrawLine(dl.drawer,dl.startPoint, dl.endPoint, dl.color);
			}

			// reset buffer index
			index = 0;
		}
		
		public static function DrawLine(drawer:Lines3D,startPoint:Vector3,endPoint:Vector3,color:uint):void
		{
			drawer.addLine(new Line3D(drawer, new LineMaterial(color,1),1,startPoint.ToVertex3D(),endPoint.ToVertex3D()));
		}
		
		private var startPoint:Vector3;
		private var endPoint:Vector3;
		private var color:uint;
		private var drawer:Lines3D;
		
		private static var index:int = 0;
		private static const size:int = 3000;
		private static var deferredLineArray:Vector.<DeferredLine>;
	}
}