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
	// Provides methods to annotate the steering behaviors.
	public interface IAnnotationService
	{
		/**
		 * Indicates whether annotation is enabled.
		 */ 
		function get IsEnabled ():Boolean;
		function set IsEnabled (val:Boolean):void;
		
		/**
		 * This function should be called to redraw the Annotation Canvas
		 */
		function Redraw():void;

		/**
		 * Adds a Trail
		 * @param	trail An instance of a trail canvas
		 */
		function AddTrail (trail:Trail):void;

		/// <summary>
		/// Removes the specified Trail.
		/// </summary>
		/// <param name="trail"></param>
		function RemoveTrail (trail:Trail):void ;

		/// <summary>
		/// Draws all registered Trails.
		/// </summary>
		function DrawTrails ():void;

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

		/// <summary>
		/// Draws an opaque colored line segment between two locations in space.
		/// </summary>
		/// <param name="startPoint">The start point of the line.</param>
		/// <param name="endPoint">The end point of the line.</param>
		/// <param name="color">The color of the line.</param>
		function Line (startPoint:Vector3, endPoint:Vector3, color:uint):void;

		/// <summary>
		/// Draws a circle on the XZ plane.
		/// </summary>
		/// <param name="radius">The radius of the circle.</param>
		/// <param name="center">The center of the circle.</param>
		/// <param name="color">The color of the circle.</param>
		/// <param name="segments">The number of segments to use to draw the circle.</param>
		function CircleXZ (radius:Number, center:Vector3, color:uint, segments:int):void;

		/// <summary>
		/// Draws a disk on the XZ plane.
		/// </summary>
		/// <param name="radius">The radius of the disk.</param>
		/// <param name="center">The center of the disk.</param>
		/// <param name="color">The color of the disk.</param>
		/// <param name="segments">The number of segments to use to draw the disk.</param>
		function DiskXZ (radius:Number, center:Vector3, color:uint, segments:int):void;

		/// <summary>
		/// Draws a circle perpendicular to the given axis.
		/// </summary>
		/// <param name="radius">The radius of the circle.</param>
		/// <param name="center">The center of the circle.</param>
		/// <param name="axis">The axis of the circle.</param>
		/// <param name="color">The color of the circle.</param>
		/// <param name="segments">The number of segments to use to draw the circle.</param>
		function Circle3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int):void;
		/// <summary>
		/// Draws a disk perpendicular to the given axis.
		/// </summary>
		/// <param name="radius">The radius of the disk.</param>
		/// <param name="center">The center of the disk.</param>
		/// <param name="axis">The axis of the disk.</param>
		/// <param name="color">The color of the disk.</param>
		/// <param name="segments">The number of segments to use to draw the disk.</param>
		function Disk3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int):void;

		/// <summary>
		/// Draws a circle (not filled) or disk (filled) on the XZ plane.
		/// </summary>
		/// <param name="radius">The radius of the circle/disk.</param>
		/// <param name="center">The center of the circle/disk.</param>
		/// <param name="color">The color of the circle/disk.</param>
		/// <param name="segments">The number of segments to use to draw the circle/disk.</param>
		/// <param name="filled">Flag indicating whether to draw a disk or circle.</param>
		function CircleOrDiskXZ (radius:Number, center:Vector3, color:uint, segments:int, filled:Boolean):void;

		/// <summary>
		/// Draws a circle (not filled) or disk (filled) perpendicular to the given axis.
		/// </summary>
		/// <param name="radius">The radius of the circle/disk.</param>
		/// <param name="center">The center of the circle/disk.</param>
		/// <param name="axis">The axis of the circle/disk.</param>
		/// <param name="color">The color of the circle/disk.</param>
		/// <param name="segments">The number of segments to use to draw the circle/disk.</param>
		/// <param name="filled">Flag indicating whether to draw a disk or circle.</param>
		function CircleOrDisk3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int, filled:Boolean):void;

		/// <summary>
		/// Draws a circle (not filled) or disk (filled) perpendicular to the given axis.
		/// </summary>
		/// <param name="radius">The radius of the circle/disk.</param>
		/// <param name="axis">The axis of the circle/disk.</param>
		/// <param name="center">The center of the circle/disk.</param>
		/// <param name="color">The color of the circle/disk.</param>
		/// <param name="segments">The number of segments to use to draw the circle/disk.</param>
		/// <param name="filled">Flag indicating whether to draw a disk or circle.</param>
		/// <param name="in3d">Flag indicating whether to draw the disk/circle in 3D or the XZ plane.</param>
		function CircleOrDisk (radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void;

		/// <summary>
		/// Called when steerToAvoidObstacles decides steering is required.
		/// </summary>
		/// <param name="minDistanceToCollision"></param>
		function AvoidObstacle (minDistanceToCollision:Number):void;

		/// <summary>
		/// Called when steerToFollowPath decides steering is required.
		/// </summary>
		/// <param name="future"></param>
		/// <param name="onPath"></param>
		/// <param name="target"></param>
		/// <param name="outside"></param>
		function PathFollowing (future:Vector3, onPath:Vector3, target:Vector3, outside:Number):void;

		/// <summary>
		/// Called when steerToAvoidCloseNeighbors decides steering is required.
		/// </summary>
		/// <param name="other"></param>
		/// <param name="additionalDistance"></param>
		function AvoidCloseNeighbor (other:IVehicle, additionalDistance:Number):void;

		/// <summary>
		/// Called when steerToAvoidNeighbors decides steering is required.
		/// </summary>
		/// <param name="threat"></param>
		/// <param name="steer"></param>
		/// <param name="ourFuture"></param>
		/// <param name="threatFuture"></param>
		function AvoidNeighbor (threat:IVehicle, steer:Number, ourFuture:Vector3, threatFuture:Vector3):void;

		/// <summary>
		/// Draws lines from the vehicle's position showing its velocity and acceleration.
		/// </summary>
		/// <param name="vehicle">The vehicle to annotate.</param>
		function VelocityAcceleration (vehicle:IVehicle):void;

		/// <summary>
		/// Draws lines from the vehicle's position showing its velocity and acceleration.
		/// </summary>
		/// <param name="vehicle">The vehicle to annotate.</param>
		/// <param name="maxLength">The maximum length for the acceleration and velocity lines.</param>
		function VelocityAcceleration2 (vehicle:IVehicle, maxLength:Number):void;

		/// <summary>
		/// Draws lines from the vehicle's position showing its velocity and acceleration.
		/// </summary>
		/// <param name="vehicle">The vehicle to annotate.</param>
		/// <param name="maxLengthAcceleration">The maximum length for the acceleration line.</param>
		/// <param name="maxLengthVelocity">The maximum length for the velocity line.</param>
		function VelocityAcceleration3 (vehicle:IVehicle, maxLengthAcceleration:Number, maxLengthVelocity:Number):void;
	}
}