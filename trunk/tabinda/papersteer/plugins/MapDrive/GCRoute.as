// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// Copyright (C) 2007 Michael Coles <michael@digini.com>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/*using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework;*/

package tabinda.papersteer.plugins.MapDrive
{
	// A variation on PolylinePathway (whose path tube radius is constant)
	// GCRoute (Grand Challenge Route) has an array of radii-per-segment
	//
	// XXX The OpenSteer path classes are long overdue for a rewrite.  When
	// XXX that happens, support should be provided for constant-radius,
	// XXX radius-per-segment (as in GCRoute), and radius-per-vertex.
	public class GCRoute extends PolylinePathway
	{
		// construct a GCRoute given the number of points (vertices), an
		// array of points, an array of per-segment path radii, and a flag
		// indiating if the path is connected at the end.
		public function GCRoute (_pointCount:int,_points:Array,_radii:Array,_cyclic:Boolean):void
		{
			Initialize (_pointCount,_points,_radii[0],_cyclic);

			radii=new Array(pointCount);

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
		public override  function MapPointToPath (point:Vector3,tangent:Vector3,outside:Number):Vector3
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
			return onPath;
		}

		// ignore that "tangent" output argument which is never used
		// XXX eventually move this to Pathway class
		public function MapPointToPath (point:Vector3,outside:Number):Vector3
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
				var d:Number=PointToSegmentDistance(point,points[i - 1],points[i]);
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
			return Vector3.Dot(normals[segmentIndex0],normals[segmentIndex1]);
		}

		// return path tangent at given point (its projection on path)
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
		}

		// is the given point "near" a waypoint of this path?  ("near" == closer
		// to the waypoint than the max of radii of two adjacent segments)
		public function NearWaypoint (point:Vector3):Boolean
		{
			// loop over all waypoints
			for (var i:int=1; i < pointCount; i++)
			{
				// return true if near enough to this waypoint
				var r:Number=Math.max(radii[i],radii[i + 1 % pointCount]);
				var d:Number=point - points[i].Length();
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

		// per-segment radius (width) array
		public var radii:Array;
	}
}