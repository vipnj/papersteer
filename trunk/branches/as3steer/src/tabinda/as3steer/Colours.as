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

package tabinda.as3steer
{
	/**
	 * A generic color class in forms of red,green, blue values
	 */
	class Colours
	{
		public static  var gBlack:Vector3=new Vector3(0,0,0);
		public static  var gWhite:Vector3=new Vector3(1,1,1);
		public static  var gRed:Vector3=new Vector3(1,0,0);
		public static  var gYellow:Vector3=new Vector3(1,1,0);
		public static  var gGreen:Vector3=new Vector3(0,1,0);
		public static  var gCyan:Vector3=new Vector3(0,1,1);
		public static  var gBlue:Vector3=new Vector3(0,0,1);
		public static  var gMagenta:Vector3=new Vector3(1,0,1);
		public static  var gOrange:Vector3=new Vector3(1,0.5,0);

		public static function grayColor(g:Number):Vector3
		{
			return new Vector3(g,g,g);
		}

		public static  var gGray10:Vector3=grayColor(0.1);
		public static  var gGray20:Vector3=grayColor(0.2);
		public static  var gGray30:Vector3=grayColor(0.3);
		public static  var gGray40:Vector3=grayColor(0.4);
		public static  var gGray50:Vector3=grayColor(0.5);
		public static  var gGray60:Vector3=grayColor(0.6);
		public static  var gGray70:Vector3=grayColor(0.7);
		public static  var gGray80:Vector3=grayColor(0.8);
		public static  var gGray90:Vector3=grayColor(0.9);
	}
}