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
	public class Vector3D
	{
		//*********************************************************************************	
		// Variables
		//*********************************************************************************	

		// Coordinate Points in 3D Vector Space
		public var x:Number, y:Number, z:Number = 0.0;
		
		// Special points in Vector Space
		public static const Zero:Vector3D = new Vector3D(0, 0, 0);
		public static const Side:Vector3D = new Vector3D(-1, 0, 0);
		public static const Up:Vector3D = new Vector3D(0, 1, 0);
		public static const Forward:Vector3D = new Vector3D(0, 0, 1);
		public static const Backward:Vector3D = new Vector3D(0, 0, -1);

		//*********************************************************************************	
		// Constructors
		//*********************************************************************************	

		// A mutliple constructor handler
		public function Vector3D(... args) 
		{
			if(args.length == 3) 
			{
				x = args[0]; 
				y = args[1]; 
				z = args[2];
			} 
			else if(args.length == 2) 
			{
				x = args[0]; 
				y = args[1];
				z = 0;
			} 
			else 
			{
				x = 0; 
				y = 0; 
				z = 0;		
			}
		}
		
		// This serves as an alternate Constructor
		// Returns a new Vector3D instance
		public function Constructor():Vector3D
		{
			return new Vector3D(this.x, this.y, this.z);
		}
		
		// Serves as a Copy Constructor
		public function CopyConstructor(v:Vector3D):Vector3D
		{
			return new Vector3D(v.x, v.y, v.z);
		}

		//*********************************************************************************	
		// Operator Functions
		//*********************************************************************************	

		// Checks if a Vector is equal to another
		// Serves as an == operator
		public static function isEqual(lhs:Vector3D,rhs:Vector3D):Boolean
		{ 
			return (lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z);
		}

		// Checks if a Vector is not equal to another
		// Serves as an != operator
		public static function isNotEqual(lhs:Vector3D,rhs:Vector3D)
		{
			return (lhs.x != rhs.x || lhs.y != rhs.y || lhs.z != rhs.z);
		}
		
		// Returns true if the vector's scalar components are all greater
        // that the ones of the vector it is compared against.
		// Serves as a < operator
		public static function isLesser(lhs:Vector3D,rvec:Vector3D):Boolean
		{
			if (lhs.x < rvec.x && lhs.y < rvec.y && lhs.z < rvec.z)
			{
				return true;
			}
			return false;
		}

		// Returns true if the vector's scalar components are all smaller
        // than the ones of the vector it is compared against.
		// Serves as a > operator
		public static function isGreater(lhs:Vector3D,rhs:Vector3D):Boolean
		{
			if (lhs.x > rhs.x && lhs.y > rhs.y && lhs.z > rhs.z)
			{
				return true;
			}
			return false;
		}
		
		//*********************************************************************************	
		// Setter Functions
		//*********************************************************************************	
		
		
		public function setX(x2:Number=0.0):void
		{
			this.x = x2;
		}
		
		public function setY(y2:Number=0.0):void
		{
			this.y = y2;
		}
		
		public function setZ(z2:Number=0.0):void
		{
			this.z = z2;
		}
		
		public function getX():Number
		{
			return x;
		}
		
		public function getY():Number
		{
			return y;
		}
		
		public function getZ():Number
		{
			return z;
		}
		
		public function setXY(x2:Number=0.0,y2:Number=0.0):void
		{
			this.x = x2;
			this.y = y2;
		}
		
		public function setXYZ(x2:Number=0.0, y2:Number=0.0, z2:Number=0.0):void
		{
			this.x = x2;
			this.y = y2;
			this.z = z2;
		}
		
		public function v_setXYZ(v:Vector3D):void
		{
			this.x = v.x;
			this.y = v.y;
			this.z = v.z;
		}
		
		//*********************************************************************************		
		//  Utility Functions
		//*********************************************************************************		

		// Sets this vector's components to the minimum of its own and the
		// ones of the passed in vector.
		
		// 'Minimum' in this case means the combination of the lowest
		// value of x, y and z from both vectors. Lowest is taken just
		// numerically, not magnitude, so -1 < 0.
		public function MakeFloor(cmp:Vector3D):void
		{
			if (cmp.x < x)
			{
				x=cmp.x;
			}
			if (cmp.y < y)
			{
				y=cmp.y;
			}
			if (cmp.z < z)
			{
				z=cmp.z;
			}
		}
		
		// Sets this vector's components to the maximum of its own and the
        // ones of the passed in vector.
            
        // 'Maximum' in this case means the combination of the highest
        // value of x, y and z from both vectors. Highest is taken just
        // numerically, not magnitude, so 1 > -3.
		public function MakeCeil(cmp:Vector3D):void
		{
			if (cmp.x > x)
			{
				x=cmp.x;
			}
			if (cmp.y > y)
			{
				y=cmp.y;
			}
			if (cmp.z > z)
			{
				z=cmp.z;
			}
		}
		
		// utility member functions used in OpenSteer

		// return component of vector parallel to a unit basis vector
		// IMPORTANT NOTE: assumes "basis" has unit magnitude (length == 1)
		public function ParallelComponent(unitBasis:Vector3D):Vector3D
		{
			var projection:Number = DotProduct(unitBasis);
			return ScalarMultiplication(projection,unitBasis);
		}

		// return component of vector perpendicular to a unit basis vector
		// IMPORTANT NOTE: assumes "basis" has unit magnitude(length==1)
		public function PerpendicularComponent(unitBasis:Vector3D):Vector3D
		{
			return VectorSubtraction(this, ParallelComponent(unitBasis));
		}
		
		// Returns true if this vector is zero length.
		public function IsZeroLength():Boolean
		{
			var sqlen:Number = this.x * this.x + this.y * this.y + this.z * this.z;
			return sqlen < 0.000001 * 0.000001;
		}

		// As normalise, except that this vector is unaffected and the
        // normalised vector is returned as a copy.
		public function NormalisedCopy():Vector3D
		{
			var ret:Vector3D=new Vector3D(this);
			ret.fNormalize();
			return ret;
		}

		/*// Calculates a reflection vector to the plane with the given normal .
        // NB assumes 'this' is pointing AWAY FROM the plane, invert if it is not.
		public function Reflect(normal:Vector3D):Vector3D
		{
			return new Vector3D(VectorSubtraction(ScalarMultiplication(2, ScalarMultiplication(DotProduct(normal))), normal));
		}*/
		
		// Calculates the Magnitude of the Vector
		public function Magnitude():Number
		{
			return Number(Math.sqrt(SquaredMagnitude()));
		}
		
		// Calculates the Square of the Magnitude of a Vector
		public function SquaredMagnitude():Number
		{
			return this.x * this.x + this.y * this.y + this.z * this.z;
		}
		
		// Calculates the MidPoint of Vector
		public function VectorMidPoint(vec:Vector3D):Vector3D
		{
			return new Vector3D(this.x + vec.x * 0.5, this.y + vec.y * 0.5, this.z + vec.z * 0.5);
		}
		
		// Calculates the Normal
		public function fNormalize():Vector3D
		{
			// skip divide if length is zero
			var len:Number = Magnitude();
			return len > 0 ? UnaryScalarDivision(len) : this;
		}
		
		// Set Negative
		public function Negate():void
		{
			this.x = -this.x;
			this.y = -this.y;
			this.z = -this.z;
		}
		
		// Calculates the limiting Values
		public function Limit(max:Number=0.0):void
		{
			if (Magnitude() > max)
			{
				fNormalize();
				UnaryScalarMultiplication(max);
			}
		}
		
		// Calculates a 2 Dimensional Angle of Direction
		public function angle2D():Number
		{
			var angle:Number = 0.0;
			angle = Math.atan2( -this.y, this.x);
			return -1 * angle;
		}
		
		// Calculates the Distance of a Vector from Another
		public static function Distance(v1:Vector3D, v2:Vector3D):Number
		{
			var dx:Number = 0.0;
			dx=v1.x - v2.x;
			
			var dy:Number = 0.0;
			dy=v1.y - v2.y;
			
			var dz:Number = 0.0;
			dz=v1.z - v2.z;
			
			return Number(Math.sqrt(dx * dx + dy * dy + dz * dz));
		}
		
		// clamps the length of a given vector to maxLength.  If the vector is
		// shorter its value is returned unaltered, if the vector is longer
		// the value returned has length of maxLength and is paralle to the
		// original input.
		public function TruncateLength(maxLength:Number):Vector3D
		{
			var maxLengthSquared:Number = maxLength * maxLength;
			var vecLengthSquared:Number = SquaredMagnitude();
			if (vecLengthSquared <= maxLengthSquared)
				return this;
			else
				return ScalarMultiplication((maxLength / Number(Math.sqrt(vecLengthSquared))), this);
		}
		
		// rotate this vector about the global Y (up) axis by the given angle, 
		// param1=vec:vector3D,param2=angle:Number, param3=sin:Number,param4=cos:Number
		public static function RotateAboutGlobalY(...args):Vector3D
		{
			var temp:Vector3D;
			if (args.length == 2)
			{
				var s:Number = Number(Math.sin(args[1]));
				var c:Number = Number(Math.cos(args[1]));
				temp = new Vector3D((args[0].x * c) + (args[0].y * s), (args[0].y), (args[0].z * c) - (args[0].x * s));
			}
			else if (args.length == 4)
			{
				// is both are zero, they have not be initialized yet
				if (args[2] == 0 && args[3] == 0)
				{
					args[2] = Number(Math.sin(args[1]));
					args[3] = Number(Math.cos(args[1]));
				}
				temp= new Vector3D((args[0].x * args[3]) + (args[0].z * args[2]), args[0].y, (args[0].z * args[3]) - (args[0].x * args[2]));
			}
			return temp;
		}
		
		// if this position is outside sphere, push it back in by one diameter
		public function SphericalWraparound(center:Vector3D, radius:Number):Vector3D
		{
			var offset:Vector3D = VectorSubtraction(this, center);
			var r = offset.Magnitude();
			if (r > radius)
				return VectorAddition(this , ScalarMultiplication(radius * -2,(ScalarDivision(offset, r))));
			else
				return this;
		}
		
				// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on a disk of unit radius
		// on the XZ (Y=0) plane, centered at the origin.  Orientation will be
		// random and length will range between 0 and 1
		public static function RandomVectorOnUnitRadiusXZDisk():Vector3D
		{
			var v:Vector3D = new Vector3D();
			do
			{
				v.setXYZ((Math.random() * 2) - 1, 0, (Math.random() * 2) - 1);
			}
			while (v.Magnitude() >= 1);

			return v;
		}

		// Returns a position randomly distributed inside a sphere of unit radius
		// centered at the origin.  Orientation will be random and length will range
		// between 0 and 1
		public static function RandomVectorInUnitRadiusSphere():Vector3D
		{
			var v:Vector3D = new Vector3D();
			do
			{
				v.setXYZ((Math.random() * 2) - 1, (Math.random() * 2) - 1, (Math.random() * 2) - 1);
			}
			while (v.Magnitude() >= 1);

			return v;
		}
		
				// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on the surface of a sphere
		// of unit radius centered at the origin.  Orientation will be random
		// and length will be 1
		public static function RandomUnitVector():Vector3D
		{
			var v:Vector3D = RandomVectorInUnitRadiusSphere();
			v.fNormalize();
			return v;
		}

		// ----------------------------------------------------------------------------
		// Returns a position randomly distributed on a circle of unit radius
		// on the XZ (Y=0) plane, centered at the origin.  Orientation will be
		// random and length will be 1
		public static function RandomUnitVectorOnXZPlane():Vector3D
		{
			var v:Vector3D = RandomVectorInUnitRadiusSphere();
			v.setY(0.0);
			v.fNormalize();
			return v;
		}

		// ----------------------------------------------------------------------------
		// used by limitMaxDeviationAngle / limitMinDeviationAngle below
		public static function LimitDeviationAngleUtility(insideOrOutside:Boolean, source:Vector3D, cosineOfConeAngle:Number, basis:Vector3D):Vector3D
		{
			// immediately return zero length input vectors
			var sourceLength:Number = source.Magnitude();
			if (sourceLength == 0) return source;

			// measure the angular diviation of "source" from "basis"
			var direction:Vector3D = source.UnaryScalarDivision(sourceLength);
			var cosineOfSourceAngle:Number = direction.DotProduct(basis);

			// Simply return "source" if it already meets the angle criteria.
			// (note: we hope this top "if" gets compiled out since the flag
			// is a constant when the function is inlined into its caller)
			if (insideOrOutside)
			{
				// source vector is already inside the cone, just return it
				if (cosineOfSourceAngle >= cosineOfConeAngle) return source;
			}
			else
			{
				// source vector is already outside the cone, just return it
				if (cosineOfSourceAngle <= cosineOfConeAngle) return source;
			}

			// find the portion of "source" that is perpendicular to "basis"
			var perp:Vector3D = source.PerpendicularComponent(basis);

			// normalize that perpendicular
			var unitPerp:Vector3D = perp;
			unitPerp.fNormalize();

			// construct a new vector whose length equals the source vector,
			// and lies on the intersection of a plane (formed the source and
			// basis vectors) and a cone (whose axis is "basis" and whose
			// angle corresponds to cosineOfConeAngle)
			var perpDist:Number = Number(Math.sqrt(1 - (cosineOfConeAngle * cosineOfConeAngle)));
			var c0:Vector3D = ScalarMultiplication(cosineOfConeAngle,basis);
			var c1:Vector3D = ScalarMultiplication(perpDist,unitPerp);
			return ScalarMultiplication(sourceLength,VectorAddition(c0 , c1));
		}

		// ----------------------------------------------------------------------------
		// Enforce an upper bound on the angle by which a given arbitrary vector
		// diviates from a given reference direction (specified by a unit basis
		// vector).  The effect is to clip the "source" vector to be inside a cone
		// defined by the basis and an angle.
		public static function LimitMaxDeviationAngle(source:Vector3D, cosineOfConeAngle:Number, basis:Vector3D):Vector3D
		{
			return LimitDeviationAngleUtility(true, // force source INSIDE cone
				source, cosineOfConeAngle, basis);
		}

		// ----------------------------------------------------------------------------
		// Enforce a lower bound on the angle by which a given arbitrary vector
		// diviates from a given reference direction (specified by a unit basis
		// vector).  The effect is to clip the "source" vector to be outside a cone
		// defined by the basis and an angle.
		public static function LimitMinDeviationAngle(source:Vector3D, cosineOfConeAngle:Number, basis:Vector3D):Vector3D
		{
			return LimitDeviationAngleUtility(false, // force source OUTSIDE cone
				source, cosineOfConeAngle, basis);
		}

		// ----------------------------------------------------------------------------
		// Returns the distance between a point and a line.  The line is defined in
		// terms of a point on the line ("lineOrigin") and a UNIT vector parallel to
		// the line ("lineUnitTangent")
		public static function DistanceFromLine(point:Vector3D, lineOrigin:Vector3D, lineUnitTangent:Vector3D):Number
		{
			var offset:Vector3D = VectorSubtraction(point, lineOrigin);
			var perp:Vector3D = offset.PerpendicularComponent(lineUnitTangent);
			return perp.Magnitude();
		}

		// ----------------------------------------------------------------------------
		// given a vector, return a vector perpendicular to it (note that this
		// arbitrarily selects one of the infinitude of perpendicular vectors)
		public static function FindPerpendicularIn3d(direction:Vector3D):Vector3D
		{
			// to be filled in:
			var quasiPerp:Vector3D;  // a direction which is "almost perpendicular"
			var result:Vector3D = new Vector3D();     // the computed perpendicular to be returned

			// three mutually perpendicular basis vectors
			var i:Vector3D = new Vector3D(1, 0, 0);
			var j:Vector3D = new Vector3D(0, 1, 0);
			var k:Vector3D = new Vector3D(0, 0, 1);

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
			result = direction.CrossProduct(quasiPerp);
			return result;
		}
		
		// Calculates the dot (scalar) product of this vector with another.
        //
        // The dot product can be used to calculate the angle between 2
        // vectors. If both are unit vectors, the dot product is the
        // cosine of the angle; otherwise the dot product must be
        // divided by the product of the lengths of both vectors to get
        // the cosine of the angle. This result can further be used to
        // calculate the distance of a point from a plane.

		public function DotProduct(vec:Vector3D):Number
		{
			return this.x * vec.x + this.y * vec.y + this.z * vec.z;
		}
		
		// Calculates the cross-product of 2 vectors, i.e. the vector that
        // lies perpendicular to them both.
        
        // The cross-product is normally used to calculate the normal
        // vector of a plane, by calculating the cross-product of 2
        // non-equivalent vectors which lie on the plane (e.g. 2 edges
        // of a triangle).
        
        // Returns a vector which is the result of the cross-product. This
        // vector will <b>NOT</b> be normalised, to maximise efficiency
        // - call Vector3::normalise on the result if you wish this to
        // be done. As for which side the resultant vector will be on, the
        // returned vector will be on the side from which the arc from 'this'
        // to rkVector is anticlockwise, e.g. UNIT_Y.CrossProduct(UNIT_Z)
        // = UNIT_X, whilst UNIT_Z.CrossProduct(UNIT_Y) = -UNIT_X.
		// This is because PV3D uses a right-handed coordinate system.

		public function CrossProduct(rkVector:Vector3D):Vector3D
		{
			var kCross:Vector3D = new Vector3D();

			kCross.x=this.y * rkVector.z - this.z * rkVector.y;
			kCross.y=this.z * rkVector.x - this.x * rkVector.z;
			kCross.z=this.x * rkVector.y - this.y * rkVector.x;

			return kCross;
		}
		
		//**************************************************************************************		
		// Arithmetic Functions
		//**************************************************************************************
		
		// Serves as Vector Addition but takes on 1 argument
		public function UnaryVectorAddition(v:Vector3D):Vector3D
		{
			this.x += v.x;
			this.y += v.y;
			this.z += v.z;
			return this;
		}
		
		// Same as above but takes two vectors as arguments
		public static function VectorAddition(v1:Vector3D, v2:Vector3D):Vector3D 
		{
    		var v:Vector3D = new Vector3D(v1.x + v2.x,v1.y + v2.y, v1.z + v2.z);
   			return v;
  		}
		
		// Serves as Vector Subtraction but takes on 1 argument
		public function UnaryVectorSubtraction(v:Vector3D):void
		{
			this.x -= v.x;
			this.y -= v.y;
			this.z -= v.z;
		}
		
		// Same as above but takes two vectors as arguments
 	 	public static function VectorSubtraction(v1:Vector3D, v2:Vector3D):Vector3D 
		{
    		var v:Vector3D = new Vector3D(v1.x - v2.x,v1.y - v2.y,v1.z - v2.z);
    		return v;
  		}
		
		// This function does Scalar Multiplication and takes a 
		// scalar component as the argument
		public function UnaryScalarMultiplication(n:Number=0.0):Vector3D
		{
			this.x *= n;
			this.y *= n;
			this.z *= n;
			return this;
		}
		
		// This function is same as the above but takes two arguments
		// A scalar component and the Vector to multiply it with
		public static function ScalarMultiplication(n:Number,vec:Vector3D):Vector3D
		{
			vec.x *= n;
			vec.y *= n;
			vec.z *= n;
			
			return vec;
		}
				
		// This function does Scalar Division and takes a 
		// scalar component as the argument
		public function UnaryScalarDivision(n:Number):Vector3D
		{
			if (n == 0.0)
			{
				return new Vector3D();
			}
			this.x /= n;
			this.y /= n;
			this.z /= n;
			return this;
		}
		
		// This function is same as the above but takes two arguments
		// A scalar component and the Vector to divide it from
		public static function ScalarDivision(lvec:Vector3D,fScalar:Number):Vector3D
		{
			var kDiv:Vector3D=new Vector3D;

			var fInv:Number=1.0 / fScalar;
			kDiv.x=lvec.x * fInv;
			kDiv.y=lvec.y * fInv;
			kDiv.z=lvec.z * fInv;

			return kDiv;
		}
		
		// Prints the Vector 
		public function tostring():String
		{
			return("x= " + x + " y= " + y + " z= " + z + "\n");
		}
	}
}