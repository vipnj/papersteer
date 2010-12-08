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
		 * @param	trail The trail to add
		 */
		function AddTrail (trail:Trail):void;

		/**
		 * Removes a specified trail
		 * @param	trail The trail to remove
		 */
		function RemoveTrail (trail:Trail):void ;

		/**
		 * Draw all registered Trails
		 */
		function DrawAllTrails ():void;		
		
		/**
		 * Draw the given registered Trail
		 */
		function DrawTrail (trail:Trail):void;		
		
		/**
		 * Clear all registered trails
		 */
		function ClearAllTrails ():void;		
		
		/**
		 * Clear given trail
		 * @param	trail The trail instance to clear
		 */
		function ClearTrail (trail:Trail):void;

		/**
		 * @usage
		 * Drawing of lines, circles and (filled) disks to annotate steering
		 * behaviors.  When called during OpenSteerDemo's simulation update phase,
		 * these functions call a "deferred draw" routine which buffer the
	     * arguments for use during the redraw phase.
		 *
		 * note: "circle" means unfilled
		 *       "disk" means filled
		 *       "XZ" means on a plane parallel to the X and Z axes (perp to Y)
		 *       "3d" means the circle is perpendicular to the given "axis"
		 *       "segments" is the number of line segments used to draw the circle
		 *
		 */
		
		 /** Draws an opaque colored line segment between two locations in space.
		  * 
		 * @param	startPoint Start point of the line
		 * @param	endPoint End point of the line
		 * @param	color Color of the line
		 */
		function Line (startPoint:Vector3, endPoint:Vector3, color:uint):void;

		/**
		 * Draws a circle on the XZ plane.
		 * 
		 * @param radius The radius of the circle.
		 * @param center The center of the circle.
		 * @param color The color of the circle.
		 * @param segments The number of segments to use to draw the circle.
		 */
		function CircleXZ (radius:Number, center:Vector3, color:uint, segments:int):void;

		/**
		* Draws a disk on the XZ plane.
		* 
		* @param radius The radius of the disk.
		* @param center The center of the disk.
		* @param color The color of the disk.
		* @param segments The number of segments to use to draw the disk
		*/
		function DiskXZ (radius:Number, center:Vector3, color:uint, segments:int):void;

		/**
		* Draws a circle perpendicular to the given axis.
		* 
		* @param radius The radius of the circle.
		* @param center The center of the circle.
		* @param axis The axis of the circle.
		* @param color The color of the circle.
		* @param segments The number of segments to use to draw the circle.
		*/
		function Circle3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int):void;
		
		/**
		* Draws a disk perpendicular to the given axis.
		* 
		* @param radius The radius of the disk.
		* @param center The center of the disk.
		* @param axis The axis of the disk.
		* @param color The color of the disk.
		* @param segments The number of segments to use to draw the disk.
		*/
		function Disk3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int):void;

		/** 
		* Draws a circle (not filled) or disk (filled) on the XZ plane.
		* 
		* @param radius The radius of the circle/disk.
		* @param center The center of the circle/disk.
		* @param color The color of the circle/disk.
		* @param segments The number of segments to use to draw the circle/disk.
		* @param filled Flag indicating whether to draw a disk or circle.
		*/
		function CircleOrDiskXZ (radius:Number, center:Vector3, color:uint, segments:int, filled:Boolean):void;

		/**
		* Draws a circle (not filled) or disk (filled) perpendicular to the given axis.
		* 
		* @param radius The radius of the circle/disk.
		* @param center The center of the circle/disk.
		* @param axis The axis of the circle/disk.
		* @param color The color of the circle/disk.
		* @param segments The number of segments to use to draw the circle/disk.
		* @param filled Flag indicating whether to draw a disk or circle.
		*/
		function CircleOrDisk3D (radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int, filled:Boolean):void;

		/**
		* Draws a circle (not filled) or disk (filled) perpendicular to the given axis.
		* 
		* @param radius The radius of the circle/disk.
		* @param axis The axis of the circle/disk.
		* @param center The center of the circle/disk.
		* @param color The color of the circle/disk.
		* @param segments The number of segments to use to draw the circle/disk.
		* @param filled Flag indicating whether to draw a disk or circle.
		* @param in3d Flag indicating whether to draw the disk/circle in 3D or the XZ plane.
		*/
		function CircleOrDisk (radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void;

		/** 
		* Called when steerToAvoidObstacles decides steering is required.
		* 
		* @param minDistanceToCollision
		*/
		function AvoidObstacle (vehicle:IVehicle,minDistanceToCollision:Number):void;

		/** 
		* Called when steerToFollowPath decides steering is required.
		* 
		* @param future
		* @param onPath
		* @param target
		* @param outside
		*/
		function PathFollowing (future:Vector3, onPath:Vector3, target:Vector3, outside:Number):void;

		/**
		 * Called when steerToAvoidCloseNeighbors decides steering is required.
		 * 
		 * @param other
		 * @param additionalDistance
		 */
		function AvoidCloseNeighbor (other:IVehicle, additionalDistance:Number):void;

		/**
		 * Called when steerToAvoidNeighbors decides steering is required.
		 *
		 * @param threat
		 * @param steer
		 * @param ourFuture
		 * @param threatFuture
		 */
		function AvoidNeighbor (threat:IVehicle, steer:Number, ourFuture:Vector3, threatFuture:Vector3):void;

		/**
		 * Draws lines from the vehicle's position showing its velocity and acceleration.
		 *
		 * @param vehicle The vehicle to annotate.
		 */
		function VelocityAcceleration (vehicle:IVehicle):void;

		/**
		 * Draws lines from the vehicle's position showing its velocity and acceleration.
		 * 
		 * @param vehicle The vehicle to annotate.
		 * @param maxLength The maximum length for the acceleration and velocity lines.
		 */
		function VelocityAcceleration2 (vehicle:IVehicle, maxLength:Number):void;

		/**
		 * Draws lines from the vehicle's position showing its velocity and acceleration.
		 * 
		 * @param vehicle The vehicle to annotate.
		 * @param maxLengthAcceleration The maximum length for the acceleration line.
		 * @param maxLengthVelocity The maximum length for the velocity line.
		 */
		function VelocityAcceleration3 (vehicle:IVehicle, maxLengthAcceleration:Number, maxLengthVelocity:Number):void;
	}
}