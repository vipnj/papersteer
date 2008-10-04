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
	import flash.ui.Keyboard;
	
	public interface IPlugIn
	{
		// generic PlugIn actions: open, update, redraw, close and reset
		function Open ():void;
		function Update (currentTime:Number, elapsedTime:Number):void;
		function Redraw (currentTime:Number, elapsedTime:Number):void;
		function Close ():void;
		function Reset ():void;

		// return a pointer to this instance's character string name
		function get Name ():String;

		// numeric sort key used to establish user-visible PlugIn ordering
		// ("built ins" have keys greater than 0 and less than 1)
		function get SelectionOrderSortKey ():Number;

		// allows a PlugIn to nominate itself as OpenSteerDemo's initially selected
		// (default) PlugIn, which is otherwise the first in "selection order"
		function get RequestInitialSelection ():Boolean;

		// handle function keys (which are reserved by SterTest for PlugIns)
		function HandleFunctionKeys (key:Keyboard):void;

		// print "mini help" documenting function keys handled by this PlugIn
		function PrintMiniHelpForFunctionKeys ():void;

		// return an AVGroup (an STL vector of AbstractVehicle pointers) of
		// all vehicles(/agents/characters) defined by the PlugIn
		/*List<IVehicle> Vehicles { get; }*/
		function get Vehicles ():Array;
	}
}