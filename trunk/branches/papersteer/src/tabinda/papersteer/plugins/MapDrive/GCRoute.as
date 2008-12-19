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

package tabinda.papersteer.plugins.MapDrive
{
	import tabinda.papersteer.*;
	
	// A variation on PolylinePathway (whose path tube radius is constant)
	// GCRoute (Grand Challenge Route) has an array of radii-per-segment
	//
	// XXX The OpenSteer path classes are long overdue for a rewrite.  When
	// XXX that happens, support should be provided for constant-radius,
	// XXX radius-per-segment (as in GCRoute), and radius-per-vertex.
	public class GCRoute extends PolylinePathway
	{
		// per-segment radius (width) array
		public var radii:Vector.<Number>;
		
		// construct a GCRoute given the number of points (vertices), an
		// array of points, an array of per-segment path radii, and a flag
		// indiating if the path is connected at the end.
		public function GCRoute (_pointCount:int,_points:Vector.<Vector3>,_radii:Vector.<Number>,_cyclic:Boolean):void
		{
			Initialize (_pointCount,_points,_radii[0],_cyclic);

			radii=new Vector.<Number>(pointCount);

			// loop over all points
			for (var i:int=0; i < pointCount; i++)
			{
				// copy in point locations, closing cycle when appropriate
				var closeCycle:Boolean=cyclic && i == pointCount - 1;
				var j:int=closeCycle?0:i;
				points[i]=_points[j];
				radii[i]=_radii[i];
			}
		}

		// override the PolylinePathway method to allow for GCRoute-style
		// per-leg radii

		// Given an arbitrary point ("A"), returns the nearest point ("P") on
		// this path.  Also returns, via output arguments, the path tangent at
		// P and a measure of how far A is outside the Pathway's "tube".  Note
		// that a negative distance indicates A is inside the Pathway.
		public override  function MapPointToPath (point:Vector3,tangent:Vector3, outside:Number):Array
		{
			var onPath:Vector3=Vector3.Zero;
			tangent=Vector3.Zero;
			outside=Number.MAX_VALUE;

			// loop over all segments, find the one nearest to the given point
			for (var i:int=1; i < pointCount; i++)
			{
				// QQQ note bizarre calling sequence of pointToSegmentDistance
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				var d:Number=PointToSegmentDistance(point,points[i - 1],points[i]);

				// measure how far original point is outside the Pathway's "tube"
				// (negative values (from 0 to -radius) measure "insideness")
				var o:Number=d - radii[i];

				// when this is the smallest "outsideness" seen so far, take
				// note and save the corresponding point-on-path and tangent
				if (o < outside)
				{
					outside=o;
					onPath=chosen;
					tangent=segmentNormal;
				}
			}

			// return point on path
			var temp:Array = new Array();
			temp[0] = onPath;
			temp[1] = tangent
			temp[2] = outside;
			return temp;
		}

		// ignore that "tangent" output argument which is never used
		// XXX eventually move this to Pathway class
		public function callMapPointToPath (point:Vector3,outside:Number):Array
		{
			var tangent:Vector3;
			return MapPointToPath(point,tangent,outside);
		}

		// get the index number of the path segment nearest the given point
		// XXX consider moving this to path class
		public function IndexOfNearestSegment (point:Vector3):int
		{
			var index:int=0;
			var minDistance:Number=Number.MAX_VALUE;

			// loop over all segments, find the one nearest the given point
			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				var d:Number = PointToSegmentDistance(point, points[i - 1], points[i]);
	
				if (d < minDistance)
				{
					minDistance=d;
					index=i;
				}
			}
			return index;
		}

		// returns the dot product of the tangents of two path segments, 
		// used to measure the "angle" at a path vertex: how sharp is the turn?
		public function DotSegmentUnitTangents (segmentIndex0:int,isegmentIndex1:int):Number
		{
			return normals[segmentIndex0].DotProduct(normals[isegmentIndex1]);
		}
		
		/**
		 * return path tangent at given point (its projection on path),
		 * multiplied by the given pathfollowing direction (+1/-1 =
		 * upstream/downstream).  Near path vertices (waypoints) use the
		 * tangent of the "next segment" in the given direction
		 * @param	...args point:Vector3,pathFollowDirection:int
		 * @return normal:Vector3 return path tangent at given point (its projection on path)
		 */
		public function TangentAt(...args):Vector3
		{
			if (args.length == 2)
			{
				var segmentIndex:int=IndexOfNearestSegment(args[0]);
				var nextIndex:int=segmentIndex + args[1];
				var insideNextSegment:Boolean=IsInsidePathSegment(args[0],nextIndex);
				var i:int=segmentIndex + insideNextSegment?args[1]:0;
				return Vector3.ScalarMultiplication(Number(args[1]),normals[i]);
			}
			else(args.length == 1)
			{
				return normals[IndexOfNearestSegment(args[0])];
			}
		}
		
		/*return path tangent at given point (its projection on path)
		public function TangentAt (point:Vector3):Vector3
		{
			return normals[IndexOfNearestSegment(point)];
		}

		// return path tangent at given point (its projection on path),
		// multiplied by the given pathfollowing direction (+1/-1 =
		// upstream/downstream).  Near path vertices (waypoints) use the
		// tangent of the "next segment" in the given direction
		public function TangentAt (point:Vector3,pathFollowDirection:int):Vector3
		{
			var segmentIndex:int=IndexOfNearestSegment(point);
			var nextIndex:int=segmentIndex + pathFollowDirection;
			var insideNextSegment:Boolean=IsInsidePathSegment(point,nextIndex);
			var i:int=segmentIndex + insideNextSegment?pathFollowDirection:0;
			return normals[i] * Number(pathFollowDirection);
		}*/

		// is the given point "near" a waypoint of this path?  ("near" == closer
		// to the waypoint than the max of radii of two adjacent segments)
		public function NearWaypoint (point:Vector3):Boolean
		{
			// loop over all waypoints
			for (var i:int=1; i < pointCount; i++)
			{
				// return true if near enough to this waypoint
				var r:Number=Math.max(radii[i],radii[i + 1 % pointCount]);
				var d:Number=Vector3.VectorSubtraction(point , points[i]).Magnitude();
				if (d < r)
				{
					return true;
				}
			}
			return false;
		}

		// is the given point inside the path tube of the given segment
		// number?  (currently not used. this seemed like a useful utility,
		// but wasn't right for the problem I was trying to solve)
		public function IsInsidePathSegment (point:Vector3,segmentIndex:int):Boolean
		{
			if (segmentIndex < 1 || segmentIndex >= pointCount)
			{
				return false;
			}

			var i:int=segmentIndex;

			// QQQ note bizarre calling sequence of pointToSegmentDistance
			segmentLength=lengths[i];
			segmentNormal=normals[i];
			var d:Number=PointToSegmentDistance(point,points[i - 1],points[i]);

			// measure how far original point is outside the Pathway's "tube"
			// (negative values (from 0 to -radius) measure "insideness")
			var o:Number=d - radii[i];

			// return true if point is inside the tube
			return o < 0;
		}
	}
}