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
	import org.papervision3d.core.math.Number3D;
	
	public class Vector3
	{
		//*********************************************************************************	
		// Variables
		//*********************************************************************************	

		// Coordinate Points in 3D Vector Space
		public var x:Number = 0.0;
		public var y:Number = 0.0;
		public var z:Number = 0.0;
		
		// Special points in Vector Space
		public static const Zero:Vector3 = new Vector3(0, 0, 0);
		public static const Up:Vector3 = new Vector3(0, 1, 0);
		public static const Left:Vector3 = new Vector3(-1, 0, 0);
		public static const Right:Vector3 = new Vector3(1, 0, 0);
		public static const Forward:Vector3 = new Vector3(0, 0, -1);
		public static const Backward:Vector3 = new Vector3(0, 0, 1);
		public static const Down:Vector3 = new Vector3(0, -1, 0);
		public static const UnitX:Vector3=new Vector3(1,0,0);
		public static const UnitY:Vector3=new Vector3(0,1,0);
		public static const UnitZ:Vector3 = new Vector3(0, 0, 1);
		public static const UnitVector:Vector3 = new Vector3(1, 1, 1);

		//*********************************************************************************	
		// Constructors
		//*********************************************************************************	

		// A mutliple constructor handler
		public function Vector3(_x:Number =0.0, _y:Number = 0.0, _z:Number =0.0) 
		{
			x = _x;
			y = _y;
			z = _z;
		}
		
		// This serves as an alternate Constructor
		// Returns a new Vector3 instance
		public function Constructor():Vector3
		{
			return new Vector3(this.x, this.y, this.z);
		}
		
		// Serves as a Copy Constructor
		public function CopyConstructor(v:Vector3):Vector3
		{
			return new Vector3(v.x, v.y, v.z);
		}

		// vector addition
		public static function VectorAddition(lvec:Vector3, rvec:Vector3):Vector3
		{
			return new Vector3(lvec.x + rvec.x, lvec.y + rvec.y, lvec.z + rvec.z);
		}

		// vector subtraction
		public static function VectorSubtraction(lvec:Vector3, rvec:Vector3):Vector3
		{
			return new Vector3(lvec.x - rvec.x, lvec.y - rvec.y, lvec.z - rvec.z);
		}

		// unary minus
		public static function Negate(vec:Vector3):Vector3
		{
			return new Vector3(-vec.x, -vec.y, -vec.z);
		}

		// vector times scalar product(scale length of vector times argument)
		public static function ScalarMultiplication(scaleFactor:Number, vec:Vector3):Vector3
		{
			return new Vector3(vec.x * scaleFactor, vec.y * scaleFactor, vec.z * scaleFactor);
		}

		// vector divided by a scalar(divide length of vector by argument)
		public static function ScalarDivision(vec:Vector3, divider:Number):Vector3
		{
			return new Vector3(vec.x / divider, vec.y / divider, vec.z / divider);
		}

		// dot product
		public function DotProduct(vec:Vector3):Number
		{
			return (this.x * vec.x) + (this.y * vec.y) + (this.z * vec.z);
		}

		// length
		public function Magnitude():Number
		{
			return Number(Math.sqrt(SquaredMagnitude()));
		}

		// length squared
		public function SquaredMagnitude():Number
		{
			return DotProduct(this);
		}

		// normalize: returns normalized version(parallel to this, length = 1)
		public function fNormalize():Vector3
		{
			// skip divide if length is zero
			var len:Number = Magnitude();
			return len > 0 ? ScalarDivision(this,len) : this;
		}

		public static function CrossProduct(lvec :Vector3, rvec:Vector3):Vector3
		{
			return new Vector3((lvec.y * rvec.z) - (lvec.z * rvec.y), (lvec.z * rvec.x) - (lvec.x * rvec.z), (lvec.x * rvec.y) - (lvec.y * rvec.x));
		}

		// set XYZ coordinates to given three floats
		public function set_XYZ(x:Number, y:Number, z:Number):Vector3
		{
			this.x = x;
			this.y = y;
			this.z = z;
			return this;
		}

		// equality/inequality
		public static function isEqual(lvec:Vector3, rvec:Vector3):Boolean
		{
			return (lvec.x == rvec.x) && (lvec.y == rvec.y) && (lvec.z == rvec.z);
		}
		public static function isNotEqual(lvec:Vector3, rvec:Vector3):Boolean
		{
			return (lvec.x != rvec.x) && (lvec.y != rvec.y) && (lvec.z != rvec.z);
		}

		public static function Distance(lvec:Vector3, rvec:Vector3):Number
		{
			return VectorSubtraction(lvec ,rvec).Magnitude();
		}

		// utility member functions used in OpenSteer

		// return component of vector parallel to a unit basis vector
		// IMPORTANT NOTE: assumes "basis" has unit magnitude (length == 1)
		public function ParallelComponent(unitBasis:Vector3):Vector3
		{
			var projection:Number = DotProduct(unitBasis);
			return ScalarMultiplication(projection,unitBasis);
		}

		// return component of vector perpendicular to a unit basis vector
		// IMPORTANT NOTE: assumes "basis" has unit magnitude(length==1)
		public function PerpendicularComponent(unitBasis:Vector3):Vector3
		{
			return VectorSubtraction(this , ParallelComponent(unitBasis));
		}

		// clamps the length of a given vector to maxLength.  If the vector is
		// shorter its value is returned unaltered, if the vector is longer
		// the value returned has length of maxLength and is paralle to the
		// original input.
		public function TruncateLength(maxLength:Number):Vector3
		{
			var maxLengthSquared:Number = maxLength * maxLength;
			var vecLengthSquared:Number = SquaredMagnitude();
			if (vecLengthSquared <= maxLengthSquared)
				return this;
			else
				return ScalarMultiplication((maxLength / Number(Math.sqrt(vecLengthSquared))),this);
		}

		// forces a 3d position onto the XZ (aka y=0) plane
		//FIXME: Misleading name
		public function SetYToZero():Vector3
		{
			return new Vector3(x, 0, z);
		}

		// rotate this vector about the global Y (up) axis by the given angle
		// takes angle:Number, sin:Number, cos:Number
		public function RotateAboutGlobalY(...args):Vector3
		{
			trace("Vector3.RotateAboutGlobalY",args[0] is Number, args[1] is Number, args[2] is Number);
			
			if (args.length == 3)
			{
				// is both are zero, they have not be initialized yet
				if (args[1] == 0 && args[2] == 0)
				{
					args[1] = Number(Math.sin(args[0]));
					args[2] = Number(Math.cos(args[0]));
				}
				return new Vector3((this.x * args[2]) + (this.z * args[1]), this.y, (this.z * args[2]) - (this.x * args[1]));
			}
			else
			{
				var s:Number = Number(Math.sin(args[0]));
				var c:Number = Number(Math.cos(args[0]));
				return new Vector3((this.x * c) + (this.z * s), (this.y), (this.z * c) - (this.z * s));
			}

		}

		// if this position is outside sphere, push it back in by one diameter
		public function SphericalWraparound(center:Vector3, radius:Number):Vector3
		{
			var offset:Vector3 = VectorSubtraction(this , center);
			var r:Number = offset.Magnitude();
			if (r > radius)
				return VectorAddition(this , ScalarMultiplication(radius * -2,ScalarDivision(offset,r)));
			else
				return this;
		}

		public function ToVertex3D():Vertex3D
		{
			return new Vertex3D(this.x, this.y, this.z);
		}
		
		public function ToNumber3D():Number3D
		{
			return new Number3D(this.x, this.y, this.z);
		}

		// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on a disk of unit radius
		// on the XZ (Y=0) plane, centered at the origin.  Orientation will be
		// random and length will range between 0 and 1
		public static function RandomVectorOnUnitRadiusXZDisk():Vector3
		{
			var v:Vector3 = new Vector3();
			do
			{
				v.set_XYZ((Math.random() * 2) - 1, 0, (Math.random() * 2) - 1);
			}
			while (v.Magnitude() >= 1);

			return v;
		}

		// Returns a position randomly distributed inside a sphere of unit radius
		// centered at the origin.  Orientation will be random and length will range
		// between 0 and 1
		public static function RandomVectorInUnitRadiusSphere():Vector3
		{
			var v:Vector3 = new Vector3();
			do
			{
				v.set_XYZ((Math.random() * 2) - 1, (Math.random() * 2) - 1, (Math.random() * 2) - 1);
			}
			while (v.Magnitude() >= 1);

			return v;
		}

		// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on the surface of a sphere
		// of unit radius centered at the origin.  Orientation will be random
		// and length will be 1
		public static function RandomUnitVector():Vector3
		{
			return RandomVectorInUnitRadiusSphere().fNormalize();
		}

		// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on a circle of unit radius
		// on the XZ (Y=0) plane, centered at the origin.  Orientation will be
		// random and length will be 1
		public static function RandomUnitVectorOnXZPlane():Vector3
		{
			return RandomVectorInUnitRadiusSphere().SetYToZero().fNormalize();
		}

		// ----------------------------------------------------------------------------
		// used by limitMaxDeviationAngle / limitMinDeviationAngle below
		public static function LimitDeviationAngleUtility(insideOrOutside:Boolean, source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
		{
			// immediately return zero length input vectors
			var sourceLength:Number = source.Magnitude();
			if (sourceLength == 0)
			{
				return source;
			}

			// measure the angular diviation of "source" from "basis"
			var direction:Vector3 = ScalarDivision(source,sourceLength);
			var cosineOfSourceAngle:Number = direction.DotProduct(basis);

			// Simply return "source" if it already meets the angle criteria.
			// (note: we hope this top "if" gets compiled out since the flag
			// is a constant when the function is inlined into its caller)
			if (insideOrOutside)
			{
				// source vector is already inside the cone, just return it
				if (cosineOfSourceAngle >= cosineOfConeAngle)
				{
					return source;
				}
			}
			else
			{
				// source vector is already outside the cone, just return it
				if (cosineOfSourceAngle <= cosineOfConeAngle)
				{
					return source;
				}
			}

			// find the portion of "source" that is perpendicular to "basis"
			var perp:Vector3 = source.PerpendicularComponent(basis);

			// normalize that perpendicular
			var unitPerp:Vector3 = perp.fNormalize();

			// construct a new vector whose length equals the source vector,
			// and lies on the intersection of a plane (formed the source and
			// basis vectors) and a cone (whose axis is "basis" and whose
			// angle corresponds to cosineOfConeAngle)
			var perpDist:Number = Number(Math.sqrt(1 - (cosineOfConeAngle * cosineOfConeAngle)));
			var c0:Vector3 = ScalarMultiplication(cosineOfConeAngle,basis);
			var c1:Vector3 = ScalarMultiplication(perpDist,unitPerp);
			return ScalarMultiplication(sourceLength,VectorAddition(c0 , c1));
		}

		// ----------------------------------------------------------------------------
		// Enforce an upper bound on the angle by which a given arbitrary vector
		// diviates from a given reference direction (specified by a unit basis
		// vector).  The effect is to clip the "source" vector to be inside a cone
		// defined by the basis and an angle.
		public static function LimitMaxDeviationAngle(source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
		{
			return LimitDeviationAngleUtility(true, // force source INSIDE cone
				source, cosineOfConeAngle, basis);
		}

		// ----------------------------------------------------------------------------
		// Enforce a lower bound on the angle by which a given arbitrary vector
		// diviates from a given reference direction (specified by a unit basis
		// vector).  The effect is to clip the "source" vector to be outside a cone
		// defined by the basis and an angle.
		public static function LimitMinDeviationAngle(source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
		{
			return LimitDeviationAngleUtility(false, // force source OUTSIDE cone
				source, cosineOfConeAngle, basis);
		}

		// ----------------------------------------------------------------------------
		// Returns the distance between a point and a line.  The line is defined in
		// terms of a point on the line ("lineOrigin") and a UNIT vector parallel to
		// the line ("lineUnitTangent")
		public static function DistanceFromLine(point:Vector3, lineOrigin:Vector3, lineUnitTangent:Vector3):Number
		{
			var offset:Vector3 = VectorSubtraction(point ,lineOrigin);
			var perp:Vector3 = offset.PerpendicularComponent(lineUnitTangent);
			return perp.Magnitude();
		}

		// ----------------------------------------------------------------------------
		// given a vector, return a vector perpendicular to it (note that this
		// arbitrarily selects one of the infinitude of perpendicular vectors)
		public static function FindPerpendicularIn3d(direction:Vector3):Vector3
		{
			// to be filled in:
			var quasiPerp:Vector3;  // a direction which is "almost perpendicular"
			var result:Vector3 = new Vector3();     // the computed perpendicular to be returned

			// three mutually perpendicular basis vectors
			var i:Vector3 = new Vector3(1, 0, 0);
			var j:Vector3 = new Vector3(0, 1, 0);
			var k:Vector3 = new Vector3(0, 0, 1);

			// measure the projection of "direction" onto each of the axes
			var id:Number = i.DotProduct(direction);
			var jd:Number = j.DotProduct(direction);
			var kd:Number = k.DotProduct(direction);

			// set quasiPerp to the basis which is least parallel to "direction"
			if ((id <= jd) && (id <= kd))
			{
				quasiPerp = i;               // projection onto i was the smallest
			}
			else
			{
				if ((jd <= id) && (jd <= kd))
					quasiPerp = j;           // projection onto j was the smallest
				else
					quasiPerp = k;           // projection onto k was the smallest
			}

			// return the cross product (direction x quasiPerp)
			// which is guaranteed to be perpendicular to both of them
			result = CrossProduct(direction, quasiPerp);
			return result;
		}
		
		// Prints the Vector 
		public function tostring():String
		{
			return("x= " + x + " y= " + y + " z= " + z);
		}
	}
}