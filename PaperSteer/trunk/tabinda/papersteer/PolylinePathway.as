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
	/// <summary>
	/// PolylinePathway: a simple implementation of the Pathway protocol.  The path
	/// is a "polyline" a series of line segments between specified points.  A
	/// radius defines a volume for the path which is the union of a sphere at each
	/// point and a cylinder along each segment.
	/// </summary>
	public class PolylinePathway extends Pathway
	{
		public var pointCount:int;
		public var points:Array;
		public var radius:Number;
		public var cyclic:Boolean;

		// XXX removed the "private" because it interfered with derived
		// XXX classes later this should all be rewritten and cleaned up
		// private:

		// xxx shouldn't these 5 just be local variables?
		// xxx or are they used to pass secret messages between calls?
		// xxx seems like a bad design
		protected var segmentLength:Number;
		protected var segmentProjection:Number;
		protected var local:Vector3D;
		protected var chosen:Vector3D;
		protected var segmentNormal:Vector3D;

		protected var lengths:Array;
		protected var normals:Array;
		protected var totalPathLength:Number;

		//public PolylinePathway()
		//{ }

		// construct a PolylinePathway given the number of points (vertices),
		// an array of points, and a path radius.
		public function PolylinePathway (_pointCount:int,_points:Array,_radius:Number,_cyclic:Boolean):void
		{
			Initialize (_pointCount,_points,_radius,_cyclic);
		}

		// utility for constructors in derived classes
		public function Initialize (_pointCount:int,_points:Array,_radius:Number,_cyclic:Boolean):void
		{
			// set data members, allocate arrays
			radius=_radius;
			cyclic=_cyclic;
			pointCount=_pointCount;
			totalPathLength=0;
			if (cyclic)
			{
				pointCount++;
			}
			lengths=new Array(pointCount);
			points=new Array(pointCount);
			normals=new Array(pointCount);

			// loop over all points
			for (var i:int=0; i < pointCount; i++)
			{
				// copy in point locations, closing cycle when appropriate
				var closeCycle:Boolean=cyclic && i == pointCount - 1;
				var j:int=closeCycle?0:i;
				points[i]=_points[j];

				// for the end of each segment
				if (i > 0)
				{
					// compute the segment length
					normals[i]=points[i] - points[i - 1];
					lengths[i]=normals[i].Length();

					// find the normalized vector parallel to the segment
					normals[i]*= 1 / lengths[i];

					// keep running total of segment lengths
					totalPathLength+= lengths[i];
				}
			}
		}

		// Given an arbitrary point ("A"), returns the nearest point ("P") on
		// this path.  Also returns, via output arguments, the path tangent at
		// P and a measure of how far A is outside the Pathway's "tube".  Note
		// that a negative distance indicates A is inside the Pathway.
		public override  function MapPointToPath (point:Vector3D,tangent:Vector3D,outside:Number):Vector3D
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;
			var onPath:Vector3D=Vector3D.Zero;
			tangent=Vector3D.Zero;

			// loop over all segments, find the one nearest to the given point
			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				d=PointToSegmentDistance(point,points[i - 1],points[i]);
				if (d < minDistance)
				{
					minDistance=d;
					onPath=chosen;
					tangent=segmentNormal;
				}
			}

			// measure how far original point is outside the Pathway's "tube"
			outside=Vector3D.Distance(onPath,point) - radius;

			// return point on path
			return onPath;
		}

		// given an arbitrary point, convert it to a distance along the path
		public override  function MapPointToPathDistance (point:Vector3D):Number
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;
			var segmentLengthTotal:Number=0;
			var pathDistance:Number=0;

			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				d=PointToSegmentDistance(point,points[i - 1],points[i]);
				if (d < minDistance)
				{
					minDistance=d;
					pathDistance=segmentLengthTotal + segmentProjection;
				}
				segmentLengthTotal+= segmentLength;
			}

			// return distance along path of onPath point
			return pathDistance;
		}

		// given a distance along the path, convert it to a point on the path
		public override  function MapPathDistanceToPoint (pathDistance:Number):Vector3D
		{
			// clip or wrap given path distance according to cyclic flag
			var remaining:Number=pathDistance;
			if (cyclic)
			{
				remaining=pathDistance % totalPathLength;//FIXME: (float)fmod(pathDistance, totalPathLength);
			}
			else
			{
				if (pathDistance < 0)
				{
					return points[0];
				}
				if (pathDistance >= totalPathLength)
				{
					return points[pointCount - 1];
				}
			}

			// step through segments, subtracting off segment lengths until
			// locating the segment that contains the original pathDistance.
			// Interpolate along that segment to find 3d point value to return.
			var result:Vector3D=Vector3D.Zero;
			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				if (segmentLength < remaining)
				{
					remaining-= segmentLength;
				}
				else
				{
					var ratio:Number=remaining / segmentLength;
					result=Utilities.Interpolate2(ratio,points[i - 1],points[i]);
					break;
				}
			}
			return result;
		}

		// utility methods

		// compute minimum distance from a point to a line segment
		public function PointToSegmentDistance (point:Vector3D,ep0:Vector3D,ep1:Vector3D):Number
		{
			// convert the test point to be "local" to ep0
			local=Vector3D.VectorSubtraction(point, ep0);

			// find the projection of "local" onto "segmentNormal"
			segmentProjection=segmentNormal.DotProduct(local);

			// handle boundary cases: when projection is not on segment, the
			// nearest point is one of the endpoints of the segment
			if (segmentProjection < 0)
			{
				chosen=ep0;
				segmentProjection=0;
				return Vector3D.Distance(point,ep0);
			}
			if (segmentProjection > segmentLength)
			{
				chosen=ep1;
				segmentProjection=segmentLength;
				return Vector3D.Distance(point,ep1);
			}

			// otherwise nearest point is projection point on segment
			chosen=Vector3D.ScalarMultiplication(segmentProjection,segmentNormal);
			chosen = Vector3D.VectorAddition(chosen , ep0);
			return Vector3D.Distance(point,chosen);
		}

		// assessor for total path length;
		public function get TotalPathLength ():Number
		{
			return totalPathLength;
		}
	}
}