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
	public class AABBox
	{
		public function AABBox (min:Vector3,max:Vector3)
		{
			m_min=min;
			m_max=max;
		}
		public function IsInsideX (p:Vector3):Boolean
		{
			return ! p.X < m_min.X || p.X > m_max.X;
		}
		public function IsInsideZ (p:Vector3):Vector3
		{
			return ! p.Z < m_min.Z || p.Z > m_max.Z;
		}
		public function Draw ():void
		{
			var b:Vector3=new Vector3(m_min.X,0,m_max.Z);
			var c:Vector3=new Vector3(m_max.X,0,m_min.Z);
			var color:Color=new Color(255,255,0);
			Drawing.DrawLineAlpha (m_min,b,color,1.0);
			Drawing.DrawLineAlpha (b,m_max,color,1.0);
			Drawing.DrawLineAlpha (m_max,c,color,1.0);
			Drawing.DrawLineAlpha (c,m_min,color,1.0);
		}

		var m_min:Vector3;
		var m_max:Vector3;
	}
}