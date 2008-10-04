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
	public class Annotation implements IAnnotationService
	{
		//List<Trail> trails;
		var trails:Array;
		var isenabled:Boolean;

		//HACK: change the IDraw to a IDrawService
		public static  var drawer:IDraw;

		// constructor
		public function Annotation ()
		{
			isenabled=true;
			//trails = new List<Trail>();
			trails=new Array();
		}

		/// <summary>
		/// Indicates whether annotation is enabled.
		/// </summary>
		public function get IsEnabled ():Boolean
		{
			return isenabled;
		}
		public function set IsEnabled (val:Boolean):void
		{
			isenabled=val;
		}

		/// <summary>
		/// Adds a Trail.
		/// </summary>
		/// <param name="trail">The trail to add.</param>
		public function AddTrail (trail:Trail):void
		{
			trails.push(trail);
		}

		/// <summary>
		/// Removes the specified Trail.
		/// </summary>
		/// <param name="trail">The trail to remove.</param>
		public function RemoveTrail (trail:Trail):void
		{
			trails.splice(trails.indexOf(trail),1);
		}

		/// <summary>
		/// Draws all registered Trails.
		/// </summary>
		public function DrawTrails (drawer:IDraw):void
		{
			for (var i:int=0; i < trails.length; i++)
			{
				trails[i].Draw(drawer);
			}
		}

		// ------------------------------------------------------------------------
		// drawing of lines, circles and (filled) disks to annotate steering
		// behaviors.  When called during OpenSteerDemo's simulation update phase,
		// these functions call a "deferred draw" routine which buffer the
		// arguments for use during the redraw phase.
		//
		// note: "circle" means unfilled
		//       "disk" means filled
		//       "XZ" means on a plane parallel to the X and Z axes (perp to Y)
		//       "3d" means the circle is perpendicular to the given "axis"
		//       "segments" is the number of line segments used to draw the circle

		// draw an opaque colored line segment between two locations in space
		public function Line (startPoint:Vector3D,endPoint:Vector3D,color:uint):void
		{
			if (isenabled == true && drawer != null)
			{
				drawer.Line (startPoint,endPoint,color);
			}
		}

		// draw a circle on the XZ plane
		public function CircleXZ (radius:Number,center:Vector3D,color:uint,segments:int):void
		{
			CircleOrDiskXZ (radius,center,color,segments,false);
		}

		// draw a disk on the XZ plane
		public function DiskXZ (radius:Number,center:Vector3D,color:uint,segments:int):void
		{
			CircleOrDiskXZ (radius,center,color,segments,true);
		}

		// draw a circle perpendicular to the given axis
		public function Circle3D (radius:Number,center:Vector3D,axis:Vector3D,color:uint,segments:int):void
		{
			CircleOrDisk3D (radius,center,axis,color,segments,false);
		}

		// draw a disk perpendicular to the given axis
		public function Disk3D (radius:Number,center:Vector3D,axis:Vector3D,color:uint,segments:int):void
		{
			CircleOrDisk3D (radius,center,axis,color,segments,true);
		}

		// ------------------------------------------------------------------------
		// support for annotation circles
		public function CircleOrDiskXZ (radius:Number,center:Vector3D,color:uint,segments:int,filled:Boolean):void
		{
			CircleOrDisk (radius,Vector3D.Zero,center,color,segments,filled,false);
		}

		public function CircleOrDisk3D (radius:Number,center:Vector3D,axis:Vector3D,color:uint,segments:int,filled:Boolean):void
		{
			CircleOrDisk (radius,axis,center,color,segments,filled,true);
		}

		public function CircleOrDisk (radius:Number,axis:Vector3D,center:Vector3D,color:uint,segments:int,filled:Boolean,in3d:Boolean):void
		{
			if (isenabled == true && drawer != null)
			{
				drawer.CircleOrDisk (radius,axis,center,color,segments,filled,in3d);
			}
		}

		// called when steerToAvoidObstacles decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function AvoidObstacle (minDistanceToCollision:Number):void
		{
		}

		// called when steerToFollowPath decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function PathFollowing (future:Vector3D,onPath:Vector3D,target:Vector3D,outside:Number):void
		{
		}

		// called when steerToAvoidCloseNeighbors decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function AvoidCloseNeighbor (other:IVehicle,additionalDistance:Number):void
		{
		}

		// called when steerToAvoidNeighbors decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function AvoidNeighbor (threat:IVehicle,steer:Number,ourFuture:Vector3D,threatFuture:Vector3D):void
		{
		}

		public function VelocityAcceleration (vehicle:IVehicle):void
		{
			VelocityAcceleration3 (vehicle,3,3);
		}

		public function VelocityAcceleration2 (vehicle:IVehicle,maxLength:Number):void
		{
			VelocityAcceleration3 (vehicle,maxLength,maxLength);
		}

		public function VelocityAcceleration3 (vehicle:IVehicle,maxLengthAcceleration:Number,maxLengthVelocity:Number):void
		{
			const desat:int=102;
			var vColor:uint = 0xFF99CC;// new Colors(255, desat, 255);// pinkish
			var aColor:uint = 0x00CCFF;// new Colors(desat, desat, 255);// bluish

			var aScale:Number=maxLengthAcceleration / vehicle.MaxForce;
			var vScale:Number=maxLengthVelocity / vehicle.MaxSpeed;
			var p:Vector3D=vehicle.Position;

			Line (p, Vector3D.ScalarMultiplication(vScale,Vector3D.VectorAddition(p , vehicle.Velocity)),vColor);
			Line (p,Vector3D.ScalarMultiplication(aScale,Vector3D.VectorAddition(p , vehicle.Velocity)),aColor);
		}
	}
}