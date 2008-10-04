// ----------------------------------------------------------------------------
//
// OpenSteer - Action Script 3 Port
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
	// camera mode selection
	public class CameraMode
	{
		// marks beginning of list
		public static const StartMode:String="StartMode";

		// fixed global position and aimpoint
		public static const Fixed:String="Fixed";

		// camera position is directly above (in global Up/Y) target
		// camera up direction is target's forward direction
		public static const StraightDown:String="StraightDown";

		// look at subject vehicle, adjusting camera position to be a
		// constant distance from the subject
		public static const FixedDistanceOffset:String="FixedDistanceOffset";

		// camera looks at subject vehicle from a fixed offset in the
		// local space of the vehicle (as if attached to the vehicle)
		public static const FixedLocalOffset:String="FixedLocalOffset";

		// camera looks in the vehicle's forward direction, camera
		// position has a fixed local offset from the vehicle.
		public static const OffsetPOV:String="OffsetPOV";

		// cmFixedPositionTracking // xxx maybe?

		// marks the end of the list for cycling (to cmStartMode+1)
		public static const EndMode:String="EndMode";
	}
}