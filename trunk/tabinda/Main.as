// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>

// PaperSteer - Steering Behaviors for Autonomous Characters
package tabinda
{
	import flash.display.Sprite;
	import tabinda.demo;
	
	public class Main extends Sprite
	{
		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		var demo:Demo = new Demo()
		demo.initialize():
		addChild(demo);
	}
}
