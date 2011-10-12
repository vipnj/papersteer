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

package tabinda.papersteer
{
	// xxx cwr 9-6-02 temporary to support old code
	public class PathIntersection
	{
		public var intersect:Boolean;
		public var distance:Number;
		public var surfacePoint:Vector3;
		public var surfaceNormal:Vector3;
		public var obstacle:SphericalObstacle;
		
		public function PathIntersection(_intersect:Boolean=false,_distance:Number=0,_surfacePoint:Vector3=null,_surfaceNormal:Vector3=null,_obstacle:SphericalObstacle=null):void
		{
			intersect = _intersect;
			distance = _distance;
			if (_surfacePoint == null) 
				surfacePoint = new Vector3(0, 0, 0);
			else 
				surfacePoint = _surfacePoint;
				
			if (_surfaceNormal == null) 
				surfaceNormal = new Vector3(0, 0, 0);
			else 
				surfaceNormal = _surfaceNormal;
			
			if (_obstacle == null) 
				obstacle = new SphericalObstacle();
			else 
				obstacle = _obstacle;	
		}
	}
}