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
	public interface IVehicle extends ILocalSpace
	{	
		// mass (defaults to unity so acceleration=force)
		function get Mass ():Number;
		function set Mass (mass:Number):void;

		// size of bounding sphere, for obstacle avoidance, etc.
		function get Radius ():Number;
		function set Radius (radius:Number):void;

		// velocity of vehicle
		function get Velocity ():Vector3;

		/**
		 * Gets the acceleration of the vehicle
		 * @return Vector3
		 */
		function get Acceleration ():Vector3;

		// speed of vehicle (may be faster than taking magnitude of velocity)
		function get Speed ():Number;
		function set Speed (speed:Number):void;

		// predict position of this vehicle at some time in the future
		//(assumes velocity remains constant)
		function PredictFuturePosition (predictionTime:Number):Vector3;

		// ----------------------------------------------------------------------
		// XXX this vehicle-model-specific functionality seems out
		// XXX of place on the abstract base class, but for now it is expedient

		// the maximum steering force this vehicle can apply
		function get MaxForce ():Number;
		function set MaxForce (maxforce:Number):void;

		// the maximum speed this vehicle is allowed to move
		function get MaxSpeed ():Number;
		function set MaxSpeed (maxspeed:Number):void;
	}
}