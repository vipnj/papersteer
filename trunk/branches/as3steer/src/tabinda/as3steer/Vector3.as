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
	/** Standard 3-dimensional vector.
        @remarks
            A direction in 3D space represented as distances along the 3
            orthoganal axes (x, y, z). Note that positions, directions and
            scaling factors can be represented by a vector, depending on how
            you interpret the values.
    */
	public class Vector3
	{
		public var x:Number,y:Number,z:Number;

		// special points
		public static  var ZERO:Vector3=new Vector3(0,0,0);
		public static  var UNIT_X:Vector3=new Vector3(1,0,0);
		public static  var UNIT_Y:Vector3=new Vector3(0,1,0);
		public static  var UNIT_Z:Vector3=new Vector3(0,0,1);
		public static  var NEGATIVE_UNIT_X:Vector3=new Vector3(-1,0,0);
		public static  var NEGATIVE_UNIT_Y:Vector3=new Vector3(0,-1,0);
		public static  var NEGATIVE_UNIT_Z:Vector3=new Vector3(0,0,-1);
		public static  var UNIT_SCALE:Vector3=new Vector3(1,1,1);

		public function Vector3(... args)
		{
			if (args.length == 3)
			{
				x = args[0];
				y = args[1];
				z = args[2];
			}
			else if (args.length == 2)
			{
				x = args[0];
				y = args[1];
				z = 0;
			}
			else if (args.length == 1 && args[0] is Vector3)
			{
				x = args[0].x;
				y = args[0].y;
				z = args[0].z;
			}
			else if (args.length == 1 && args[0] is Number)
			{
				x = args[0];
				y = args[0];
				z = args[0];
			}
			else
			{
				x = 0;
				y = 0;
				z = 0;
			}
		}
		
		public function Invert():Vector3
		{
			this.x = -this.x;
			this.y = -this.y;
			this.z = -this.z;
			
			return this;
		}

		public static function Equality(lvec:Vector3,rvec:Vector3):Boolean
		{
			return (lvec.x == rvec.x && lvec.y == rvec.y && lvec.z == rvec.z);
		}

		public static function InEquality(lvec:Vector3,rvec:Vector3)
		{
			return (lvec.x != rvec.x || lvec.y != rvec.y || lvec.z != rvec.z);
		}

		// arithmetic operations
		public static function VectorAddition(lvec:Vector3,rvec:Vector3):Vector3
		{
			var kSum:Vector3=new Vector3();

			kSum.x=lvec.x + rvec.x;
			kSum.y=lvec.y + rvec.y;
			kSum.z=lvec.z + rvec.z;

			return kSum;
		}

		public static function VectorSubtraction(lvec:Vector3,rvec:Vector3):Vector3
		{
			var kDiff:Vector3=new Vector3;

			kDiff.x=lvec.x - rvec.x;
			kDiff.y=lvec.y - rvec.y;
			kDiff.z=lvec.z - rvec.z;

			return kDiff;
		}

		public static function ScalarMultiplication1(lvec:Vector3,fScalar:Number):Vector3
		{
			var kProd:Vector3=new Vector3();

			kProd.x=fScalar * lvec.x;
			kProd.y=fScalar * lvec.y;
			kProd.z=fScalar * lvec.z;

			return kProd;
		}

		public static function ScalarMultiplication2(fScalar:Number,rvec:Vector3):Vector3
		{
			var kProd:Vector3=new Vector3();

			kProd.x=fScalar * rvec.x;
			kProd.y=fScalar * rvec.y;
			kProd.z=fScalar * rvec.z;

			return kProd;
		}

		public static function VectorMultiplication(lvec:Vector3,rvec:Vector3):Vector3
		{
			var kProd:Vector3=new Vector3;

			kProd.x=lvec.x * rvec.x;
			kProd.y=lvec.y * rvec.y;
			kProd.z=lvec.z * rvec.z;

			return kProd;
		}

		public static function ScalarDivision(lvec:Vector3,fScalar:Number):Vector3
		{
			var kDiv:Vector3=new Vector3;

			var fInv:Number=1.0 / fScalar;
			kDiv.x=lvec.x * fInv;
			kDiv.y=lvec.y * fInv;
			kDiv.z=lvec.z * fInv;

			return kDiv;
		}

		public static function VectorDivision(lvec:Vector3,rvec:Vector3):Vector3
		{
			var kDiv:Vector3=new Vector3;

			kDiv.x=lvec.x / rvec.x;
			kDiv.y=lvec.y / rvec.y;
			kDiv.z=lvec.z / rvec.z;

			return kDiv;
		}

		public static function SingleVectorSubtraction(vec:Vector3):Vector3
		{
			var kNeg:Vector3=new Vector3;

			kNeg.x=- vec.x;
			kNeg.y=- vec.y;
			kNeg.z=- vec.z;

			return kNeg;
		}

		public static function ScalarAddition1(lvec:Vector3,rhs:Number):Vector3
		{
			var ret:Vector3=new Vector3(rhs);
			return ret= VectorAddition(ret,lvec);
		}

		public static function ScalarAddition2(lhs:Number,rvec:Vector3):Vector3
		{
			var ret:Vector3=new Vector3(lhs);
			return ret= VectorAddition(ret,rvec);
		}

		public static function ScalarSubtraction1(lvec:Vector3,rhs:Number):Vector3
		{
			return VectorSubtraction(lvec,new Vector3(rhs));
		}

		public static function ScalarSubtraction2(lhs:Number,rvec:Vector3):Vector3
		{
			var ret:Vector3=new Vector3(lhs);
			return ret=VectorSubtraction(ret,rvec);
		}

		/** Returns the length (magnitude) of the vector.
            @warning
                This operation requires a square root and is expensive in
                terms of CPU operations. If you don't need to know the exact
                length (e.g. for just comparing lengths) use squaredLength()
                instead.
        */
		public function Length():Number
		{
			return Number(Math.sqrt(x * x + y * y + z * z));
		}

		/** Returns the square of the length(magnitude) of the vector.
            @remarks
                This  method is for efficiency - calculating the actual
                length of a vector requires a square root, which is expensive
                in terms of the operations required. This method returns the
                square of the length of the vector, i.e. the same as the
                length but before the square root is taken. Use this if you
                want to find the longest / shortest vector without incurring
                the square root.
        */
		public function SquaredLength():Number
		{
			return x * x + y * y + z * z;
		}

		/** Calculates the dot (scalar) product of this vector with another.
            @remarks
                The dot product can be used to calculate the angle between 2
                vectors. If both are unit vectors, the dot product is the
                cosine of the angle; otherwise the dot product must be
                divided by the product of the lengths of both vectors to get
                the cosine of the angle. This result can further be used to
                calculate the distance of a point from a plane.
            @param
                vec Vector with which to calculate the dot product (together
                with this one).
            @returns
                A float representing the dot product value.
        */
		public function DotProduct(vec:Vector3):Number
		{
			return x * vec.x + y * vec.y + z * vec.z;
		}

		/** Normalises the vector.
            @remarks
                This method normalises the vector such that it's
                length / magnitude is 1. The result is called a unit vector.
            @note
                This function will not crash for zero-sized vectors, but there
                will be no changes made to their components.
            @returns The previous length of the vector.
        */
		public function Normalise():Number
		{
			var fLength:Number=Number(Math.sqrt(x * x + y * y + z * z));

			// Will also work for zero-sized vectors, but will change nothing
			if (fLength > 1e-08)
			{
				var fInvLength:Number=1.0 / fLength;
				x*= fInvLength;
				y*= fInvLength;
				z*= fInvLength;
			}

			return fLength;
		}

		/** Calculates the cross-product of 2 vectors, i.e. the vector that
            lies perpendicular to them both.
            @remarks
                The cross-product is normally used to calculate the normal
                vector of a plane, by calculating the cross-product of 2
                non-equivalent vectors which lie on the plane (e.g. 2 edges
                of a triangle).
            @param
                vec Vector which, together with this one, will be used to
                calculate the cross-product.
            @returns
                A vector which is the result of the cross-product. This
                vector will <b>NOT</b> be normalised, to maximise efficiency
                - call Vector3::normalise on the result if you wish this to
                be done. As for which side the resultant vector will be on, the
                returned vector will be on the side from which the arc from 'this'
                to rkVector is anticlockwise, e.g. UNIT_Y.CrossProduct(UNIT_Z)
                = UNIT_X, whilst UNIT_Z.CrossProduct(UNIT_Y) = -UNIT_X.
			This is because OGRE uses a right-handed coordinate system.
            @par
                For a clearer explanation, look a the left and the bottom edges
                of your monitor's screen. Assume that the first vector is the
                left edge and the second vector is the bottom edge, both of
                them starting from the lower-left corner of the screen. The
                resulting vector is going to be perpendicular to both of them
                and will go <i>inside</i> the screen, towards the cathode tube
                (assuming you're using a CRT monitor, of course).
        */
		public function CrossProduct(rkVector:Vector3):Vector3
		{
			var kCross:Vector3=new Vector3;

			kCross.x=y * rkVector.z - z * rkVector.y;
			kCross.y=z * rkVector.x - x * rkVector.z;
			kCross.z=x * rkVector.y - y * rkVector.x;

			return kCross;
		}

		/** Returns a vector at a point half way between this and the passed
            in vector.
        */
		public function MidPoint(vec:Vector3):Vector3
		{
			return new Vector3(x + vec.x * 0.5,y + vec.y * 0.5,z + vec.z * 0.5);
		}

		/** Returns true if the vector's scalar components are all greater
            that the ones of the vector it is compared against.
        */
		public static function islesser(lvec:Vector3,rvec:Vector3):Boolean
		{
			if (lvec.x < rvec.x && lvec.y < rvec.y && lvec.z < rvec.z)
			{
				return true;
			}
			return false;
		}

		/** Returns true if the vector's scalar components are all smaller
            that the ones of the vector it is compared against.
        */
		public static function isgreater(lvec:Vector3,rhs:Vector3):Boolean
		{
			if (lvec.x > rhs.x && lvec.y > rhs.y && lvec.z > rhs.z)
			{
				return true;
			}
			return false;
		}

		/** Sets this vector's components to the minimum of its own and the
            ones of the passed in vector.
            @remarks
                'Minimum' in this case means the combination of the lowest
                value of x, y and z from both vectors. Lowest is taken just
                numerically, not magnitude, so -1 < 0.
        */
		public function MakeFloor(cmp:Vector3):void
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
		}/** Sets this vector's components to the maximum of its own and the
            ones of the passed in vector.
            @remarks
                'Maximum' in this case means the combination of the highest
                value of x, y and z from both vectors. Highest is taken just
                numerically, not magnitude, so 1 > -3.
        */

		public function MakeCeil(cmp:Vector3):void
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
		}/** Generates a vector perpendicular to this vector (eg an 'up' vector).
            @remarks
                This method will return a vector which is perpendicular to this
                vector. There are an infinite number of possibilities but this
                method will guarantee to generate one of them. If you need more
                control you should use the Quaternion class.
        */

		public function Perpendicular():Vector3
		{
			var fSquareZero:Number=0.000001 * 0.000001;// 1e-06 * 1e-06;

			var perp:Vector3=this.CrossProduct(Vector3.UNIT_X);

			// Check length
			if (perp.SquaredLength() < fSquareZero)
			{
				/* This vector is the Y axis multiplied by a scalar, so we have
  		 		to use another axis.*/
				perp=this.CrossProduct(Vector3.UNIT_Y);
			}

			return perp;
		}
		
		/** Returns true if this vector is zero length. */
		public function IsZeroLength():Boolean
		{
			var sqlen:Number=x * x + y * y + z * z;
			return (sqlen < (1e-06 * 1e-06));
		}

		/** As normalise, except that this vector is unaffected and the
          * normalised vector is returned as a copy. 
		*/
		public function NormalisedCopy():Vector3
		{
			var ret:Vector3=new Vector3(this);
			ret.Normalise();
			return ret;
		}

		/** Calculates a reflection vector to the plane with the given normal .
        @remarks NB assumes 'this' is pointing AWAY FROM the plane, invert if it is not.
        */
		public function Reflect(normal:Vector3):Vector3
		{
			return new Vector3(VectorSubtraction(this,ScalarMultiplication2(2,ScalarMultiplication2(DotProduct(normal),normal))));
		}
		
		public function tostring():String
		{
			return this.x + " " + this.y + " " + this.z;
		}
	}
}