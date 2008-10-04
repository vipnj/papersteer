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
	
	// was an abstract base class
	public class PlugIn implements IPlugIn
	{
		// This array stores a list of all PlugIns.  It is manipulated by the
		// constructor and destructor, and used in findByName and applyToAll.
		const totalSizeOfRegistry:int = 1000;
		static var itemsInRegistry:int = 0;
		static var registry:Array;
		var _name:String;
		
		public function Open():void
		{
			
		}
		public function Update(currentTime:Number, elapsedTime:Number):void
		{
			
		}
		public function Redraw(currentTime:Number, elapsedTime:Number):void
		{
			
		}
		public function Close():void
		{
			
		}
		public function get Name():String
		{
			return _name;
		}
		//public function List<IVehicle> Vehicles { get; }
		public function get Vehicles():Array
		{
			return new Array();
		}

		// prototypes for function pointers used with PlugIns
		public function PlugInCallBackFunction(clientObject:PlugIn):void
		{
			
		}
		
		public function getPICBF():Function
		{
			return PlugInCallBackFunction; // bound method returned
		}

		public function VoidCallBackFunction():void
		{
			
		}
		public function TimestepCallBackFunction(currentTime:Number, elapsedTime:Number):void
		{
			
		}

		// constructor
		public function PlugIn()
		{
			registry = new Array(totalSizeOfRegistry);
			// save this new instance in the registry
			AddToRegistry();
		}

		// default reset method is to do a close then an open
		public function Reset():void
		{
			Close();
			Open();
		}

		// default sort key (after the "built ins")
		public function get SelectionOrderSortKey():Number
		{
			return 1.0;
		}

		// default is to NOT request to be initially selected
		public function get RequestInitialSelection():Boolean
		{
			return false;
		}

		// default function key handler: ignore all
		public function HandleFunctionKeys(key:Keyboard):void { }

		// default "mini help": print nothing
		public function PrintMiniHelpForFunctionKeys():void { }

		// returns pointer to the next PlugIn in "selection order"
		public function Next():PlugIn
		{
			for (var i:int = 0; i < itemsInRegistry; i++)
			{
				if (this == registry[i])
				{
					var atEnd:Boolean = (i == (itemsInRegistry - 1));
					return registry[atEnd ? 0 : i + 1];
				}
			}
			return null;
		}

		// format instance to characters for printing to stream
		public function ToString():String
		{
			return String("<PlugIn \"{0}\">" + Name);
		}

		// CLASS FUNCTIONS

		// search the class registry for a Plugin with the given name
		public static function FindByName(Name:String):IPlugIn
		{
			if (Name.length <= 0)
			{
				for (var i:int = 0; i < itemsInRegistry; i++)
				{
					var pi:PlugIn = registry[i];
					var s:String = pi.Name;
					if (s.length <=0 && Name == s)
						return pi;
				}
			}
			return null;
		}

		// apply a given function to all PlugIns in the class registry
		public static function ApplyToAll(f:Function):void
		{
			//f = getPICBF();
			
			for (var i:int = 0; i < itemsInRegistry; i++)
			{
				//PlugInCallBackFunction(registry[i]);
			}
		}

		// sort PlugIn registry by "selection order"
		public static function SortBySelectionOrder():void
		{
			// I know, I know, just what the world needs:
			// another inline shell sort implementation...

			// starting at each of the first n-1 elements of the array
			for (var i:int = 0; i < itemsInRegistry - 1; i++)
			{
				// scan over subsequent pairs, swapping if larger value is first
				for (var j:int = i + 1; j < itemsInRegistry; j++)
				{
					var iKey:Number = registry[i].SelectionOrderSortKey;
					var jKey:Number = registry[j].SelectionOrderSortKey;

					if (iKey > jKey)
					{
						var temporary:PlugIn = registry[i];
						registry[i] = registry[j];
						registry[j] = temporary;
					}
				}
			}
		}

		// returns pointer to default PlugIn (currently, first in registry)
		public static function FindDefault():PlugIn
		{
			// return NULL if no PlugIns exist
			if (itemsInRegistry == 0) return null;

			// otherwise, return the first PlugIn that requests initial selection
			for (var i:int = 0; i < itemsInRegistry; i++)
			{
				if (registry[i].RequestInitialSelection) return registry[i];
			}

			// otherwise, return the "first" PlugIn (in "selection order")
			return registry[0];
		}

		// save this instance in the class's registry of instances
		function AddToRegistry():void
		{
			// save this instance in the registry
			registry[itemsInRegistry++] = this;
		}
	}
}
