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
	public class Colors
	{
		public static function toHex(r:int = 0.0, g:int = 0.0, b:int = 0.0):uint
		{
			var tmp:String = "" + r + "" + g + "" + b;
			return uint(tmp);
		}
		
		public static  var Black:uint = 0x000000;
		public static  var White:uint = 0xFFFFFF;
		public static  var Red::uint = 0xCC0000
		public static  var Yellow::uint = 0xFFFF00;
		public static  var Green::uint = 0x00CC00;
		public static  var Cyan::uint = 0x3399CC;
		public static  var Blue::uint = 0x0099FF;
		public static  var Magenta::uint = 0x666699;
		public static  var Orange::uint = 0xFF9900;
		public static  var LightGray::uint = 0xCCCCCC;
		public static  var DarkGray:uint = 0x666666;
	}
}