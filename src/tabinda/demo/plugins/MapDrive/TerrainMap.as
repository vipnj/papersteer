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

package tabinda.demo.plugins.MapDrive
{
	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class TerrainMap
	{
		public function TerrainMap (c:Vector3,x:Number,z:Number,r:int)
		{
			center=c;
			xSize=x;
			zSize=z;
			resolution=r;
			outsideValue=false;

			map=new Vector.<Boolean>(resolution * resolution);
			for (var i:int=0; i < resolution * resolution; i++)
			{
				map[i]=false;
			}
		}

		// clear the map (to false)
		public function Clear ():void
		{
			for (var i:int=0; i < resolution; i++)
			{
				for (var j:int=0; j < resolution; j++)
				{
					SetMapBit (i,j,false);
				}
			}

		}// get and set a bit based on 2d integer map index
		public function GetMapBit (i:int,j:int):Boolean
		{
			return map[MapAddress(i,j)];
		}

		public function SetMapBit (i:int,j:int,value:Boolean):Boolean
		{
			return map[MapAddress(i,j)]=value;
		}

		// get a value based on a position in 3d world space
		public function GetMapValue (point:Vector3):Boolean
		{
			var local:Vector3=Vector3.VectorSubtraction(point , center);
			local.y=0;
			var localXZ:Vector3=local;

			var hxs:Number=xSize / 2;
			var hzs:Number=zSize / 2;

			var x:Number=localXZ.x;
			var z:Number=localXZ.z;

			var isOut:Boolean=(x > + hxs) || (x < - hxs) || (z > + hzs) || (z < - hzs);

			if (isOut)
			{
				return outsideValue;
			}
			else
			{
				var r:Number=Number(resolution);
				var i:int=int(Utilities.RemapInterval(x,- hxs,hxs,0.0,r));
				var j:int=int(Utilities.RemapInterval(z,- hzs,hzs,0.0,r));
				return GetMapBit(i,j);
			}
		}

		public function MinSpacing ():Number
		{
			return Math.min(xSize,zSize) / Number(resolution);
		}

		// used to detect if vehicle body is on any obstacles
		public function ScanLocalXZRectangle (localSpace:ILocalSpace,xMin:Number,xMax:Number,zMin:Number,zMax:Number):Boolean
		{
			var spacing:Number=MinSpacing() / 2;

			for (var x:Number=xMin; x < xMax; x+= spacing)
			{
				for (var z:Number=zMin; z < zMax; z+= spacing)
				{
					var sample:Vector3=new Vector3(x,0,z);
					var global:Vector3=localSpace.GlobalizePosition(sample);
					if (GetMapValue(global))
					{
						return true;
					}
				}
			}
			return false;
		}

		// Scans along a ray (directed line segment) on the XZ plane, sampling
		// the map for a "true" cell.  Returns the index of the first sample
		// that gets a "hit", or zero if no hits found.
		public function ScanXZray (origin:Vector3,sampleSpacing:Vector3,sampleCount:int):int
		{
			var samplePoint:Vector3=origin;

			for (var i:int=1; i <= sampleCount; i++)
			{
				samplePoint = Vector3.VectorAddition(samplePoint,sampleSpacing);
				if (GetMapValue(samplePoint))
				{
					return i;
				}
			}

			return 0;
		}

		public function Cellwidth ():int
		{
			return resolution;
		}// xxx cwr
		public function Cellheight ():int
		{
			return resolution;
		}// xxx cwr
		public function IsPassable (point:Vector3):Boolean
		{
			return ! GetMapValue(point);
		}

		public var center:Vector3;
		public var xSize:Number;
		public var zSize:Number;
		public var resolution:int;

		public var outsideValue:Boolean;

		private function MapAddress (i:int,j:int):int
		{
			return i + (j * resolution);
		}

		private var map:Vector.<Boolean>;
	}
}