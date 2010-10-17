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

package tabinda.demo
{
	import flash.display.DisplayObject;
	import flash.display.LineScaleMode;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	import org.papervision3d.core.render.command.RenderTriangle;
	import org.papervision3d.materials.WireframeMaterial;
	import org.papervision3d.Papervision3D;
	
	import org.papervision3d.core.proto.*;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.objects.primitives.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	
	import tabinda.papersteer.*;
	
	public class Drawing implements IDraw
	{
		public static var localSpace:LocalSpace = new LocalSpace();
		public static var demo:Demo = null;
		
		// Papervision3D variables
		public static var colMaterial : ColorMaterial = new ColorMaterial(0x000000, 1);						// Color Material
		public static var lines:Lines3D = new Lines3D(new LineMaterial(0x000000,1), "Lines");				// Lines Object that holds all the lines
		
		public static function init():void
		{
			
		}
		
		public static function iDrawLine(startPoint:Vector3, endPoint:Vector3, color:uint ):void
		{
			lines.addLine(new Line3D(lines, new LineMaterial(color,1),1,new Vertex3D(startPoint.x,startPoint.y,startPoint.z),new Vertex3D(endPoint.x,endPoint.y,endPoint.z)));
		}
		
		public function BeginDoubleSidedDrawing(mat:MaterialObject3D):void
		{
			mat.doubleSided = true;
		}
		
		public function EndDoubleSidedDrawing(mat:MaterialObject3D):void
		{
			mat.doubleSided = false;
		}

		private static function iDrawTriangle(a:Vector3, b:Vector3, c:Vector3, color:uint):void
		{
			//var tri:Triangle3D = new Triangle3D(new DisplayObject3D(), new Array([new Vector3(a.x, a.y, a.z), new Vector3(b.x, b.y, b.z), new Vector3(c.x, c.y, c.z)]), new MaterialObject3D());
		}

		// Draw a single OpenGL quadrangle given four Vector3 vertices, and color.
		private static function iDrawQuadrangle( a:Vector3,  b:Vector3,  c:Vector3, d:Vector3,  color:uint):void
		{
			
			//var p:Plane = new Plane(colMaterial, 5, 5, 1, 1);
			//p.x = v.x;
			//p.y = v.y;
			//p.z = v.z;
			//demo.scene.addChild(p);
		}

		public function Line( startPoint:Vector3, endPoint:Vector3,  color:uint):void
		{
			DrawLine(startPoint, endPoint, color);
		}

		// draw a line with alpha blending
		public function LineAlpha(startPoint:Vector3,  endPoint:Vector3, color:uint, alpha:Number):void
		{
			DrawLineAlpha(startPoint, endPoint, color, alpha);
		}

		public function  CircleOrDisk( radius:Number, axis:Vector3, center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void
		{
			DrawCircleOrDisk(radius, axis, center, color, segments, filled, in3d);
		}

		public static function  DrawLine( startPoint:Vector3,  endPoint:Vector3,  color:uint):void
		{
			if (Demo.IsDrawPhase == true)
			{
				iDrawLine(startPoint, endPoint, color);
			}
			else
			{
				DeferredLine.AddToBuffer(startPoint, endPoint, color);
			}
		}

		// draw a line with alpha blending
		public static function DrawLineAlpha( startPoint:Vector3, endPoint:Vector3, color:uint, alpha:Number):void
		{
			var c:uint = color;
			if (Demo.IsDrawPhase == true)
			{
				iDrawLine(startPoint, endPoint, c);
			}
			else
			{
				DeferredLine.AddToBuffer(startPoint, endPoint, c);
			}
		}

		// draw 2d lines in screen space: x and y are the relevant coordinates
		public static function  Draw2dLine(startPoint:Vector3,  endPoint:Vector3,color:uint):void
		{
			iDrawLine(startPoint, endPoint, color);
		}

		// draws a "wide line segment": a rectangle of the given width and color
		// whose mid-line connects two given endpoints
		public static function DrawXZWideLine( startPoint:Vector3, endPoint:Vector3,PathMesh:TriangleMesh3D,uvArr:Array, color:uint,width:Number):void
		{
			var offset:Vector3 = Vector3.VectorSubtraction(endPoint , startPoint);
			offset.fNormalize();
            var perp:Vector3 = localSpace.LocalRotateForwardToSide(offset);
			var radius:Vector3 = Vector3.ScalarDivision(perp,width / 2);

			var a:Vertex3D = Vector3.VectorAddition(startPoint , radius).ToVertex3D();
			var b:Vertex3D = Vector3.VectorAddition(endPoint , radius).ToVertex3D();
			var c:Vertex3D = Vector3.VectorSubtraction(endPoint , radius).ToVertex3D();
			var d:Vertex3D = Vector3.VectorSubtraction(startPoint , radius).ToVertex3D();
			
			PathMesh.geometry.vertices.push(a);
			PathMesh.geometry.vertices.push(b);
			PathMesh.geometry.vertices.push(c);
			PathMesh.geometry.vertices.push(d);
			
			PathMesh.geometry.faces.push(new Triangle3D(PathMesh, new Array(a, b, c, d), new ColorMaterial(color), uvArr));
						
			//iDrawQuadrangle(a, b, c, d, color);
		}

		// draw a (filled-in, polygon-based) square checkerboard grid on the XZ
		// (horizontal) plane.
		//
		// ("size" is the length of a side of the overall grid, "subsquares" is the
		// number of subsquares along each edge (for example a standard checkboard
		// has eight), "center" is the 3d position of the center of the grid,
		// color1 and color2 are used for alternating subsquares.)
		public static function DrawXZCheckerboardGrid(GridMesh:TriangleMesh3D,size:Number, subsquares:int,  center:Vector3, color1:uint,  color2:uint):void
		{			
			var gridX    :Number = subsquares;
			var gridY    :Number = subsquares;
			var gridX1   :Number = gridX + 1;
			var gridY1   :Number = gridY + 1;
	
			var vertices :Array  = GridMesh.geometry.vertices;
			var faces    :Array  = GridMesh.geometry.faces;
	
			var textureX :Number = size /2;
			var textureY :Number = size /2;
	
			var iW       :Number = size / gridX;
			var iH       :Number = size / gridY;
	
			// Vertices
			for( var ix:int = 0; ix < gridX + 1; ix++ )
			{
				for( var iy:int = 0; iy < gridY1; iy++ )
				{
					var x :Number = ix * iW - textureX;
					var y :Number = iy * iH - textureY;
	
					vertices.push( new Vertex3D( x, y, 0 ) );
				}
			}
	
			// Faces
			var uvA :NumberUV;
			var uvC :NumberUV;
			var uvB :NumberUV;
	
			for(  ix = 0; ix < gridX; ix++ )
			{
				for(  iy= 0; iy < gridY; iy++ )
				{
					// Triangle A
					var a:Vertex3D = vertices[ ix     * gridY1 + iy     ];
					var c:Vertex3D = vertices[ ix     * gridY1 + (iy+1) ];
					var b:Vertex3D = vertices[ (ix+1) * gridY1 + iy     ];
	
					uvA =  new NumberUV( ix     / gridX, iy     / gridY );
					uvC =  new NumberUV( ix     / gridX, (iy+1) / gridY );
					uvB =  new NumberUV( (ix+1) / gridX, iy     / gridY );
	
					faces.push(new Triangle3D(GridMesh, [ a, b, c ], new ColorMaterial(0x000000), [ uvA, uvB, uvC ] ) );
	
					// Triangle B
					a = vertices[ (ix+1) * gridY1 + (iy+1) ];
					c = vertices[ (ix+1) * gridY1 + iy     ];
					b = vertices[ ix     * gridY1 + (iy+1) ];
	
					uvA =  new NumberUV( (ix+1) / gridX, (iy+1) / gridY );
					uvC =  new NumberUV( (ix+1) / gridX, iy      / gridY );
					uvB =  new NumberUV( ix      / gridX, (iy+1) / gridY );
					
					faces.push(new Triangle3D(GridMesh, [ a, b, c ], new ColorMaterial(0xffffff), [ uvA, uvB, uvC ] ) );
				}
			}
	
			GridMesh.geometry.ready = true;
			
			if(Papervision3D.useRIGHTHANDED)
				GridMesh.geometry.flipFaces();
		}

		// draw a square grid of lines on the XZ (horizontal) plane.
		//
		// ("size" is the length of a side of the overall grid, "subsquares" is the
		// number of subsquares along each edge (for example a standard checkboard
		// has eight), "center" is the 3d position of the center of the grid, lines
		// are drawn in the specified "color".)
		public static function DrawXZLineGrid(size:Number,subsquares:int,center:Vector3, color:uint):void
		{
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			// draw a square XZ grid with the given size and line count
			var q:Number = -half;
			for (var i:int = 0; i < (subsquares + 1); i++)
			{
				var x1:Vector3 = new Vector3(q, 0, +half); // along X parallel to Z
				var x2:Vector3 = new Vector3(q, 0, -half);
				var z1:Vector3 = new Vector3(+half, 0, q); // along Z parallel to X
				var z2:Vector3 = new Vector3(-half, 0, q);
				
				lines.addLine(new Line3D(lines, new LineMaterial(color,1), 2, x1 + center, x2 + center));
				lines.addLine(new Line3D(lines, new LineMaterial(color,1), 2, z1 + center, z2 + center));
								
				q += spacing;
			}
		}

		// draw the three axes of a LocalSpace: three lines parallel to the
		// basis vectors of the space, centered at its origin, of lengths
		// given by the coordinates of "size".
		public static function DrawAxes( ls:ILocalSpace, size:Vector3, color:uint):void
		{
			var x:Vector3 = new Vector3(size.x / 2, 0, 0);
			var y:Vector3 = new Vector3(0, size.y / 2, 0);
			var z:Vector3 = new Vector3(0, 0, size.z / 2);

			iDrawLine(ls.GlobalizePosition(x), ls.GlobalizePosition(Vector3.ScalarMultiplication(-1,x)), color);
			iDrawLine(ls.GlobalizePosition(y), ls.GlobalizePosition(Vector3.ScalarMultiplication(-1,y)), color);
			iDrawLine(ls.GlobalizePosition(z), ls.GlobalizePosition(Vector3.ScalarMultiplication(-1,z)), color);
		}

		public static function DrawQuadrangle( a:Vector3,  b:Vector3,  c:Vector3,  d:Vector3,  color:uint):void
		{
			iDrawQuadrangle(a, b, c, d, color);
		}

		// draw the edges of a box with a given position, orientation, size
		// and color.  The box edges are aligned with the axes of the given
		// LocalSpace, and it is centered at the origin of that LocalSpace.
		// "size" is the main diagonal of the box.
		//
		// use gGlobalSpace to draw a box aligned with global space
		public static function DrawBoxOutline(localSpace:ILocalSpace, size:Vector3, color:uint):void
		{
			var s:Vector3 = Vector3.ScalarDivision(size,2.0);  // half of main diagonal

			var a:Vector3 = new Vector3(+s.x, +s.y, +s.z);
			var b:Vector3 = new Vector3(+s.x, -s.y, +s.z);
			var c:Vector3 = new Vector3(-s.x, -s.y, +s.z);
			var d:Vector3 = new Vector3(-s.x, +s.y, +s.z);

			var e:Vector3 = new Vector3(+s.x, +s.y, -s.z);
			var f:Vector3 = new Vector3(+s.x, -s.y, -s.z);
			var g:Vector3 = new Vector3(-s.x, -s.y, -s.z);
			var h:Vector3 = new Vector3(-s.x, +s.y, -s.z);

			var A:Vector3 = localSpace.GlobalizePosition(a);
			var B:Vector3 = localSpace.GlobalizePosition(b);
			var C:Vector3 = localSpace.GlobalizePosition(c);
			var D:Vector3 = localSpace.GlobalizePosition(d);

			var E:Vector3 = localSpace.GlobalizePosition(e);
			var F:Vector3 = localSpace.GlobalizePosition(f);
			var G:Vector3 = localSpace.GlobalizePosition(g);
			var H:Vector3 = localSpace.GlobalizePosition(h);

			iDrawLine(A, B, color);
			iDrawLine(B, C, color);
			iDrawLine(C, D, color);
			iDrawLine(D, A, color);

			iDrawLine(A, E, color);
			iDrawLine(B, F, color);
			iDrawLine(C, G, color);
			iDrawLine(D, H, color);

			iDrawLine(E, F, color);
			iDrawLine(F, G, color);
			iDrawLine(G, H, color);
			iDrawLine(H, E, color);
		}

		public static function  DrawXZCircle( radius:Number, center:Vector3, color:uint, segments:int):void
		{
			DrawXZCircleOrDisk(radius, center, color, segments, false);
		}

		public static function DrawXZDisk(radius:Number, center:Vector3, color:uint, segments:int):void
		{
			DrawXZCircleOrDisk(radius, center, color, segments, true);
		}

		// drawing utility used by both drawXZCircle and drawXZDisk
		public static function DrawXZCircleOrDisk(radius:Number, center:Vector3, color:uint, segments:int, filled:Boolean):void
		{
			// draw a circle-or-disk on the XZ plane
			DrawCircleOrDisk(radius, Vector3.Zero, center, color, segments, filled, false);
		}

		// a simple 2d vehicle on the XZ plane
		public static function DrawBasic2dCircularVehicle(vehicle:IVehicle,CtfMesh:TriangleMesh3D,triArr:Vector.<Triangle3D>,uvArr:Array, color:uint):void
		{
			// "aspect ratio" of body (as seen from above)
			var x:Number = 0.5;
			var y:Number = Number(Math.sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = vehicle.Radius;
			var p:Vector3 = vehicle.Position;

			// shape of triangular body
			var u:Vector3 = Vector3.ScalarMultiplication((r * 0.05),new Vector3(0, 1, 0)); // slightly up
			var f:Vector3 = Vector3.ScalarMultiplication(r,vehicle.Forward);
			var s:Vector3 = Vector3.ScalarMultiplication(x * r, vehicle.Side);
			var b:Vector3 = Vector3.ScalarMultiplication(-y*r,vehicle.Forward);

			// draw double-sided triangle (that is: no (back) face culling)
			CtfMesh.geometry.vertices.push(u.ToVertex3D(), f.ToVertex3D(), s.ToVertex3D(), b.ToVertex3D());
			
			var temp:Array = new Array();
			var a:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , f) , u).ToVertex3D();
			var d:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			var e:Vertex3D = Vector3.VectorAddition( Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)).ToVertex3D();
			
			CtfMesh.geometry.faces.push(new Triangle3D(CtfMesh,new Array(a,d,e), new ColorMaterial(color), uvArr));
			
			/*iDrawTriangle(Vector3.VectorAddition(Vector3.VectorAddition(p , f) , u),
						  Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)),
						  Vector3.VectorAddition( Vector3.VectorAddition(p , b) , Vector3.VectorAddition(s , u)),
						   color);
			

			// draw the circular collision boundary
			DrawXZCircle(r, Vector3.VectorAddition(p , u), Colors.White, 20);*/
			
			CtfMesh.geometry.ready = true;
			if (Papervision3D.useRIGHTHANDED) CtfMesh.geometry.flipFaces();
		}

		// a simple 3d vehicle
		public static function DrawBasic3dSphericalVehicle( vehicle:IVehicle, BoidMesh:TriangleMesh3D,triArr:Vector.<Triangle3D>,uvArr:Array,color:uint):void
		{			
			var vColor:Vector3 = Colors.toVector(Colors.LightGray);
			
			// "aspect ratio" of body (as seen from above)
			const x:Number = 0.5;
			var y:Number = Number(Math.sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = vehicle.Radius;
			var p:Vector3 = vehicle.Position;

			// body shape parameters
			var f:Vector3 = Vector3.ScalarMultiplication(r,vehicle.Forward);
			var s:Vector3 = Vector3.ScalarMultiplication((r * x), vehicle.Side);
			var u:Vector3 = Vector3.ScalarMultiplication((r * x * 0.5),vehicle.Up);
			var b:Vector3 = Vector3.ScalarMultiplication(r * -y,vehicle.Forward);

			// vertex positions
			var nose:Vertex3D = Vector3.VectorAddition(p , f).ToVertex3D();
			var side1:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , s).ToVertex3D();
			var side2:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , s).ToVertex3D();
			var top:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(p , b) , u).ToVertex3D();
			var bottom:Vertex3D = Vector3.VectorSubtraction(Vector3.VectorAddition(p , b) , u).ToVertex3D();;
			
			/*trace("nose",nose.x, nose.y, nose.z); 
			trace("side1",side1.x, side1.y, side1.z);
			trace("side2",side2.x, side2.y, side2.z);
			trace("top",top.x, top.y, top.z);
			trace("bottom",bottom.x, bottom.y, bottom.z);*/
			
			// colors
			const j:Number = +0.05;
			const k:Number = -0.05;
			
			var color1:uint = 0x00FF00;// Colors.toHex(Vector3.VectorAddition(vColor , new Vector3(j, j, k)));
			var color2:uint = 0xFF0000;// Colors.toHex(Vector3.VectorAddition(vColor , new Vector3(j, k, j)));
			var color3:uint = 0x0000FF;// Colors.toHex(Vector3.VectorAddition(vColor , new Vector3(k, j, j)));
			var color4:uint = 0xF0F000;// Colors.toHex(Vector3.VectorAddition(vColor , new Vector3(k, j, k)));
			var color5:uint = 0xFF00FF;// Colors.toHex(Vector3.VectorAddition(vColor , new Vector3(k, k, j)));
			
			BoidMesh.geometry.vertices.push(nose,top,side1,side2,bottom);
			
			triArr[0].reset(BoidMesh, new Array(nose, side1, top), new ColorMaterial(color1) , uvArr);
			triArr[1].reset(BoidMesh, new Array(nose, top, side2), new ColorMaterial(color2), uvArr);
			triArr[2].reset(BoidMesh, new Array(nose, bottom, side1), new ColorMaterial(color3), uvArr);
			triArr[3].reset(BoidMesh, new Array(nose, side2, bottom), new ColorMaterial(color4), uvArr);
			triArr[4].reset(BoidMesh, new Array(side1, side2, top), new ColorMaterial(color5), uvArr);
			triArr[5].reset(BoidMesh, new Array(side2, side1, bottom), new ColorMaterial(color5), uvArr);
			
			BoidMesh.geometry.faces.push(triArr[0]);
			BoidMesh.geometry.faces.push(triArr[1]);
			BoidMesh.geometry.faces.push(triArr[2]);
			BoidMesh.geometry.faces.push(triArr[3]);
			BoidMesh.geometry.faces.push(triArr[4]);
			BoidMesh.geometry.faces.push(triArr[5]);
			
			/*BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(nose, side1, top), new ColorMaterial(color1), uvArr));
			BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(nose, top, side2), new ColorMaterial(color2), uvArr));
			BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(nose, bottom, side1), new ColorMaterial(color3), uvArr));
			BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(nose, side2, bottom), new ColorMaterial(color4), uvArr));
			BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(side1, side2, top), new ColorMaterial(color5), uvArr));
			BoidMesh.geometry.faces.push(new Triangle3D(BoidMesh, new Array(side2, side1, bottom),new ColorMaterial(color5), uvArr));
			*/
			
			//BoidMesh.mergeVertices();
			//for each(var t:Triangle3D in BoidMesh.geometry.faces) t.renderCommand.create = BoidMesh.createRenderTriangle;
			BoidMesh.geometry.ready = true;
			if (Papervision3D.useRIGHTHANDED) BoidMesh.geometry.flipFaces();
		}

		// General purpose circle/disk drawing routine.  Draws circles or disks (as
		// specified by "filled" argument) and handles both special case 2d circles
		// on the XZ plane or arbitrary circles in 3d space (as specified by "in3d"
		// argument)
		public static function DrawCircleOrDisk(radius:Number, axis:Vector3,  center:Vector3, color:uint, segments:int, filled:Boolean, in3d:Boolean):void
		{
			if (Demo.IsDrawPhase == true)
			{
				var ls:LocalSpace = new LocalSpace();
				if (in3d)
				{
					// define a local space with "axis" as the Y/up direction
					// (XXX should this be a method on  LocalSpace?)
					var unitAxis:Vector3 = axis;
                    unitAxis.fNormalize();
					var unitPerp:Vector3 = Vector3.FindPerpendicularIn3d(axis);
                    unitPerp.fNormalize();
					ls.Up = unitAxis;
					ls.Forward = unitPerp;
					ls.Position = (center);
					ls.SetUnitSideFromForwardAndUp();
				}

				// point to be rotated about the (local) Y axis, angular step size
				var pointOnCircle:Vector3 = new Vector3(radius, 0, 0);
				var step:Number = Number(2 * Math.PI) / Number(segments);

				// rotate p around the circle in "segments" steps
				var sin:Number = 0;
				var cos:Number = 0;
				var vertexCount:int = filled ? segments + 1 : segments;
				for (var i:int = 0; i < vertexCount; i++)
				{
					// rotate point one more step around circle
                    var temp:Array = VHelper.RotateAboutGlobalY(pointOnCircle, step, sin, cos);
					sin = temp[0];
					cos = temp[1];
					pointOnCircle = temp[2];
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(radius, axis, center, color, segments, filled, in3d);
			}
		}

		public static function Draw3dCircleOrDisk(radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int, filled:Boolean):void
		{
			// draw a circle-or-disk in the given local space
			DrawCircleOrDisk(radius, axis, center, color, segments, filled, true);
		}

		public static function Draw3dCircle(radius:Number, center:Vector3, axis:Vector3, color:uint, segments:int):void
		{
			Draw3dCircleOrDisk(radius, center, axis, color, segments, false);
		}

		public static function AllDeferredLines():void
		{
			DeferredLine.DrawAll();
		}

		public static function AllDeferredCirclesOrDisks():void
		{
			DeferredCircle.DrawAll();
		}

		public static function Draw2dTextAt3dLocation(text:String, location:Vector3, color:uint):void
		{
			// XXX NOTE: "it would be nice if" this had a 2d screenspace offset for
			// the origin of the text relative to the screen space projection of
			// the 3d point.

			// set text color and raster position
			demo.getandDrawText(text, location, color);
		}

		public static function Draw2dTextAt2dLocation(text:String, location:Vector3, color:uint):void
		{
			// set text color and raster position
			demo.getandDrawText(text, location, color);
		}

		public static function GetWindowWidth():Number
		{
			return 1024;
		}

		public static function GetWindowHeight():Number
		{
			return 640;
		}
	}
}
