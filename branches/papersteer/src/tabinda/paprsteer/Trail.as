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
	/// <summary>
	/// Provides support to visualize the recent path of a vehicle.
	/// </summary>
	public class Trail
	{
		var currentIndex:int;			// Array index of most recently recorded point
		var duration:Number;				// Duration (in seconds) of entire trail
		var sampleInterval:Number;		// Desired interval between taking samples
		var lastSampleTime:Number;		// Global time when lat sample was taken
		var dottedPhase:int;			// Dotted line: draw segment or not
		var currentPosition:Vector3;	// Last reported position of vehicle
		var vertices:Vector.<Vector3>;			// Array (ring) of recent points along trail
		var flags:Vector.<int>;				// Array (ring) of flag bits for trail points
		var trailColor:uint;			// Color of the trail
		var tickColor:uint;			// Color of the ticks

		/// <summary>
		/// Initializes a new instance of Trail.
		/// </summary>
		/// <param name="duration">The amount of time the trail represents.</param>
		/// <param name="vertexCount">The number of smaples along the trails length.</param>
		public function Trail(...args):void
		{
			if (args.length == 2)
			{
				this.duration = args[0];

				// Set internal trail state
				this.currentIndex = 0;
				this.lastSampleTime = 0;
				this.sampleInterval = this.duration / args[1];
				this.dottedPhase = 1;

				// Initialize ring buffers
				this.vertices = new Vector.<Vector3>(args[1]);
				this.flags = new Vector.<int>(args[1]);

				trailColor = Colors.LightGray;
				tickColor = Colors.White;
			}
			else
			{
				this.duration = 5;

				// Set internal trail state
				this.currentIndex = 0;
				this.lastSampleTime = 0;
				this.sampleInterval = this.duration / 1000;
				this.dottedPhase = 1;

				// Initialize ring buffers
				this.vertices = new Vector.<Vector3>(1000);
				this.flags = new Vector.<int>(1000);

				trailColor = Colors.LightGray;
				tickColor = Colors.White;
			}
		}

		/// <summary>
		/// Gets or sets the color of the trail.
		/// </summary>
		public function get TrailColor():uint
		{
			return trailColor;
		}
		
		public function set TrailColor(val:uint)
		{
			trailColor = val;
		}

		/// <summary>
		/// Gets or sets the color of the ticks.
		/// </summary>
		public function get TickColor():uint
		{
			return tickColor;
		}
		
		public function set TickColor(val:uint)
		{
			tickColor = val;
		}

		/// <summary>
		/// Records a position for the current time, called once per update.
		/// </summary>
		/// <param name="currentTime"></param>
		/// <param name="position"></param>
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

		/// <summary>
		/// Draws the trail as a dotted line, fading away with age.
		/// </summary>
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
						drawer.LineAlpha(currentPosition, vertices[index], color, 1);
					}
					else
					{
						// draw trail segments with opacity decreasing with age
						var minO:Number = 0.05; // minimum opacity
						var fraction:Number = Number(j) / vertices.length;
						var opacity:Number = (fraction * (1 - minO)) + minO;
						drawer.LineAlpha(vertices[index], vertices[next], color, opacity);
					}
				}
				index = next;
			}
		}

		/// <summary>
		/// Clear trail history. Used to prevent long streaks due to teleportation.
		/// </summary>
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
