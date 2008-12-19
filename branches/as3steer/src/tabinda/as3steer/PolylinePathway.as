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

package tabinda.as3steer
{
	/** construct a PolylinePathway given the number of points (vertices),
    *  an array of points, and a path radius.
	*/
	public class PolylinePathway extends Pathway
	{
		var pointCount:int;
		var points:Array;
		var radius:Number;
		var cyclic:Boolean;

		var segmentLength:Number;
		var segmentProjection:Number;
		var local:Vector3;
		var chosen:Vector3;
		var segmentNormal:Vector3;

		var lengths:Array;
		var normals:Array;
		var totalPathLength:Number;

		// construct a PolylinePathway given the number of points (vertices),
		// an array of points, and a path radius.
		public function PolylinePathway(_pointCount:int,_points:Array,_radius:Number,_cyclic:Boolean)
		{
			initialize(_pointCount,_points,_radius,_cyclic);
		}

		// utility for constructors in derived classes
		function initialize(_pointCount:int,_points:Array,_radius:Number,_cyclic:Boolean):void
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
				var closeCycle:Boolean=cyclic && (i == pointCount - 1);
				var j:int=closeCycle?0:i;
				points[i]=_points[j];

				// for the end of each segment
				if (i > 0)
				{
					// compute the segment length
					normals[i]=Vector3.VectorSubtraction(points[i] , points[i - 1]);
					lengths[i]=normals[i].Length();// ength();

					// find the normalized vector parallel to the segment
					normals[i] = Vector3.ScalarMultiplication1(normals[i],(1 / lengths[i]));

					// keep running total of segment lengths
					totalPathLength+= lengths[i];
				}
			}
		}

		// utility methods
		// assessor for total path length;
		function getTotalPathLength():Number
		{
			return totalPathLength;
		}

		public override  function mapPointToPath(point:Vector3,tStruct:mapReturnStruct):Vector3
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;// FLT_MAX;
			var onPath:Vector3=Vector3.ZERO;

			// loop over all segments, find the one nearest to the given point
			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				d=pointToSegmentDistance(point,points[i - 1],points[i]);
				if (d < minDistance)
				{
					minDistance=d;
					onPath=chosen;
					tStruct.tangent=segmentNormal;
				}
			}

			// measure how far original point is outside the Pathway's "tube"
			tStruct.outside= Vector3.VectorSubtraction(onPath , point).Length() - radius;

			// return point on path
			return onPath;
		}

		public override  function mapPointToPathDistance(point:Vector3):Number
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;
			var segmentLengthTotal:Number=0;
			var pathDistance:Number=0;

			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				segmentNormal=normals[i];
				d=pointToSegmentDistance(point,points[i - 1],points[i]);
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

		public override  function mapPathDistanceToPoint(pathDistance:Number):Vector3
		{
			// clip or wrap given path distance according to cyclic flag
			var remaining:Number=pathDistance;
			if (cyclic)
			{
				remaining=Number(pathDistance%totalPathLength);
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
			var result:Vector3=Vector3.ZERO;
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
					result=Utility.interpolate(ratio,points[i - 1],points[i]);
					break;
				}
			}
			return result;
		}

		// ----------------------------------------------------------------------------
		// computes distance from a point to a line segment 
		//
		// (I considered moving this to the vector library, but its too
		// tangled up with the internal state of the PolylinePathway instance)
		function pointToSegmentDistance(point:Vector3,ep0:Vector3,ep1:Vector3):Number
		{
			// convert the test point to be "local" to ep0
			local=Vector3.VectorSubtraction(point , ep0);

			// find the projection of "local" onto "segmentNormal"
			segmentProjection=segmentNormal.DotProduct(local);

			// handle boundary cases: when projection is not on segment, the
			// nearest point is one of the endpoints of the segment
			if (segmentProjection < 0)
			{
				chosen=ep0;
				segmentProjection=0;
				return Vector3.VectorSubtraction(point , ep0).Length();
			}
			if (segmentProjection > segmentLength)
			{
				chosen=ep1;
				segmentProjection=segmentLength;
				return Vector3.VectorSubtraction(point , ep1).Length();
			}

			// otherwise nearest point is projection point on segment
			chosen=Vector3.ScalarMultiplication1(segmentNormal , segmentProjection);
			chosen= Vector3.VectorAddition(chosen,ep0);
			return Vector3.VectorSubtraction(point , chosen).Length();
		}
	}
}