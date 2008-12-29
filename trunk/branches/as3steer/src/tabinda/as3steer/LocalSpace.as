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
	import flash.display.Sprite;
	
	/** LocalSpace: a local coordinate system for 3d space
	*
	* Provide functionality such as transforming from local space to global
	* space and vice versa.  Also regenerates a valid space from a perturbed
	* "forward vector" which is the basis of abnstract vehicle turning.
	*
	* These are comparable to a 4x4 homogeneous transformation matrix where the
	* 3x3 (R) portion is constrained to be a pure rotation (no shear or scale).
	* The rows of the 3x3 R matrix are the basis vectors of the space.  They are
	* all constrained to be mutually perpendicular and of unit length.  The top
	* ("x") row is called "side", the middle ("y") row is called "up" and the
	* bottom ("z") row is called forward.  The translation vector is called
	* "position".  Finally the "homogeneous column" is always [0 0 0 1].
	*
	*     [ R R R  0 ]      [ Sx Sy Sz  0 ]
	*     [ R R R  0 ]      [ Ux Uy Uz  0 ]
	*     [ R R R  0 ]  ->  [ Fx Fy Fz  0 ]
	*     [          ]      [             ]
	*     [ T T T  1 ]      [ Tx Ty Tz  1 ]
	* ----------------------------------------------------------------------------
	*/
	public class LocalSpace extends Sprite
	{
		private var _side:Vector3;//    side-pointing unit basis vector
		private var _up:Vector3;//  upward-pointing unit basis vector
		private var _forward:Vector3;// forward-pointing unit basis vector
		private var _position:Vector3;// origin of local space


		public function side():Vector3
		{
			return _side;
		}
		public function up():Vector3
		{
			return _up;
		}
		public function forward():Vector3
		{
			return _forward;
		}
		public function Position():Vector3
		{
			return _position;
		}

		public function setSide(...args):Vector3
		{
			if(args.length == 3)
			{
				return _side=new Vector3(args[0],args[1],args[2]);
			}
			else
			{
				return _side = args[0];
			}
		}
		
		public function setUp(...args):Vector3
		{
			if(args.length == 3)
			{
				return _up=new Vector3(args[0],args[1],args[2]);
			}
			else
			{
				return _up = args[0];
			}
		}
		
		public function setForward(...args):Vector3
		{
			if(args.length == 3)
			{
				return _forward=new Vector3(args[0],args[1],args[2]);
			}
			else
			{
				return _forward = args[0];
			}
		}
		
		public function setPosition(...args):Vector3
		{
			if(args.length == 3)
			{
				return _position=new Vector3(args[0],args[1],args[2]);
			}
			else
			{
				return _position = args[0];
			}
		}

		// use right-(or left-)handed coordinate space
		public function rightHanded():Boolean
		{
			return true;
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
		public function resetLocalSpace():void
		{
			_forward=new Vector3(0,0,1);
			_side=localRotateForwardToSide(_forward);
			_up=new Vector3(0,1,0);
			_position=new Vector3(0,0,0);
		}

		// ------------------------------------------------------------------------
		// transform a direction in global space to its equivalent in local space
		public function localizeDirection(globalDirection:Vector3):Vector3
		{
			// dot offset with local basis vectors to obtain local coordiantes
			return new Vector3(globalDirection.DotProduct(_side),
							globalDirection.DotProduct(_up),
							globalDirection.DotProduct(_forward));
		}

		// ------------------------------------------------------------------------
		// transform a point in global space to its equivalent in local space
		public function localizePosition(globalPosition:Vector3):Vector3
		{
			// global offset from local origin
			var globalOffset:Vector3=Vector3.VectorSubtraction(globalPosition,_position);
			// dot offset with local basis vectors to obtain local coordiantes
			return localizeDirection(globalOffset);
		}

		// ------------------------------------------------------------------------
		// transform a point in local space to its equivalent in global space
		public function globalizePosition(localPosition:Vector3):Vector3
		{
			return Vector3.VectorAddition(_position,globalizeDirection(localPosition));
		}
		
		// ------------------------------------------------------------------------
		// transform a direction in local space to its equivalent in global space
		public function globalizeDirection(localDirection:Vector3):Vector3
		{
			return Vector3.VectorAddition(
										Vector3.VectorAddition(Vector3.ScalarMultiplication1(_side, localDirection.x),
										Vector3.ScalarMultiplication1(_up, localDirection.y)),
										Vector3.ScalarMultiplication1(_forward,localDirection.z));
		}

		// ------------------------------------------------------------------------
		// set "side" basis vector to normalized cross product of forward and up
		public function setUnitSideFromForwardAndUp():void
		{
			// derive new unit side basis vector from forward and up
			if (rightHanded())
			{
				_side=_forward.CrossProduct(_up);
			}
			else
			{
				_side=_up.CrossProduct(_forward);
			}
			_side.Normalise();
		}

		// ------------------------------------------------------------------------
		// regenerate the orthonormal basis vectors given a new forward
		// (which is expected to have unit length)
		public function regenerateOrthonormalBasisUF(newUnitForward:Vector3):void
		{
			_forward=newUnitForward;

			// derive new side basis vector from NEW forward and OLD up
			setUnitSideFromForwardAndUp();

			// derive new Up basis vector from new Side and new Forward
			// (should have unit length since Side and Forward are
			// perpendicular and unit length)
			if (rightHanded())
			{
				_up=_side.CrossProduct(_forward);
			}
			else
			{
				_up=_forward.CrossProduct(_side);
			}
		}

		public function regenerateOrthonormalBasis(...args):void
		{
			if(args.length == 2)
			{
				_up=args[1];
				args[0].Normalise();
				regenerateOrthonormalBasis(args[0]);
			}
			else if(args.length ==1)
			{
				args[0].Normalise();
				regenerateOrthonormalBasisUF(args[0]);
			}
		}

		// ------------------------------------------------------------------------
		// rotate, in the canonical direction, a vector pointing in the
		// "forward" (+Z) direction to the "side" (+/-X) direction
		public function localRotateForwardToSide(v:Vector3):Vector3
		{
			return new Vector3(rightHanded()?- v.z:+ v.z,v.y,v.x);
		}

		// not currently used, just added for completeness
		public function globalRotateForwardToSide(globalForward:Vector3):Vector3
		{
			var localForward:Vector3=localizeDirection(globalForward);
			var localSide:Vector3=localRotateForwardToSide(localForward);
			return globalizeDirection(localSide);
		}
	}
}