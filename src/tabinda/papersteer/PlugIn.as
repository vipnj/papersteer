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
	// was an abstract base class
	public class PlugIn implements IPlugIn
	{
		// This array stores a list of all PlugIns.  It is manipulated by the
		// constructor and destructor, and used in findByName and applyToAll.
		private static var registry:Vector.<PlugIn> = new Vector.<PlugIn>(totalSizeOfRegistry);
		private static const totalSizeOfRegistry:int = 1000;
		private static var itemsInRegistry:int = 0;
		private var name:String;
		
		/**
		 * Open Plugins and intialize any variables
		 */
		public function Open():void	{ }
		
		/**
		 * Updates the plugin and objects related to it
		 * @param	currentTime Current RealTime Clock Tick
		 * @param	elapsedTime Elapsed Time since last Tick
		 */
		public function Update(currentTime:Number, elapsedTime:Number):void	{ }
		
		/**
		 * Redraw the plugin and objects related to it
		 * @param	currentTime Current RealTime Clock Tick
		 * @param	elapsedTime Elapsed Time since last Tick
		 */
		public function Redraw(currentTime:Number, elapsedTime:Number):void	{ }
		
		/**
		 * Close the plugin and destroy objects
		 */
		public function Close():void { }
		
		/**
		 * Return the name of the plugin
		 */
		public function get Name():String { return name; }
		
		/**
		 * Return all Vehicles of the selected Plugin
		 */
		public function get Vehicles():Vector.<IVehicle> { return new Vector.<IVehicle>(); }

		/**
		 * Prototypes for function pointers used with PlugIns
		 * @param	clientObject 
		 */
		public function PlugInCallBackFunction(...args):void { }
		public function VoidCallBackFunction():void { }
		public function TimestepCallBackFunction(currentTime:Number, elapsedTime:Number):void { }

		/**
		 * Constructor
		 */
		public function PlugIn()
		{
			// save this new instance in the registry
			AddToRegistry();
		}

		/**
		 * Default reset method is to do a close then an open
		 */
		public function Reset():void
		{
			Close();
			Open();
		}

		/**
		 * Default sort key (after the "built ins")
		 */
		public function get SelectionOrderSortKey():Number { return 1.0; }

		/**
		 * Default is to NOT request to be initially selected
		 */
		public function get RequestInitialSelection():Boolean { return false; }

		/**
		 * Default function key handler: ignore all
		 * @param	key
		 */
		public function HandleFunctionKeys(key:uint):void { }

		/**
		 * Default "mini help": print nothing
		 */ 
		public function PrintMiniHelpForFunctionKeys():void { }

		/**
		 * Returns pointer to the next PlugIn in "selection order"
		 * @return Plugin Instance
		 */ 
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

		/**
		 * Format instance to characters for printing to stream
		 * @return Plugin Name
		 */
		public function ToString():String
		{
			return String("<PlugIn \""+Name+"\">");
		}

		// CLASS FUNCTIONS

		/**
		 * Search the class registry for a Plugin with the given name
		 * @param	Name Fint plugin by Name
		 * @return  Plugin instance
		 */
		public static function FindByName(Name:String):IPlugIn
		{
			if (Name == null || Name == "")
			{
				for (var i:int = 0; i < itemsInRegistry; i++)
				{
					var pi:PlugIn = registry[i];
					var s:String = pi.Name;
					if ((s == null || s=="") && Name == s)
					{
						return pi;
					}
				}
			}
			return null;
		}

		/**
		 * Apply a given function to all PlugIns in the class registry
		 * @param	f Function to apply to all Items
		 */
		public static function ApplyToAll(func:Function):void
		{
			for (var i:int = 0; i < itemsInRegistry; i++)
			{
				func.call(null,{plugin:registry[i]});
			}
		}

		/**
		 * Sort PlugIn registry by "selection order"
		 */
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

		/**
		 * Returns pointer to default PlugIn (currently, first in registry)
		 * @return Pointer to default PlugIn
		 */
		public static function FindDefault():PlugIn
		{
			// return NULL if no PlugIns exist
			if (itemsInRegistry == 0)
			{
				return null;
			}

			// otherwise, return the first PlugIn that requests initial selection
			for (var i:int = 0; i < itemsInRegistry; i++)
			{
				if (registry[i].RequestInitialSelection)
				{
					return registry[i];
				}
			}

			// otherwise, return the "first" PlugIn (in "selection order")
			return registry[0];
		}

		/**
		 * Save this instance in the class's registry of instances
		 */
		private function AddToRegistry():void
		{
			// save this instance in the registry
			registry[itemsInRegistry++] = this;
		}
	}
}
