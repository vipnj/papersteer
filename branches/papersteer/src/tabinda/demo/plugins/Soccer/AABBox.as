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

package tabinda.demo.plugins.Soccer
{
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class AABBox
	{
		public function AABBox (min:Vector3,max:Vector3)
		{
			m_min=min;
			m_max=max;
		}
		public function IsInsideX (p:Vector3):Boolean
		{
			return ! p.x < m_min.x || p.x > m_max.x;
		}
		public function IsInsideZ (p:Vector3):Boolean
		{
			return ! p.z < m_min.z || p.z > m_max.z;
		}
		public function Draw ():void
		{
			var b:Vector3=new Vector3(m_min.x,0,m_max.z);
			var c:Vector3=new Vector3(m_max.x,0,m_min.z);
			var color:uint=Colors.toHex(255,255,0);
			Drawing.DrawLineAlpha (m_min,b,color,1.0);
			Drawing.DrawLineAlpha (b,m_max,color,1.0);
			Drawing.DrawLineAlpha (m_max,c,color,1.0);
			Drawing.DrawLineAlpha (c,m_min,color,1.0);
		}

		private var m_min:Vector3;
		private var m_max:Vector3;
	}
}