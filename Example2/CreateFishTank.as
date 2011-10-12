// ----------------------------------------------------------------------------
//
// Fish Tank Example
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

package
{
	// Flash Imports
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	
	// OpenSteer Library Imports
	import tabinda.as3steer.*;

	public class CreateFishTank extends MovieClip 
	{
		// OpenSteer variables
		private var _fishTank:FishTank;					// The tank that holds the fish and sharks
		private var _tickTock:Clock;					// Our Acquarium moves real time based on the computer's clock
		
		// Fishtank background Gradient
		private var _gradientType:String;				// Is it a Bulb or a Saber light?
		private var _matrix:Matrix;						// Maths...
		private var _tankBounds:Sprite;					// The boundaries of our Fish Tank
		
		public function CreateFishTank():void
		{
			// Creates the Fish Tank environment
			createEnvironment();
			
			_tickTock = new Clock();
			Start();
		}
		
		////////////////////////////////
		/* Control Our Fish Tank	 */
		///////////////////////////////
		private function createEnvironment():void
		{
			gradientType = GradientType.RADIAL;

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(stage.stageWidth,stage.stageHeight,0,0,0);

			var gradientColors:Array = [0xf1f1f1, 0xc5c5c5];
			var gradientAlphas:Array = [1,1];
			var gradientRatio:Array = [0,255];

			tankBounds = new Sprite();
			tankBounds.graphics.beginGradientFill(gradientType,gradientColors,gradientAlphas,gradientRatio,matrix);
			tankBounds.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			tankBounds.x = tankBounds.y = 0;

			addChild(tankBounds);
		}
	
		/** 
		* Put in some fish and shark eggs and spawn them
		*/
		private function Start():void 
		{
			var totalFish:int = 50;						// Total number of Fish
			var totalSharks:int = 3;					// Total number of Sharks
			
			fishTank = new FishTank (new Vector3 (200, 200, 200), 200, totalFish,totalSharks);
			addChild(fishTank);
			
			addEventListener(Event.ENTER_FRAME, aliveFishTank);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, playAroundWithFish);
			
			for (var i:int=0;i<totalFish;i++)
			{
				fishTank.addFishToTank();
			}
		
			for (i=0;i<totalSharks;i++)
			{
				fishTank.addSharkToTank();
			}
		}
		
		/**
		 * Control the Behavior of the Fish inside Fish Tank
		 * @param	doThis Listens to your Hands
		 */
		private function playAroundWithFish(doThis:KeyboardEvent):void 
		{
			fishTank.controlFish(doThis);
		}
		
		/**
		 * Animate the Fish and the Sharks
		 * @param	lifeEnergy	Update the fish lives
		 */
		private function aliveFishTank(lifeEnergy:Event):void 
		{
			tickTock.Update();
			fishTank.moveIt(tickTock.TotalSimulationTime, tickTock.ElapsedSimulationTime);
		}
		
		////////////////////////////////
		/*Properties of Our Fish Tank*/
		///////////////////////////////
		public function get tickTock():Clock { return _tickTock; }
		
		public function set tickTock(value:Clock):void 
		{
			_tickTock = value;
		}
		
		public function get gradientType():String { return _gradientType; }
		
		public function set gradientType(value:String):void 
		{
			_gradientType = value;
		}
		
		public function get matrix():Matrix { return _matrix; }
		
		public function set matrix(value:Matrix):void 
		{
			_matrix = value;
		}
		
		public function get tankBounds():Sprite { return _tankBounds; }
		
		public function set tankBounds(value:Sprite):void 
		{
			_tankBounds = value;
		}
		
		public function get fishTank():FishTank { return _fishTank; }
		
		public function set fishTank(value:FishTank):void 
		{
			_fishTank = value;
		}
	}
}