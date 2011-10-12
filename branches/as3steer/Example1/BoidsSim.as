// ----------------------------------------------------------------------------
//
// AS3Steer - OpenSteer Action Script 3 Port
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

package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import tabinda.as3steer.*;
	
	public class BoidsSim extends MovieClip
	{
		var clock:Clock;

		// flock: a group (STL vector) of pointers to all boids
		var flock:Array;

		// pointer to database used to accelerate proximity queries
		var pd:AbstractProximityDatabase;

		// keep track of current flock size
		var population:int;

		// which of the various proximity databases is currently in use
		var cyclePD:int;
				
		var container:Sprite = new Sprite();

		public function BoidsSim()
		{
			container.x = stage.stageWidth / 4;
			container.y = stage.stageHeight / 2;
			addChild(container);
			
			clock = new Clock();
			flock = new Array();
			
			Open();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, HandleFunctionKeys);
			this.addEventListener(Event.ENTER_FRAME, cycle);
			stage.addEventListener(MouseEvent.CLICK,callAddBoidtoFlock);
		}

		function cycle(e:Event):void
		{
			clock.Update();
			Update(clock.TotalSimulationTime, clock.ElapsedSimulationTime);
			Redraw();
		}

		function Open():void
		{
			// make the database used to accelerate proximity queries
			cyclePD = -1;
			NextPD();

			// make default-sized flock
			population = 0;
			for (var i:int = 0; i < 200; i++) 
			{
				AddBoidToFlock();
			}
		}

		function Update(currentTime:Number,elapsedTime:Number):void
		{
			// update flock simulation for each boid
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].Update(currentTime,elapsedTime);
			}
		}

		function Redraw():void
		{
			// draw each boid in flock
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].Draw();
			}
		}

		function Close():void
		{
			// delete each member of the flock
			while (population > 0)
			{
				RemoveBoidFromFlock();
			}

			// delete the proximity database
			pd = null;
		}

		function Reset():void
		{
			// reset each boid in flock
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].Reset();
			}
		}

		// for purposes of demonstration, allow cycling through various
		// types of proximity databases.  this routine is called when the
		// Demo user pushes a function key.
		function NextPD():void
		{
			// save pointer to old PD
			var oldPD = pd;

			// allocate new PD
			const totalPD:int = 2;
			switch (cyclePD = (cyclePD + 1) % totalPD)
			{
			case 0:
				{
					proinfo.autoSize = TextFieldAutoSize.LEFT;
					proinfo.text = "Proximity: LQ Bin Lattice";
					var center:Vector3 = Vector3.ZERO;
					var div:Number = 10.0;
					var divisions:Vector3 = new Vector3(div, div, div);
					var diameter:Number = Boid.worldRadius * 1.1 * 2;
					var dimensions:Vector3 = new Vector3(diameter, diameter, diameter);
					pd = new LQProximityDatabase(center, dimensions, divisions);
					break;
				}
			case 1:
				{
					proinfo.autoSize = TextFieldAutoSize.LEFT;
					proinfo.text = "Proximity: Brute Force";
					pd = new BruteForceProximityDatabase();
					break;
				}
			}

			// switch each boid to new PD
			for (var i:int = 0; i < flock.length; i++)
			{
				flock[i].NewPD(pd);
			}

			// delete old PD (if any)
			oldPD = null;
		}

		function HandleFunctionKeys(key:KeyboardEvent):void
		{
			switch (key.keyCode)
			{
				case (Keyboard.F1): AddBoidToFlock(); break;
				case (Keyboard.F2): RemoveBoidFromFlock(); break;
				case (Keyboard.F3): NextPD(); break;
				case (Keyboard.F4): Boid.NextBoundaryCondition(boundinfo); break;
			}
		}
		
		function callAddBoidtoFlock(e:MouseEvent):void
		{
			AddBoidToFlock();
		}

		function AddBoidToFlock():void
		{		
			population++;
			var boid:Boid = new Boid(pd);
			flock.push(boid);
			container.addChild(boid.sp);
			binfo.autoSize = TextFieldAutoSize.RIGHT;
			binfo.text = "Boids: " + flock.length;
		}

		function RemoveBoidFromFlock():void
		{
			if (population > 0)
			{
				// save a pointer to the last boid, then remove it from the flock
				population--;
				var boid:Boid = flock[population];
				flock.splice(population, 1);
				
				container.removeChild(boid.sp);
				// delete the Boid
				boid = null;
			}
		}

		// return an AVGroup containing each boid of the flock
		function get Vehicles():Array
		{
			return flock;
		}
	}
}
