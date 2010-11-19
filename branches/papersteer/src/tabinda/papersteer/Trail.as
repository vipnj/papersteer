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
	import flash.display.Sprite;
	
	/**
	 * Provides support to visualize the recent path of a vehicle.
	 */
	public class Trail extends Sprite
	{
		private var currentIndex:int;			// Array index of most recently recorded point
		private var duration:Number;			// Duration (in seconds) of entire trail
		private var sampleInterval:Number;		// Desired interval between taking samples
		private var lastSampleTime:Number;		// Global time when lat sample was taken
		private var dottedPhase:int;			// Dotted line: draw segment or not
		private var currentPosition:Vector3;	// Last reported position of vehicle
		private var vertices:Vector.<Vector3>;	// Array (ring) of recent points along trail
		private var flags:Vector.<int>;			// Array (ring) of flag bits for trail points
		private var trailColor:uint;			// Color of the trail
		private var tickColor:uint;				// Color of the ticks
		
		/**
		 * Initializes a new instance of Trail
		 *
		 * @param ...args
		 * @param duration The amount of time the trail represents.
		 * @param vertexCount The number of samples along the trails length
		 */
		public function Trail(duration:Number=5,vertexCount:int=1000):void
		{
			this.duration = duration;

			// Set internal trail state
			this.currentIndex = 0;
			this.lastSampleTime = 0;
			this.sampleInterval = this.duration / vertexCount;
			this.dottedPhase = 1;

			// Initialize ring buffers
			this.vertices = new Vector.<Vector3>(vertexCount);
			this.flags = new Vector.<int>(vertexCount);

			trailColor = Colors.LightGray;
			tickColor = Colors.White;
		}

		/**
		 * Gets or sets the color of the trail.
		 */
		public function get TrailColor():uint
		{
			return trailColor;
		}
		
		public function set TrailColor(val:uint):void
		{
			trailColor = val;
		}

		/**
		 * Gets or sets the color of the ticks.
		 */
		public function get TickColor():uint
		{
			return tickColor;
		}
		
		public function set TickColor(val:uint):void
		{
			tickColor = val;
		}

		/**
		 * Records a position for the current time, called once per update.
		 * @param	currentTime
		 * @param	position
		 */
		public function Record(currentTime:Number, position:Vector3):void
		{
			var timeSinceLastTrailSample:Number = currentTime - lastSampleTime;
			if (timeSinceLastTrailSample > sampleInterval)
			{
				currentIndex = (currentIndex + 1) % vertices.length;
				vertices[currentIndex] = position;
				dottedPhase = (dottedPhase + 1) % 2;
				var tick:Boolean = (Math.floor(currentTime) > Math.floor(lastSampleTime));
				flags[currentIndex] = int((dottedPhase | (tick ? 2 : 0)));
				lastSampleTime = currentTime;
			}
			currentPosition = position;
		}

		/**
		 * Draws the trail as a dotted line, fading away with age.
		 * @param	drawer
		 */
		public function Draw(drawer:IDraw):void
		{
			var index:int = currentIndex;
			for (var j:int = 0; j < vertices.length; j++)
			{
				// index of the next vertex (mod around ring buffer)
				var next:int = (index + 1) % vertices.length;

				// "tick mark": every second, draw a segment in a different color
				var tick:Boolean = ((flags[index] & 2) != 0 || (flags[next] & 2) != 0);
				var color:uint= tick ? tickColor : trailColor;

				// draw every other segment
				if ((flags[index] & 1) != 0)
				{
					if (j == 0)
					{
						// draw segment from current position to first trail point
						graphics.clear();
						graphics.lineStyle(1, color, opacity);
						graphics.moveTo(currentPosition.x, currentPosition.y);
						graphics.lineTo(vertices[index].x,vertices[index].y);
						graphics.endFill();
					}
					else
					{
						// draw trail segments with opacity decreasing with age
						var minO:Number = 0.05; // minimum opacity
						var fraction:Number = Number(j) / vertices.length;
						var opacity:Number = (fraction * (1 - minO)) + minO;
						
						graphics.clear();
						graphics.lineStyle(1, color, opacity);
						graphics.moveTo(vertices[index].x, vertices[index].y);
						graphics.lineTo(vertices[next].x, vertices[next].y);
						graphics.endFill();
					}
				}
				index = next;
			}
		}
		
		/**
		 * Clear trail history. Used to prevent long streaks due to teleportation.
		 */
		public function Clear():void
		{
			currentIndex = 0;
			lastSampleTime = 0;
			dottedPhase = 1;

			for (var i:int = 0; i < vertices.length; i++)
			{
				vertices[i] = Vector3.Zero;
				flags[i] = 0;
			}
		}
	}
}
