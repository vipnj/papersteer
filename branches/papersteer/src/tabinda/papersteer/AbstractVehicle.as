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
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.objects.DisplayObject3D;
	/** 
	 * Pure virtual base class for generic steerable vehicles
	 * @author Mohammad Haseeb
	 */
	public class AbstractVehicle extends LocalSpace implements IVehicle
	{
		private var _displayObject:DisplayObject3D;
		
		public function get Mass():Number { return 0.0; }
		public function get Radius():Number { return 0.0; }
		public function set Mass(param:Number):void { }
		public function set Radius(param:Number):void { }
		
		public function get Velocity():Vector3 { return new Vector3(); }
		public function get Acceleration():Vector3 { return new Vector3(); }
		
		public function get Speed():Number { return 0.0; }
		public function set Speed(param:Number):void {}
        public function PredictFuturePosition(predictionTime:Number):Vector3 { return new Vector3(); }
		public function get MaxForce():Number { return 0.0; }
		public function get MaxSpeed():Number { return 0.0; }
		public function set MaxForce(param:Number):void{}
		public function set MaxSpeed(param:Number):void { }
		
		public function get displayObject():DisplayObject3D { return _displayObject; }
		
		public function set displayObject(value:DisplayObject3D):void 
		{
			_displayObject = value;
		}
	}
}