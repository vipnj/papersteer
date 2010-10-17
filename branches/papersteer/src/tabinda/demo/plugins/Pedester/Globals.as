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

package tabinda.demo.plugins.Pedester
{
	import tabinda.papersteer.*;

	public class Globals
	{
		// create path for PlugIn 
		//
		//
		//        | gap |
		//
		//        f      b
		//        |\    /\        -
		//        | \  /  \       ^
		//        |  \/    \      |
		//        |  /\     \     |
		//        | /  \     c   top
		//        |/    \g  /     |
		//        /        /      |
		//       /|       /       V      z     y=0
		//      / |______/        -      ^
		//     /  e      d               |
		//   a/                          |
		//    |<---out-->|               o----> x
		//
		public static function GetTestPath():PolylinePathway
		{
			if (TestPath == null)
			{
				const pathRadius:Number = 2;

				const pathPointCount:int = 7;
				const size:Number = 30;
				var top:Number = 2 * size;
				var gap:Number = 1.2 * size;
				var outter:Number = 2 * size;
				var h:Number = 0.5;
				var pathPoints:Vector.<Vector3> = new Vector.<Vector3>(pathPointCount);
				pathPoints[0] = new Vector3 (h + gap - outter,  0,  h + top - outter); // 0 a
				pathPoints[1] = new Vector3 (h + gap, 0,  h + top);        			// 1 b
				pathPoints[2] = new Vector3 (h + gap + (top/2), 0, h+top/2);      		// 2 c
				pathPoints[3] = new Vector3 (h + gap, 0, h);            				// 3 d
				pathPoints[4] = new Vector3 (h, 0, h);            						// 4 e
				pathPoints[5] = new Vector3 (h,0,h + top);        						// 5 f
				pathPoints[6] = new Vector3 (h + gap,0,  h + top/2);      				// 6 g
					
				Obstacle1.Center = Utilities.Interpolate2(0.2, pathPoints[0], pathPoints[1]);
				Obstacle2.Center = Utilities.Interpolate2(0.5, pathPoints[2], pathPoints[3]);
				Obstacle1.Radius = 3;
				Obstacle2.Radius = 5;
				Obstacles.push(Obstacle1);
				Obstacles.push(Obstacle2);

				Endpoint0 = pathPoints[0];
				Endpoint1 = pathPoints[pathPointCount - 1];

				TestPath = new PolylinePathway(pathPointCount,
												 pathPoints,
												 pathRadius,
												 false);
			}
			return TestPath;
		}

		public static var TestPath:PolylinePathway = null;
		public static var Obstacle1:SphericalObstacle = new SphericalObstacle();
		public static var Obstacle2:SphericalObstacle = new SphericalObstacle();
		public static var Obstacles:Vector.<IObstacle> = new Vector.<IObstacle>();
		public static var Endpoint0:Vector3 = Vector3.Zero;
		public static var Endpoint1:Vector3 = Vector3.Zero;
		public static var UseDirectedPathFollowing:Boolean = true;

		// this was added for debugging tool, but I might as well leave it in
		public static var WanderSwitch:Boolean = true;
	}
}
