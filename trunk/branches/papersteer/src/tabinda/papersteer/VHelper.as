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
    public class VHelper
    {
        // return component of vector parallel to a unit basis vector
        // IMPORTANT NOTE: assumes "basis" has unit magnitude (length == 1)
        public static function ParallelComponent(vector:Vector3, unitBasis:Vector3):Vector3
        {
            var projection:Number = vector.DotProduct(unitBasis);
            return Vector3.ScalarMultiplication(projection,unitBasis);
        }

        // return component of vector perpendicular to a unit basis vector
        // IMPORTANT NOTE: assumes "basis" has unit magnitude(length==1)
        public static function PerpendicularComponent(vector:Vector3, unitBasis:Vector3):Vector3
        {
            return Vector3.VectorSubtraction(vector , ParallelComponent(vector, unitBasis));
        }

        // clamps the length of a given vector to maxLength.  If the vector is
        // shorter its value is returned unaltered, if the vector is longer
        // the value returned has length of maxLength and is paralle to the
        // original input.
        public static function TruncateLength(vector:Vector3, maxLength:Number):Vector3
        {
            var maxLengthSquared:Number = maxLength * maxLength;
            var vecLengthSquared:Number = vector.SquaredMagnitude();
            if (vecLengthSquared <= maxLengthSquared)
                return vector;
            else
                return Vector3.ScalarMultiplication((maxLength / Number(Math.sqrt(vecLengthSquared))),vector);
        }

        // forces a 3d position onto the XZ (aka y=0) plane
        public static function SetYtoZero(vector:Vector3):Vector3
        {
            return new Vector3(vector.x, 0, vector.z);
        }

		// rotate this vector about the global Y (up) axis by the given angle
		// receives vector:Vector3, angle:Number, sin:Number, cos:Number
		public static function RotateAboutGlobalY(...args):Array
		{
			trace("VHelper.RotateAboutGlobalY",args[0] is Number, args[1] is Number, args[2] is Number, args[3] is Number);
			
			if (args.length == 4)
			{
				// is both are zero, they have not be initialized yet
				if (args[2] == 0 && args[3] == 0)
				{
					args[2] = Number(Math.sin(args[1]));
					args[3] = Number(Math.cos(args[1]));
				}
				var temp:Array = new Array();
				temp.push(args[2]);
				temp.push(args[3]);
				temp.push(new Vector3((args[0].x * c) + (args[0].z * s), (args[0].y), (args[0].z * c) - (args[0].x * s)));
				return temp;
			}
			else
			{
				var s:Number = Number(Math.sin(args[1]));
				var c:Number = Number(Math.cos(args[1]));
				temp = new Array();
				temp.push(args[2]);
				temp.push(args[3]);
				temp.push(new Vector3((args[0].x * c) + (args[0].z * s), (args[0].y), (args[0].z * c) - (args[0].x * s)));
				return temp;
			}
		}

        // if this position is outside sphere, push it back in by one diameter
        public static function SphericalWrapAround(vector:Vector3, center:Vector3, radius:Number):Vector3
        {
            var offset:Vector3 = Vector3.VectorSubtraction(vector , center);
            var r:Number = offset.Magnitude();
            if (r > radius)
                return Vector3.VectorAddition(vector , Vector3.ScalarMultiplication(radius * -2,(Vector3.ScalarDivision(offset,r))));
            else
                return vector;
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
                v.x = (Math.random() * 2) - 1;
                v.y = 0;
                v.z = (Math.random() * 2) - 1;
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
                v.x = (Math.random() * 2) - 1;
                v.y = (Math.random() * 2) - 1;
                v.z = (Math.random() * 2) - 1;
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
            var temp:Vector3 = RandomVectorInUnitRadiusSphere();
            temp.fNormalize();

            return temp;
        }

        // ----------------------------------------------------------------------------
        // Returns a position randomly distributed on a circle of unit radius
        // on the XZ (Y=0) plane, centered at the origin.  Orientation will be
        // random and length will be 1
        public static function RandomUnitVectorOnXZPlane():Vector3
        {
            var temp:Vector3 = RandomVectorInUnitRadiusSphere();

            temp.y = 0;
            temp.fNormalize();

            return temp;
        }

        // ----------------------------------------------------------------------------
        // used by limitMaxDeviationAngle / limitMinDeviationAngle below
        public static function LimitDeviationAngleUtility(insideOrOutside:Boolean, source:Vector3,cosineOfConeAngle:Number,basis:Vector3):Vector3
        {
            // immediately return zero length input vectors
            var sourceLength:Number = source.Magnitude();

            if (sourceLength == 0)
            {
				return source;
			}

            // measure the angular diviation of "source" from "basis"
            var direction:Vector3 = Vector3.ScalarDivision(source,sourceLength);

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
            else if (cosineOfSourceAngle <= cosineOfConeAngle)
            {
				 return source;
			}

            // find the portion of "source" that is perpendicular to "basis"
            var perp:Vector3 = PerpendicularComponent(source, basis);

            // normalize that perpendicular
            var unitPerp:Vector3 = perp;
            unitPerp.fNormalize();

            // construct a new vector whose length equals the source vector,
            // and lies on the intersection of a plane (formed the source and
            // basis vectors) and a cone (whose axis is "basis" and whose
            // angle corresponds to cosineOfConeAngle)
            var perpDist:Number = Number(Math.sqrt(1 - (cosineOfConeAngle * cosineOfConeAngle)));
            var c0:Vector3 = Vector3.ScalarMultiplication(cosineOfConeAngle,basis);
            var c1:Vector3 = Vector3.ScalarMultiplication(perpDist,unitPerp);
            return Vector3.ScalarMultiplication(sourceLength,Vector3.VectorAddition(c0 , c1));
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
            var offset:Vector3 = Vector3.VectorSubtraction(point , lineOrigin);
            var perp:Vector3 = VHelper.PerpendicularComponent(offset, lineUnitTangent);
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
            var i:Vector3 = Vector3.Forward;
            var j:Vector3 = Vector3.Up;
            var k:Vector3 = Vector3.Backward;

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
            result = Vector3.CrossProduct(direction, quasiPerp);

            return result;
        }
    }
}
