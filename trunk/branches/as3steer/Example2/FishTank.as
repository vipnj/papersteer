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
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.geom.Transform;
	import flash.text.*;
	import flash.ui.Keyboard;
	
	import tabinda.as3steer.*;

	public class FishTank extends Sprite 
	{
		public var fishInTank:Array;
		public var sharksInTank:Array;
		public var totalFish:int;
		public var totalSharks:int;
		public var population:int;
		public var spawnPod:Vector3;
		public var proximityDatabase:AbstractProximityDatabase;
		public var tankParameter:Number;
		public var changeFishBehavior:int = 1;
		
		public var fishInformation:TextField;
		public var sharksInformation:TextField;
		public var proximityInformation:TextField;
		public var boundaryInformation:TextField;
		 
		/**
		 * 
		 * @param	spawnPod
		 * @param	radius
		 * @param	totalFishElements
		 * @param	totalPredators
		 */
		public function FishTank( _spawnPod:Vector3, _tankParameters:Number,_totalFish:int,_totalSharks:int)
		{
			spawnPod = _spawnPod;
			tankParameter = _tankParameters;
			totalFish = _totalFish;
			totalSharks = _totalSharks;
			
			fishInformation = new TextField();
			sharksInformation = new TextField();
			proximityInformation = new TextField();
			boundaryInformation = new TextField();
			
			fishInformation.text = "There are " + totalFish + " Fish in this Tank";
			sharksInformation.text = "Total are " +totalSharks + " Sharks in this Tank";
			boundaryInformation.text = "Stay Close";
			
			fishInformation.y = 10;
			sharksInformation.y = 25;
			proximityInformation.y = 40;
			boundaryInformation.y = 55;
			
			fishInformation.autoSize = sharksInformation.autoSize = proximityInformation.autoSize = boundaryInformation.autoSize = proximityInformation.autoSize = TextFieldAutoSize.LEFT;
			
			addChild(fishInformation);
			addChild(sharksInformation);
			addChild(proximityInformation);
			addChild(boundaryInformation);
			
			fishInTank=new Array();
			sharksInTank=new Array();
			nextMove(); 
		}
		
		public function addFishToTank():void
		{			
			var fish:Fish = new Fish (proximityDatabase,spawnPod,tankParameter);
			fishInTank.push(fish);
			addChild(fish.soul);
			population++;
			
			fishInformation.text = "There are " + fishInTank.length + " Fish in this Tank";
		}
		
		public function addSharkToTank():void
		{
			var shark:Shark=new Shark(proximityDatabase);
			addChild(shark.soul);
			
			for (var i:int=0;i<fishInTank.length;i++)
			{
				var fish:Fish=Fish( fishInTank[i]); 
				fish.addShark(shark);
			}
			sharksInTank.push(shark);
			
			sharksInformation.text = "There are " + sharksInTank.length + " Sharks in this Tank";
		}
		
		private function removeSharkFromTank ():void
		{
			if (sharksInTank.length > 0)
			{
				// save a pointer to the last boid, then remove it from the flock
				var shark:Shark = sharksInTank.pop();
				removeChild(shark.soul);
				shark = null;
				
				sharksInformation.text = "There are " + sharksInTank.length + " Sharks in this Tank";
			}
		}
		
		private function removeFishFromTank ():void
		{
			if (population > 0)
			{
				// save a pointer to the last boid, then remove it from the flock
				var fish:Fish = fishInTank.pop();
				removeChild(fish.soul);
				fish = null;
				population--;
				
				fishInformation.text = "There are " + fishInTank.length + " Fish in this Tank";
			}
		}
		
		private function nextMove():void
		{
			// allocate new PD
			const totalMoves:int = 2;
			
			switch (changeFishBehavior = (changeFishBehavior + 1) % totalMoves)
			{
			case 0:
				   trace("LQ SELECTED");
				   proximityInformation.text = "Fish, Try to Stick Together";
				   
				   var div:Number = 10.0;
				   var divisions:Vector3 =new Vector3(div, div, div);
				   var diameter:Number = tankParameter;
				   var dimensions:Vector3 =new Vector3(diameter, diameter, diameter);
				 
				   proximityDatabase = new LQProximityDatabase(spawnPod,dimensions,divisions);
				   break;
			case 1:
					trace("BRUTE FORCE SELECTED");
					proximityInformation.text = "Choose yer Friends and Wander";
					
					proximityDatabase = new BruteForceProximityDatabase();
					break;
			}        
			
			for (var i:int=0;i<fishInTank.length;i++)
			{
				var fish:Fish=Fish(fishInTank[i]);  
				fish.newPD(proximityDatabase);
			}
			
		}
		
		public function controlFish(doThis:KeyboardEvent):void
		{
			switch (doThis.keyCode)
			{
				case (Keyboard.F1): addFishToTank(); break;
				case (Keyboard.F2): removeFishFromTank(); break;
				case (Keyboard.F3): addSharkToTank(); break;
				case (Keyboard.F4): removeSharkFromTank(); break;
				case (Keyboard.F5): nextMove(); break;
				case (Keyboard.F6): 
					if (Fish.boundaryCondition == 0) 
					{ 
						Fish.boundaryCondition = 1; 
						boundaryInformation.text = "Roam this Tank Freely";
					} 
					else 
					{ 
						Fish.boundaryCondition = 0;
						boundaryInformation.text = "Stay Close";
					}
					break;
			}
		}
		
		// Update is called once per frame
		public function moveIt(simulationTime:Number, elapsedTime:Number):void 
		{
			for (var i:int=0;i<fishInTank.length;i++)
			{
				var fish:Fish=Fish(fishInTank[i]); 
				fish.update(simulationTime, elapsedTime);
			}
			
			for (i=0;i<sharksInTank.length;i++)
			{
				var shark:Shark=Shark( sharksInTank[i]); 
				shark.update(simulationTime, elapsedTime);
			}
			spawnPod = proximityDatabase.getMostPopulatedBinCenter();
		}
	}
}
