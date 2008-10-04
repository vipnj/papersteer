// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Copyright (c) 2002-2003, Craig Reynolds <craig_reynolds@playstation.sony.com>
// Copyright (C) 2007 Bjoern Graf <bjoern.graf@gmx.net>
// Copyright (C) 2007 Michael Coles <michael@digini.com>
// All rights reserved.
//
// This software is licensed as described in the file license.txt, which
// you should have received as part of this distribution. The terms
// are also available at http://www.codeplex.com/SharpSteer/Project/License.aspx.

/*using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;*/

package tabinda.demo
{
	import flash.text.TextField;
	import org.papervision3d.core.geom.Lines3D;
	import org.papervision3d.core.geom.renderables.Line3D;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.objects.DisplayObject3D;
	public class Drawing extends IDraw
	{
		public static var game:Demo = null;
		//static var cullMode:CullMode;
		static var curColor:Color;
		//static var curMode:PrimitiveType;

		static var vertices:Array = new Array();
		static var localSpace:LocalSpace = new LocalSpace();
		var defaultMaterial : LineMaterial = new LineMaterial(0xFFFFFF, 1);
		var lines:Lines3D = new Lines3D(defaultMaterial, "Lines");
		var cont:DisplayObject3D = new DisplayObject3D();
		var line:Line3D = new Line3D(lines, defaultMaterial, 2);
		lines.addChild(line);
		game.scene.addChild(lines);
		
		var tri:Triangle3D = new Triangle3D(cont,null,defaultMaterial);
		game.scene.addChild(tri);
		
		static function SetColor(color:Color):void
		{
			curColor = color;
		}

        static function drawBegin(mode:PrimitiveType):void
		{
			curMode = mode;
		}

		static function drawEnd():void
		{
			var primitiveCount:int = 0;

			switch (curMode)
			{
			case PrimitiveType.LineList:
	
				primitiveCount = vertices.Count / 2;
				break;
			case PrimitiveType.LineStrip:
				vertices.Add(vertices[0]);
				primitiveCount = vertices.Count - 1;
				break;
                case PrimitiveType.TriangleList:
				primitiveCount = vertices.Count / 3;
				break;
			case PrimitiveType.TriangleFan:
				primitiveCount = vertices.Count - 2;
				break;
			}

            //game.graphics.GraphicsDevice.DrawUserPrimitives(curMode, vertices.ToArray(), 0, primitiveCount);

			//vertices.clear();
			vertices.splice(0);
		}

		static function AddVertex(v:Vector3):void
		{
			vertices.push(new VertexPositionColor(v, curColor));
		}

		static function BeginDoubleSidedDrawing():void
		{
			//scullMode = game.graphics.GraphicsDevice.RenderState.CullMode;
			//game.graphics.GraphicsDevice.RenderState.CullMode = CullMode.None;
		}

		static function EndDoubleSidedDrawing():void
		{
			//game.graphics.GraphicsDevice.RenderState.CullMode = cullMode;
		}

		public static function iDrawLine(startPoint:Vector3, endPoint:Vector3, color:Color ):void
		{
            /*SetColor(color);
			drawBegin(PrimitiveType.LineList);
			AddVertex(startPoint);
			AddVertex(endPoint);
            drawEnd();*/
			
			line.v0 =  startPoint;
			line.v1 = endPoint;
			line.material.fillColor = color;
		}

		static function iDrawTriangle(a:Vector3, b:Vector3, c:Vector3, color:Color):void
		{
            /*SetColor(color);
			drawBegin(PrimitiveType.TriangleList);
			{
				AddVertex(a);
                AddVertex(b);
                AddVertex(c);
			}
			drawEnd();*/
			var temp:Array = new Array(a, b, c);
			tri.vertices = temp;
		}

		// Draw a single OpenGL quadrangle given four Vector3 vertices, and color.
		static function iDrawQuadrangle( a:Vector3,  b:Vector3,  c:Vector3, d:Vector3,  color:Color):void
		{
            /*SetColor(color);
			drawBegin(PrimitiveType.TriangleFan);
			{
                AddVertex(a);
                AddVertex(b);
                AddVertex(c);
                AddVertex(d);
			}
			drawEnd();*/
			var temp:Array = new Array(a, b, c, d);
			tri.vertices = temp;
			//game.scene.addChild(new Triangle3D(cont, temp, defaultMaterial));
		}

		public function Line( startPoint:Vector3,  endPoint:Vector3,  color:Color):void
		{
			DrawLine(startPoint, endPoint, color);
		}

		// draw a line with alpha blending
		public function LineAlpha(startPoint:Vector3,  endPoint:Vector3, color:Color, alpha:Number):void
		{
			DrawLineAlpha(startPoint, endPoint, color, alpha);
		}

		public function  CircleOrDisk( radius:Number, axis:Vector3, center:Vector3, color:Color, segments:int, filled:Boolean, in3d:Boolean):void
		{
			DrawCircleOrDisk(radius, axis, center, color, segments, filled, in3d);
		}

		public static function  DrawLine( startPoint:Vector3,  endPoint:Vector3,  color:Color):void
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
		public static function DrawLineAlpha( startPoint:Vector3, endPoint:Vector3, color:Color, alpha:Number):void
		{
			var c:Color = new Color(color.R, color.G, color.B, int(255.0 * alpha));
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
		public static function  Draw2dLine(startPoint,  endPoint,color:Color):void
		{
			iDrawLine(startPoint, endPoint, color);
		}

		// draws a "wide line segment": a rectangle of the given width and color
		// whose mid-line connects two given endpoints
		public static function DrawXZWideLine( startPoint:Vector3,  endPoint:Vector3, color:Color,width:Number):void
		{
			var offset:Vector3 = endPoint - startPoint;
			offset.Normalize();
            var perp:Vector3 = localSpace.LocalRotateForwardToSide(offset);
			var radius:Vector3 = perp * width / 2;

			var a:Vector3 = startPoint + radius;
			var b:Vector3 = endPoint + radius;
			var c:Vector3 = endPoint - radius;
			var d:Vector3= startPoint - radius;

			iDrawQuadrangle(a, b, c, d, color);
		}

		// draw a (filled-in, polygon-based) square checkerboard grid on the XZ
		// (horizontal) plane.
		//
		// ("size" is the length of a side of the overall grid, "subsquares" is the
		// number of subsquares along each edge (for example a standard checkboard
		// has eight), "center" is the 3d position of the center of the grid,
		// color1 and color2 are used for alternating subsquares.)
		public static function  DrawXZCheckerboardGrid(size:Number, subsquares:int,  center:Vector3, color1:Color,  color2:Color):void
		{
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			BeginDoubleSidedDrawing();
			{
				var flag1:Boolean = false;
				var p:Number = -half;
				var corner:Vector3 = new Vector3();
				for (var i:int = 0; i < subsquares; i++)
				{
					var flag2:Boolean = flag1;
					var q:Number = -half;
					for (var j:int = 0; j < subsquares; j++)
					{
						corner.X = p;
                        corner.Y = 0;
                        corner.Z = q;

						corner += center;
						iDrawQuadrangle(corner,
										 corner + new Vector3(spacing, 0, 0),
										 corner + new Vector3(spacing, 0, spacing),
										 corner + new Vector3(0, 0, spacing),
										 flag2 ? color1 : color2);
						flag2 = !flag2;
						q += spacing;
					}
					flag1 = !flag1;
					p += spacing;
				}
			}
			EndDoubleSidedDrawing();
		}

		// draw a square grid of lines on the XZ (horizontal) plane.
		//
		// ("size" is the length of a side of the overall grid, "subsquares" is the
		// number of subsquares along each edge (for example a standard checkboard
		// has eight), "center" is the 3d position of the center of the grid, lines
		// are drawn in the specified "color".)
		public static function DrawXZLineGrid(size:Number,subsquares:int,center:Vector3, color:Color):void
		{
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			// set grid drawing color
            //SetColor(color);

			// draw a square XZ grid with the given size and line count
			//drawBegin(PrimitiveType.LineList);
			var q:Number = -half;
			for (var i:int = 0; i < (subsquares + 1); i++)
			{
				var x1:Vector3 = new Vector3(q, 0, +half); // along X parallel to Z
				var x2:Vector3 = new Vector3(q, 0, -half);
				var z1:Vector3 = new Vector3(+half, 0, q); // along Z parallel to X
				var z2:Vector3 = new Vector3(-half, 0, q);

                /*AddVertex(x1 + center);
                AddVertex(x2 + center);
                AddVertex(z1 + center);
                AddVertex(z2 + center);*/
				
				lines.addChild(new Line3D(lines, defaultMaterial, 2, x1 + center, x2 + center));
				lines.addChild(new Line3D(lines, defaultMaterial, 2, z1 + center, z2 + center));
								
				q += spacing;
			}
			//drawEnd();
		}

		// draw the three axes of a LocalSpace: three lines parallel to the
		// basis vectors of the space, centered at its origin, of lengths
		// given by the coordinates of "size".
		public static function DrawAxes( ls:ILocalSpace, size:Vector3, color:Color):void
		{
			var x:Vector3 = new Vector3(size.X / 2, 0, 0);
			var y:Vector3 = new Vector3(0, size.Y / 2, 0);
			var z:Vector3 = new Vector3(0, 0, size.Z / 2);

			iDrawLine(ls.GlobalizePosition(x), ls.GlobalizePosition(x * -1), color);
			iDrawLine(ls.GlobalizePosition(y), ls.GlobalizePosition(y * -1), color);
			iDrawLine(ls.GlobalizePosition(z), ls.GlobalizePosition(z * -1), color);
		}

		public static function DrawQuadrangle( a:Vector3,  b:Vector3,  c:Vector3,  d:Vector3,  color:Color):void
		{
			iDrawQuadrangle(a, b, c, d, color);
		}

		// draw the edges of a box with a given position, orientation, size
		// and color.  The box edges are aligned with the axes of the given
		// LocalSpace, and it is centered at the origin of that LocalSpace.
		// "size" is the main diagonal of the box.
		//
		// use gGlobalSpace to draw a box aligned with global space
		public static function  DrawBoxOutline( localSpace:ILocalSpace,  size:Vector3, color:Color):void
		{
			var s:Vector3 = size / 2.0;  // half of main diagonal

			var a:Vector3 = new Vector3(+s.X, +s.Y, +s.Z);
			var b:Vector3 = new Vector3(+s.X, -s.Y, +s.Z);
			var c:Vector3 = new Vector3(-s.X, -s.Y, +s.Z);
			var d:Vector3 = new Vector3(-s.X, +s.Y, +s.Z);

			var e:Vector3 = new Vector3(+s.X, +s.Y, -s.Z);
			var f:Vector3 = new Vector3(+s.X, -s.Y, -s.Z);
			var g:Vector3 = new Vector3(-s.X, -s.Y, -s.Z);
			var h:Vector3 = new Vector3(-s.X, +s.Y, -s.Z);

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

		public static function  DrawXZCircle( radius:Number, center:Vector3, color:Color, segments:int):void
		{
			DrawXZCircleOrDisk(radius, center, color, segments, false);
		}

		public static function DrawXZDisk(radius:Number, center:Vector3, color:Color, segments:int):void
		{
			DrawXZCircleOrDisk(radius, center, color, segments, true);
		}

		// drawing utility used by both drawXZCircle and drawXZDisk
		public static function DrawXZCircleOrDisk(radius:Number, center:Vector3, color:Color, segments:int, filled:Boolean):void
		{
			// draw a circle-or-disk on the XZ plane
			DrawCircleOrDisk(radius, Vector3.Zero, center, color, segments, filled, false);
		}

		// a simple 2d vehicle on the XZ plane
		public static function DrawBasic2dCircularVehicle(vehicle:IVehicle, color:Color):void
		{
			// "aspect ratio" of body (as seen from above)
			var x:Number = 0.5;
			var y:Number = Number(Math.Sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = vehicle.Radius;
			var p:Vector3 = vehicle.Position;

			// shape of triangular body
			var u:Vector3 = new Vector3(0, 1, 0) * r * 0.05; // slightly up
			var f:Vector3 = vehicle.Forward * r;
			var s:Vector3 = vehicle.Side * x * r;
			var b:Vector3 = vehicle.Forward * -y * r;

			// draw double-sided triangle (that is: no (back) face culling)
			BeginDoubleSidedDrawing();
			iDrawTriangle(p + f + u,
						   p + b - s + u,
						   p + b + s + u,
						   color);
			EndDoubleSidedDrawing();

			// draw the circular collision boundary
			DrawXZCircle(r, p + u, Color.White, 20);
		}

		// a simple 3d vehicle
		public static function  DrawBasic3dSphericalVehicle( vehicle:IVehicle, color:Color):void
		{
			var vColor:Vector3 = new Vector3(Number(color.R / 255.0), Number(color.G / 255.0), Number(color.B / 255.0));

			// "aspect ratio" of body (as seen from above)
			const x:Number = 0.5;
			var y:Number = Number(Math.Sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = vehicle.Radius;
			var p:Vector3 = vehicle.Position;

			// body shape parameters
			var f:Vector3 = vehicle.Forward * r;
			var s:Vector3 = vehicle.Side * r * x;
			var u:Vector3 = vehicle.Up * r * x * 0.5;
			var b:Vector3 = vehicle.Forward * r * -y;

			// vertex positions
			var nose:Vector3 = p + f;
			var side1:Vector3 = p + b - s;
			var side2:Vector3 = p + b + s;
			var top:Vector3 = p + b + u;
			var bottom:Vector3 = p + b - u;

			// colors
			const j:Number = +0.05;
			const k:Number = -0.05;
			var color1:Color = new Color(vColor + new Vector3(j, j, k));
			var color2:Color = new Color(vColor + new Vector3(j, k, j));
			var color3:Color = new Color(vColor + new Vector3(k, j, j));
			var color4:Color = new Color(vColor + new Vector3(k, j, k));
			var color5:Color = new Color(vColor + new Vector3(k, k, j));

			// draw body
			iDrawTriangle(nose, side1, top, color1);  // top, side 1
			iDrawTriangle(nose, top, side2, color2);  // top, side 2
			iDrawTriangle(nose, bottom, side1, color3);  // bottom, side 1
			iDrawTriangle(nose, side2, bottom, color4);  // bottom, side 2
			iDrawTriangle(side1, side2, top, color5);  // top back
			iDrawTriangle(side2, side1, bottom, color5);  // bottom back
		}

		// a simple sphere
		public static function DrawBasic3dSphere(position:Vector3, radius:Number, color:Color):void
		{
			var vColor:Vector3 = new Vector3(Number(color.R / 255.0), Number(color.G / 255.0), Number(color.B / 255.0));

			// "aspect ratio" of body (as seen from above)
			const x:Number = 0.5;
			var y:Number = Number(Math.Sqrt(1 - (x * x)));

			// radius and position of vehicle
			var r:Number = radius;
			var p:Vector3 = position;

			// body shape parameters
			var f:Vector3 = Vector3.Forward * r;
			var s:Vector3 = Vector3.Left * r * x;
			var u:Vector3 = Vector3.Up * r * x;
			var b:Vector3 = Vector3.Forward * r * -y;

			// vertex positions
			var nose:Vector3 = p + f;
			var side1:Vector3 = p + b - s;
			var side2:Vector3 = p + b + s;
			var top:Vector3 = p + b + u;
			var bottom:Vector3 = p + b - u;

			// colors
			const  j:Number = +0.05;
			const  k:Number = -0.05;
			var color1:Color = new Color(vColor + new Vector3(j, j, k));
			var color2:Color = new Color(vColor + new Vector3(j, k, j));
			var color3:Color = new Color(vColor + new Vector3(k, j, j));
			var color4:Color = new Color(vColor + new Vector3(k, j, k));
			var color5:Color = new Color(vColor + new Vector3(k, k, j));

			// draw body
			iDrawTriangle(nose, side1, top, color1);  // top, side 1
			iDrawTriangle(nose, top, side2, color2);  // top, side 2
			iDrawTriangle(nose, bottom, side1, color3);  // bottom, side 1
			iDrawTriangle(nose, side2, bottom, color4);  // bottom, side 2
			iDrawTriangle(side1, side2, top, color5);  // top back
			iDrawTriangle(side2, side1, bottom, color5);  // bottom back
		}

		// General purpose circle/disk drawing routine.  Draws circles or disks (as
		// specified by "filled" argument) and handles both special case 2d circles
		// on the XZ plane or arbitrary circles in 3d space (as specified by "in3d"
		// argument)
		public static function DrawCircleOrDisk(radius:Number, axis:Vector3,  center:Vector3, color:Color, segments:int, filled:Boolean, in3d:Boolean):void
		{
			if (Demo.IsDrawPhase == true)
			{
				var ls:LocalSpace = new LocalSpace();
				if (in3d)
				{
					// define a local space with "axis" as the Y/up direction
					// (XXX should this be a method on  LocalSpace?)
					var unitAxis:Vector3 = axis;
                    unitAxis.Normalize();
					var unitPerp:Vector3 = Vector3Helpers.FindPerpendicularIn3d(axis);
                    unitPerp.Normalize();
					ls.Up = unitAxis;
					ls.Forward = unitPerp;
					ls.Position = (center);
					ls.SetUnitSideFromForwardAndUp();
				}

				// make disks visible (not culled) from both sides 
				if (filled) BeginDoubleSidedDrawing();

				// point to be rotated about the (local) Y axis, angular step size
				var pointOnCircle:Vector3 = new Vector3(radius, 0, 0);
				var step:Numbers = Number(2 * Math.PI) / Number(segments);

				// set drawing color
                SetColor(color);

				// begin drawing a triangle fan (for disk) or line loop (for circle)
				drawBegin(filled ? PrimitiveType.TriangleFan : PrimitiveType.LineStrip);

				// for the filled case, first emit the center point
                if (filled) AddVertex(in3d ? ls.Position : center);

				// rotate p around the circle in "segments" steps
				var sin:Number = 0, cos = 0;
				var vertexCount:int = filled ? segments + 1 : segments;
				for (var i:int = 0; i < vertexCount; i++)
				{
					// emit next point on circle, either in 3d (globalized out
					// of the local space), or in 2d (offset from the center)
                    AddVertex(in3d ? ls.GlobalizePosition(pointOnCircle) : pointOnCircle + center);

					// rotate point one more step around circle
                    pointOnCircle = Vector3Helpers.RotateAboutGlobalY(pointOnCircle, step, sin, cos);
				}

				// close drawing operation
				drawEnd();
				if (filled) EndDoubleSidedDrawing();
			}
			else
			{
				DeferredCircle.AddToBuffer(radius, axis, center, color, segments, filled, in3d);
			}
		}

		public static function Draw3dCircleOrDisk(radius:Number, center:Vector3, axis:Vector3, color:Color, segments:int, filled:Boolean):void
		{
			// draw a circle-or-disk in the given local space
			DrawCircleOrDisk(radius, axis, center, color, segments, filled, true);
		}

		public static function Draw3dCircle(radius:Number, center:Vector3, axis:Vector3, color:Color, segments:int):void
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

		public static function Draw2dTextAt3dLocation(text:String, location:Vector3, color:Color):void
		{
			// XXX NOTE: "it would be nice if" this had a 2d screenspace offset for
			// the origin of the text relative to the screen space projection of
			// the 3d point.

			// set text color and raster position
			var p:Vector3 = location;
			var textEntry:TextField = new TextField();
			textEntry.textColor = color;
			textEntry.x = p.x;
			textEntry.y = p.y;
			textEntry.text = text;
			game.addChild(textEntry);
		}

		public static function Draw2dTextAt2dLocation(text:String, location:Vector3, color:Color):void
		{
			// set text color and raster position
			var textEntry:TextField = new TextField();
			textEntry.textColor = color;
			textEntry.x = location.x;
			textEntry.y = location.y;
			textEntry.text = text;
			game.addChild(textEntry);
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
