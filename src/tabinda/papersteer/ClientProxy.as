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
		/// This structure is a proxy for (and contains a pointer to) a client
		/// (application) obj in the spatial database.  One of these exists
		/// for each client obj.  This might be included within the
		/// structure of a client obj, or could be allocated separately.
		/// </summary>
		public class ClientProxy
		{
			// previous obj in this bin, or null
			public var Prev:ClientProxy;

			// next obj in this bin, or null
			public var Next:ClientProxy;

			// bin ID (pointer to pointer to bin contents list)
			//public ClientProxy bin;
			// bin ID (index into bin contents list)
			public var Bin:int;

			// pointer to client obj
			public var Obj:Object;

			// the obj's location ("key point") used for spatial sorting
			public var Position:Vector3;

			public function ClientProxy(obj:Object)
			{
				Obj = obj;
			}
		}
}