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
	// "token" to represent objects stored in the database
	public class TokenType implements ITokenForProximityDatabase
	{
		var bfpd:BruteForceProximityDatabase;
		var obj:Object;
		var position:Vector3D;

		// constructor
		public function TokenType (parentObject:Object,pd:BruteForceProximityDatabase):void
		{
			// store pointer to our associated database and the obj this
			// token represents, and store this token on the database's vector
			bfpd=pd;
			obj=parentObject;
			bfpd.group.push(this);
		}

		// destructor
		//FIXME: need to move elsewhere
		//~TokenType()
		public function Dispose ():void
		{
			Dispose2 (true);
			//GC.SuppressFinalize (this);
		}
		protected function Dispose2 (disposing:Boolean):void
		{
			if (obj != null)
			{
				// remove this token from the database's vector
				//bfpd.group.Find(delegate(TokenType item) { return item == this; });
				//bfpd.group.Find(delegate(TokenType item) { return item == this; });
				obj=null;
			}
		}

		// the client obj calls this each time its position changes
		public function UpdateForNewPosition (newPosition:Vector3D):void
		{
			position=newPosition;
		}

		// find all neighbors within the given sphere (as center and radius)
		public function FindNeighbors (center:Vector3D,radius:Number,results:Array):void
		{
			// loop over all tokens
			var r2:Number=radius * radius;
			for (var i:int=0; i < bfpd.group.length; i++)
			{
				var offset:Vector3D=Vector3D.VectorSubtraction(center , bfpd.group[i].position);
				var d2:Number=offset.SquaredMagnitude();

				// push onto result vector when within given radius
				if (d2 < r2)
				{
					results.push (bfpd.group[i].obj);
				}
			}
		}
	}
}