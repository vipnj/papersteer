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
	/** 
	 * A utility class implementing functions for steering
	 */
    public class Utility
    {
		/**
		 * 
		 * @param	alpha
		 * @param	x0
		 * @param	x1
		 * @return
		 */
        public static function interpolate( alpha:Number, x0:Vector3, x1:Vector3):Vector3
        {
            return Vector3.VectorAddition(x0 ,	(Vector3.ScalarMultiplication(alpha,Vector3.VectorSubtraction(x1 , x0))));
        }

        /**
         * 
         * @param	alpha
         * @param	x0
         * @param	x1
         * @return
         */
		public static function interpolate2(alpha:Number,  x0:Number, x1:Number):Number
        {
            return x0 + ((x1 - x0) * alpha);
        }

		/**
		 * 
		 * @return
		 */
        public static function RandomUnitVectorOnXZPlane ():Vector3
        {
            var tVector:Vector3=RandomVectorInUnitRadiusSphere();
            tVector.y=0;
            tVector.fNormalize();
            return tVector;
        }

		/**
		 * 
		 * @return
		 */
        public static function RandomVectorInUnitRadiusSphere ():Vector3
        {
            var v:Vector3 = new Vector3();
            do
            {
                v.x = (Math.random() * 2) - 1;
                v.y = (Math.random() * 2) - 1;
                v.z = (Math.random() * 2) - 1;
            }
            while (v.Magnitude() >= 1);

            return v;
        }

		 /**
		  * 
		  * @param	source
		  * @param	cosineOfConeAngle
		  * @param	basis
		  * @return
		  */
        public static function limitMaxDeviationAngle (source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
        {
             return vecLimitDeviationAngleUtility (true, // force source INSIDE cone
                                              source,
                                              cosineOfConeAngle,
                                              basis);
        }
		
		/**
		 * 
		 * @param	insideOrOutside
		 * @param	source
		 * @param	cosineOfConeAngle
		 * @param	basis
		 * @return
		 */
        public static function vecLimitDeviationAngleUtility (insideOrOutside:Boolean, source:Vector3, cosineOfConeAngle:Number, basis:Vector3):Vector3
        {
            // immediately return zero length input vectors
            var sourceLength:Number = source.Magnitude();
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
            unitPerp.fNormalize();

            // construct a new vector whose length equals the source vector,
            // and lies on the intersection of a plane (formed the source and
            // basis vectors) and a cone (whose axis is "basis" and whose
            // angle corresponds to cosineOfConeAngle)
            var perpDist:Number = Number(Math.sqrt (1 - (cosineOfConeAngle * cosineOfConeAngle)));
            var c0:Vector3 = Vector3.ScalarMultiplication(cosineOfConeAngle,basis);
            var c1:Vector3 = Vector3.ScalarMultiplication(perpDist,unitPerp);
            return Vector3.ScalarMultiplication(sourceLength,Vector3.VectorAddition(c0, c1));
        }

		/**
		 * 
		 * @param	source
		 * @param	unitBasis
		 * @return
		 */
        public static function parallelComponent ( source:Vector3,unitBasis:Vector3):Vector3
        {
            var projection:Number = source.DotProduct(unitBasis)
			return Vector3.ScalarMultiplication(projection,unitBasis);
        }

		/**
		 * return component of vector perpendicular to a unit basis vector
         * (IMPORTANT NOTE: assumes "basis" has unit magnitude (length==1))
		 * @param	source
		 * @param	unitBasis
		 * @return
		 */
        public static function perpendicularComponent ( source:Vector3, unitBasis:Vector3):Vector3
        {
			var temp:Vector3 = parallelComponent(source, unitBasis);
			var temp2:Vector3 = Vector3.VectorSubtraction(source, temp);
            return temp2;
        }

		/**
		 * 
		 * @param	smoothRate
		 * @param	newValue
		 * @param	smoothedAccumulator
		 * @return
		 */
        public static function blendIntoAccumulator(smoothRate:Number,  newValue:Vector3, smoothedAccumulator:Vector3):Vector3
        {
            return interpolate(clip(smoothRate, 0, 1),smoothedAccumulator,newValue);
        }

		/**
		 * 
		 * @param	smoothRate
		 * @param	newValue
		 * @param	smoothedAccumulator
		 * @return
		 */
        public static function blendIntoAccumulator2(smoothRate:Number,  newValue:Number, smoothedAccumulator:Number):Number
        {
            return interpolate2(clip(smoothRate, 0, 1), smoothedAccumulator, newValue);
        }

		/**
		 * 
		 * @param	x
		 * @param	min
		 * @param	max
		 * @return
		 */
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

		/**
		 * 
		 * @return
		 */
        public static function RandomUnitVector ():Vector3
        {
            var tVector:Vector3 = RandomVectorInUnitRadiusSphere();
            tVector.fNormalize();
            return tVector;
        }

		/**
		 * 
		 * @param	source
		 * @param	center
		 * @param	radius
		 * @return
		 */
        public static function sphericalWrapAround (source:Vector3, center:Vector3, radius:Number):Vector3
        {
            var offset:Vector3 = Vector3.VectorSubtraction(source , center);
            var r:Number = offset.Magnitude();

            if (r > radius)
            {
					return Vector3.VectorAddition(source , Vector3.ScalarMultiplication(-2,Vector3.ScalarMultiplication(radius,Vector3.ScalarDivision(offset, r))));
			}
            else
            {
					return source;
			}
        }
    }
}
