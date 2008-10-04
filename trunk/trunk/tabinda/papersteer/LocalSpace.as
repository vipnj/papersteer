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
	import tabinda.papersteer.Vector3D;
	
	/// <summary>
	/// LocalSpaceMixin is a mixin layer, a class template with a paramterized base
	/// class.  Allows "LocalSpace-ness" to be layered on any class.
	/// </summary>
	public class LocalSpace implements ILocalSpace
	{
		// transformation as three orthonormal unit basis vectors and the
		// origin of the local space.  These correspond to the "rows" of
		// a 3x4 transformation matrix with [0 0 0 1] as the final column

        var _side:Vector3D;     //    side-pointing unit basis vector
        var _up:Vector3D;       //  upward-pointing unit basis vector
        var _forward:Vector3D;  // forward-pointing unit basis vector
        var _position:Vector3D; // origin of local space
		
		/// <summary>
		/// Gets or sets the side.
		/// </summary>
		public function get Side ():Vector3D
		{
			return _side;
		}
		public function set Side (val:Vector3D):void
		{
			_side = val;
		}

		/// <summary>
		/// Gets or sets the up.
		/// </summary>
		public function get Up ():Vector3D
		{
			return _up;
		}
		public function set Up (val:Vector3D):void
		{
			_up = val;
		}
		/// <summary>
		/// Gets or sets the forward.
		/// </summary>
		public function get Forward ():Vector3D
		{
			return _forward;
		}
		public function set Forward (val:Vector3D):void
		{
			_forward = val;
		}
		/// <summary>
		/// Gets or sets the position.
		/// </summary>
		public function get Position ():Vector3D
		{
			return _position;
		}
		public function set Position (val:Vector3D):void
		{
			_position = val;
		}
		
		public function SetUp (x:Number,y:Number,z:Number):Vector3D
		{
			_up.x=x;
			_up.y=y;
			_up.z=z;

			return _up;
		}
		public function SetForward (x:Number,y:Number,z:Number):Vector3D
		{
			_forward.x=x;
			_forward.y=y;
			_forward.z=z;

			return _forward;
		}
		public function SetPosition (x:Number,y:Number,z:Number):Vector3D
		{
			_position.x=x;
			_position.y=y;
			_position.z=z;

			return _position;
		}

		// ------------------------------------------------------------------------
		// Global compile-time switch to control handedness/chirality: should
		// LocalSpace use a left- or right-handed coordinate system?  This can be
		// overloaded in derived types (e.g. vehicles) to change handedness.
		public function get IsRightHanded ():Boolean
		{
			return true;
		}

		// ------------------------------------------------------------------------
		// constructor

		// Takes param1=up, param2=forward, param3=position, param4=side=can be null
		public function LocalSpace (...args):void
		{
			if (args.length == 4)
			{
				_up = args[0];
				_forward=args[1];
				_position = args[2];
				_side=args[3];
			}
			else if (args.length == 3)
			{
				_up= args[0];
				_forward=args[1];;
				_position=args[2];;
				SetUnitSideFromForwardAndUp();
			}
			else
			{
				ResetLocalSpace();
			}
		}

		// ------------------------------------------------------------------------
		// reset transform: set local space to its identity state, equivalent to a
		// 4x4 homogeneous transform like this:
		//
		//     [ X 0 0 0 ]
		//     [ 0 1 0 0 ]
		//     [ 0 0 1 0 ]
		//     [ 0 0 0 1 ]
		//
		// where X is 1 for a left-handed system and -1 for a right-handed system.
		public function ResetLocalSpace ():void
		{
			_forward=Vector3D.Backward;
			_side=LocalRotateForwardToSide(Vector3D.Forward);
			_up=Vector3D.Up;
			_position=Vector3D.Zero;
		}

		// ------------------------------------------------------------------------
		// transform a direction in global space to its equivalent in local space
		public function LocalizeDirection (globalDirection:Vector3D):Vector3D
		{
			// dot offset with local basis vectors to obtain local coordiantes
			return new Vector3D(_side.DotProduct(globalDirection),_up.DotProduct(globalDirection),_forward.DotProduct(globalDirection));
		}

		// ------------------------------------------------------------------------
		// transform a point in global space to its equivalent in local space
		public function LocalizePosition (globalPosition:Vector3D):Vector3D
		{
			// global offset from local origin
			var globalOffset:Vector3D = Vector3D.VectorSubtraction(globalPosition, _position);

			// dot offset with local basis vectors to obtain local coordiantes
			return LocalizeDirection(globalOffset);
		}

		// ------------------------------------------------------------------------
		// transform a point in local space to its equivalent in global space
		public function GlobalizePosition (localPosition:Vector3D):Vector3D
		{
			return Vector3D.VectorAddition(_position, GlobalizeDirection(localPosition));
		}

		// ------------------------------------------------------------------------
		// transform a direction in local space to its equivalent in global space
		public function GlobalizeDirection (localDirection:Vector3D):Vector3D
		{
			return Vector3D.VectorAddition(Vector3D.VectorAddition(Vector3D.ScalarMultiplication(localDirection.x, _side),Vector3D.ScalarMultiplication(localDirection.y,_up)), Vector3D.ScalarMultiplication(localDirection.z,_forward));
		}

		// ------------------------------------------------------------------------
		// set "side" basis vector to normalized cross product of forward and up
		public function SetUnitSideFromForwardAndUp ():void
		{
			// derive new unit side basis vector from forward and up
			if (IsRightHanded)
			{
				_side=_forward.CrossProduct(_up);
			}
			else
			{
				_side=_up.CrossProduct(_forward);

			}
			_side.fNormalize();
		}

		// ------------------------------------------------------------------------
		// regenerate the orthonormal basis vectors given a new forward
		//(which is expected to have unit length)
		public function RegenerateOrthonormalBasisUF (newUnitForward:Vector3D):void
		{
			_forward=newUnitForward;

			// derive new side basis vector from NEW forward and OLD up
			SetUnitSideFromForwardAndUp();

			// derive new Up basis vector from new Side and new Forward
			//(should have unit length since Side and Forward are
			// perpendicular and unit length)
			if (IsRightHanded)
			{
				_up=_side.CrossProduct(_forward);
			}
			else
			{
				_up=_forward.CrossProduct(_side);
			}
		}

		// for when the new forward is NOT know to have unit length
		public function RegenerateOrthonormalBasis (newForward:Vector3D):void
		{
			newForward.fNormalize ();

			RegenerateOrthonormalBasisUF (newForward);
		}

		// for supplying both a new forward and and new up
		public function RegenerateOrthonormalBasis2 (newForward:Vector3D,newUp:Vector3D):void
		{
			_up=newUp;
			newForward.fNormalize ();
			RegenerateOrthonormalBasis (newForward);
		}

		// ------------------------------------------------------------------------
		// rotate, in the canonical direction, a vector pointing in the
		// "forward"(+Z) direction to the "side"(+/-X) direction
		public function LocalRotateForwardToSide (val:Vector3D):Vector3D
		{
			return new Vector3D(IsRightHanded?- val.z:+ val.z,val.y,val.x);
		}

		// not currently used, just added for completeness
		public function GlobalRotateForwardToSide (val:Vector3D):Vector3D
		{
			var localForward:Vector3D=LocalizeDirection(val);
			var localSide:Vector3D=LocalRotateForwardToSide(localForward);
			return GlobalizeDirection(localSide);
		}
	}
}