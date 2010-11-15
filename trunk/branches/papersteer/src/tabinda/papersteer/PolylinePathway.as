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
	/// <summary>
	/// PolylinePathway: a simple implementation of the Pathway protocol.  The path
	/// is a "polyline" a series of line segments between specified points.  A
	/// radius defines a volume for the path which is the union of a sphere at each
	/// point and a cylinder along each segment.
	/// </summary>
	public class PolylinePathway extends Pathway
	{
		public var pointCount:int;
		public var points:Vector.<Vector3>;
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
		protected var local:Vector3;
		protected var chosen:Vector3;
		protected var segmentNormal:Vector3;

		protected var lengths:Vector.<Number>;
		protected var normals:Vector.<Vector3>;
		protected var totalPathLength:Number;

		//public PolylinePathway()
		//{ }

		// construct a PolylinePathway given the number of points (vertices),
		// an array of points, and a path radius.
		// takes _pointCount:int,_points:Array,_radius:Number,_cyclic:Boolean
		public function PolylinePathway(...args):void
		{
			//trace("PolylinePathway.constructor",args[0] is int, args[1] is Vector.<Vector3>, args[2] is Number,args[3] is Boolean);
			
			if(args.length == 4)
			{
				Initialize (args[0],args[1],args[2],args[3]);
			}
			else
			{}
		}

		// utility for constructors in derived classes
		public function Initialize (_pointCount:int,_points:Vector.<Vector3>,_radius:Number,_cyclic:Boolean):void
		{
			// set data members, allocate arrays
			radius=_radius+0.0;
			cyclic=_cyclic;
			pointCount=_pointCount;
			totalPathLength=0.0;
			if (cyclic)
			{
				pointCount++;
			}
			
			lengths = new Vector.<Number>(pointCount);
			points = new Vector.<Vector3>(pointCount);
			normals = new Vector.<Vector3>(pointCount);
			
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
					normals[i]=Vector3.VectorSubtraction(points[i] , points[i - 1]);
					lengths[i] = normals[i].Magnitude();

					// find the normalized vector parallel to the segment
					normals[i] = Vector3.ScalarMultiplication((1 / lengths[i]),normals[i]);

					// keep running total of segment lengths
					totalPathLength+= lengths[i];
				}
			}
		}

		// Given an arbitrary point ("A"), returns the nearest point ("P") on
		// this path.  Also returns, via output arguments, the path tangent at
		// P and a measure of how far A is outside the Pathway's "tube".  Note
		// that a negative distance indicates A is inside the Pathway.
		public override  function MapPointToPath (point:Vector3,tangent:Vector3,outside:Number):Array
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;
			var onPath:Vector3=Vector3.Zero;
			tangent=Vector3.Zero;

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
			outside=Vector3.Distance(onPath,point) - radius;

			var temp:Array = new Array();
			temp[0] = onPath;
			temp[1] = tangent;
			temp[2] = outside
			// return point on path
			return temp;
		}

		// given an arbitrary point, convert it to a distance along the path
		public override  function MapPointToPathDistance (point:Vector3):Number
		{
			var d:Number;
			var minDistance:Number=Number.MAX_VALUE;
			var segmentLengthTotal:Number=0.0;
			var pathDistance:Number=0.0;

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
			return pathDistance+0.0;
		}

		// given a distance along the path, convert it to a point on the path
		public override  function MapPathDistanceToPoint (pathDistance:Number):Vector3
		{
			// clip or wrap given path distance according to cyclic flag
			var remaining:Number=pathDistance;
			if (cyclic)
			{
				remaining=pathDistance % totalPathLength+0.0;//FIXME: (float)fmod(pathDistance, totalPathLength);
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
			var result:Vector3=Vector3.Zero;
			for (var i:int=1; i < pointCount; i++)
			{
				segmentLength=lengths[i];
				if (segmentLength < remaining)
				{
					remaining-= segmentLength;
				}
				else
				{
					var ratio:Number=(remaining / segmentLength)+0.0;
					result=Utilities.Interpolate2(ratio,points[i - 1],points[i]);
					break;
				}
			}
			return result;
		}

		// utility methods

		// compute minimum distance from a point to a line segment
		public function PointToSegmentDistance (point:Vector3,ep0:Vector3,ep1:Vector3):Number
		{
			// convert the test point to be "local" to ep0
			local=Vector3.VectorSubtraction(point, ep0);

			// find the projection of "local" onto "segmentNormal"
			segmentProjection=segmentNormal.DotProduct(local);

			// handle boundary cases: when projection is not on segment, the
			// nearest point is one of the endpoints of the segment
			if (segmentProjection < 0)
			{
				chosen=ep0;
				segmentProjection=0;
				return Vector3.Distance(point,ep0);
			}
			if (segmentProjection > segmentLength)
			{
				chosen=ep1;
				segmentProjection=segmentLength;
				return Vector3.Distance(point,ep1);
			}

			// otherwise nearest point is projection point on segment
			chosen=Vector3.ScalarMultiplication(segmentProjection,segmentNormal);
			chosen = Vector3.VectorAddition(chosen , ep0);
			return Vector3.Distance(point,chosen);
		}

		// assessor for total path length;
		public function get TotalPathLength ():Number
		{
			return totalPathLength+0.0;
		}
	}
}