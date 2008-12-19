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
	/** A utility class implementing functions for steering
	 * 
	 */
    public class Utility
    {
        public static function interpolate( alpha:Number, x0:Vector3, x1:Vector3):Vector3
        {
            return Vector3.VectorAddition(x0 ,	(Vector3.ScalarMultiplication1(Vector3.VectorSubtraction(x1 , x0) ,alpha)));
        }

        public static function interpolate2(alpha:Number,  x0:Number, x1:Number):Number
        {
            return x0 + ((x1 - x0) * alpha);
        }

        public static function RandomUnitVectorOnXZPlane ():Vector3
        {
            var tVector:Vector3=RandomVectorInUnitRadiusSphere();
            tVector.y=0;
            tVector.Normalise();
            return tVector;
        }

        public static function RandomVectorInUnitRadiusSphere ():Vector3
        {
            var v:Vector3=Vector3.ZERO;

            do
            {
                v = new Vector3((RandomGenerator.getInstance().nextFloat() * 2) - 1,
                        (RandomGenerator.getInstance().nextFloat() * 2) - 1,
                        (RandomGenerator.getInstance().nextFloat() * 2) - 1);
            }
            while (v.Length() >= 1);

            return v;
        }

         public static function limitMaxDeviationAngle (source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
         {
             return vecLimitDeviationAngleUtility (true, // force source INSIDE cone
                                              source,
                                              cosineOfConeAngle,
                                              basis);
         }
        public static function vecLimitDeviationAngleUtility (insideOrOutside:Boolean, source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
        {
            // immediately return zero length input vectors
            var sourceLength:Number = source.Length();
            if (sourceLength == 0) return source;

            // measure the angular diviation of "source" from "basis"
            var direction:Vector3 = Vector3.ScalarDivision(source,sourceLength);
            var cosineOfSourceAngle:Number = direction.DotProduct (basis);

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
            var perp:Vector3 = perpendicularComponent(source,basis);

            // normalize that perpendicular
            var unitPerp:Vector3 = perp;
            unitPerp.Normalise();

            // construct a new vector whose length equals the source vector,
            // and lies on the intersection of a plane (formed the source and
            // basis vectors) and a cone (whose axis is "basis" and whose
            // angle corresponds to cosineOfConeAngle)
            var perpDist:Number = Number(Math.sqrt (1 - (cosineOfConeAngle * cosineOfConeAngle)));
            var c0:Vector3 = Vector3.ScalarMultiplication1(basis, cosineOfConeAngle);
            var c1:Vector3 = Vector3.ScalarMultiplication1(unitPerp, perpDist);
            return Vector3.ScalarMultiplication1(Vector3.VectorAddition(c0, c1) , sourceLength);
        }

        public static function parallelComponent ( source:Vector3,unitBasis:Vector3):Vector3
        {
            var projection:Number = source.DotProduct(unitBasis);
            return Vector3.ScalarMultiplication1(unitBasis , projection);
        }

        // return component of vector perpendicular to a unit basis vector
        // (IMPORTANT NOTE: assumes "basis" has unit magnitude (length==1))
        public static function perpendicularComponent ( source:Vector3, unitBasis:Vector3):Vector3
        {
            return Vector3.VectorSubtraction(source, parallelComponent(source,unitBasis));
        }

        public static function blendIntoAccumulator(smoothRate:Number,  newValue:Vector3, smoothedAccumulator:Vector3):Vector3
        {
            return interpolate(clip(smoothRate, 0, 1),smoothedAccumulator,newValue);
        }

        public static function blendIntoAccumulator2(smoothRate:Number,  newValue:Number, smoothedAccumulator:Number):Number
        {
            return interpolate2(clip(smoothRate, 0, 1), smoothedAccumulator, newValue);
        }

        public static function clip(x:Number, min:Number, max:Number):Number
        {
            if (x < min) 
			{
				return min;
			}
            if (x > max) 
			{
				return max;
			}
            return x;
        }

        public static function RandomUnitVector ():Vector3
        {
            var tVector:Vector3 = RandomVectorInUnitRadiusSphere();
            tVector.Normalise();
            return tVector;
        }

        public static function sphericalWrapAround (source:Vector3, center:Vector3, radius:Number):Vector3
        {
            var offset:Vector3 = Vector3.VectorSubtraction(source , center);
            var r:Number = offset.Length();

            if (r > radius)
            {
					return Vector3.VectorAddition(source , Vector3.ScalarMultiplication1(Vector3.ScalarMultiplication1(Vector3.ScalarDivision(offset, r) , radius) , -2));
			}
            else
            {
					return source;
			}
        }
    }
}
