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

package tabinda.demo.plugins.MultiplePursuit
{
	import tabinda.papersteer.*;
	
	public class MpPursuer extends MpBase
	{
		// constructor
		public function MpPursuer(w:MpWanderer)
		{
			wanderer = w;
			Reset();
		}

		// reset state
		public override function Reset():void
		{
			super.Reset();
			bodyColor = Colors.toHex(int(255.0 * 0.6), int(255.0 * 0.4), int(255.0 * 0.4)); // redish
			if (wanderer != null)
			{
				RandomizeStartingPositionAndHeading();
			}
		}

		// one simulation step
		public function Update(currentTime:Number, elapsedTime:Number):void
		{
			// when pursuer touches quarry ("wanderer"), reset its position
			var d:Number = Vector3.Distance(Position, wanderer.Position);
			var r:Number = Radius + wanderer.Radius;
			if (d < r)
			{
				Reset();
			}

			var maxTime:Number = 20; // xxx hard-to-justify value
			ApplySteeringForce(SteerForPursuit2(wanderer, maxTime), elapsedTime);

			// for annotation
			//trail.Record(currentTime, Position);
		}

		// reset position
		public function RandomizeStartingPositionAndHeading():void
		{
			// randomize position on a ring between inner and outer radii
			// centered around the home base
			const inner:Number = 20;
			const outer:Number = 30;
			var radius:Number = Utilities.random(inner, outer);
			var randomOnRing:Vector3 = Vector3.ScalarMultiplication(radius,VHelper.RandomUnitVectorOnXZPlane());
			Position = Vector3.VectorAddition(wanderer.Position , randomOnRing);

			// randomize 2D heading
			RandomizeHeadingOnXZPlane();
		}

		private var wanderer:MpWanderer;
	}
}
