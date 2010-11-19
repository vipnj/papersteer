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

package tabinda.demo.plugins.LowSpeedTurning
{
	import org.papervision3d.*;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.*;
	import org.papervision3d.materials.special.*;
	import org.papervision3d.objects.*;
	import org.papervision3d.typography.*;
	import org.papervision3d.typography.fonts.HelveticaMedium;
	
	import tabinda.demo.*;
	import tabinda.papersteer.*;
	
	
	public class LowSpeedTurnPlugIn extends PlugIn
	{
		private const lstCount:int=5;
		private const lstLookDownDistance:Number=18;
		private static var lstViewCenter:Vector3=new Vector3(7,0,-2);
		private static var lstPlusZ:Vector3 = new Vector3(0, 0, 1);
		private var all:Vector.<LowSpeedTurn>;// for allVehicles
		
		// Triangle Mesh used to create a Grid - Look in Demo.GridUtility
		public var GridMesh:TriangleMesh3D;
		public var lines:Lines3D;
		public var colMat:ColorMaterial;
		
		private var text3D:Text3D;
		private var textFont:Font3D;
		private var textMat:Letter3DMaterial;
		
		public var pluginReset:Boolean;

		public function LowSpeedTurnPlugIn ()
		{			
			super ();
			all = new Vector.<LowSpeedTurn>();
		}

		public override  function get Name ():String
		{
			return "Low Speed Turn";
		}

		public override  function get SelectionOrderSortKey ():Number
		{
			return 0.05;
		}
		
		public function initPV3D():void
		{
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = false;
			GridMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			
			lines = new Lines3D(new LineMaterial(0x000000, 1));
			
			textMat = new Letter3DMaterial(0xffffff);
			textMat.doubleSided = true;
			textFont = new Font3D();
			text3D = new Text3D("", new HelveticaMedium, textMat);
			text3D.scale = 0.02;
			
			//Demo.contanier.addChild(text3D);
			Demo.container.addChild(GridMesh);
			Demo.container.addChild(lines);
		}

		public override  function Open ():void
		{
			initPV3D();
			
			pluginReset = true;
			
			// create a given number of agents with stepped inital parameters,
			// store pointers to them in an array.
			LowSpeedTurn.ResetStarts ();
			
			for (var i:int=0; i < lstCount; i++)
			{
				var lst:LowSpeedTurn =new LowSpeedTurn();
				all.push (lst);
				Demo.container.addChild(lst.objectMesh);
				Demo.container.addChild(lst.lines);
			}

			// initial selected vehicle
			Demo.SelectedVehicle=all[0];

			// initialize camera
			Demo.camera.Mode=CameraMode.Fixed;
			Demo.camera.FixedUp=lstPlusZ;
			Demo.camera.FixedTarget=lstViewCenter;
			Demo.camera.FixedPosition=lstViewCenter;
			Demo.camera.FixedPosition.y+= lstLookDownDistance;
			Demo.camera.LookDownDistance=lstLookDownDistance;
			Demo.camera.FixedDistanceVerticalOffset=Demo.Camera2dElevation;
			Demo.camera.FixedDistanceDistance = Demo.CameraTargetDistance;
			
			Demo.Draw2dTextAt2dLocation("", new Vector3(20, 50, 0), Colors.Gray);
		}

		public override  function Update (currentTime:Number,elapsedTime:Number):void
		{
			// update, draw and annotate each agent
			for (var i:int=0; i < all.length; i++)
			{
				all[i].Update (currentTime,elapsedTime);
			}
		}

		public override  function Redraw (currentTime:Number,elapsedTime:Number):void
		{
			// selected vehicle (user can mouse click to select another)
			var selected:IVehicle=Demo.SelectedVehicle;

			// vehicle nearest mouse (to be highlighted)
			var nearMouse:IVehicle = Demo.VehicleNearestToMouse();

			// update camera
			Demo.UpdateCamera (currentTime,elapsedTime,selected);

			if(pluginReset)
			{
				GridMesh.geometry.faces = [];
				GridMesh.geometry.vertices = [];
			
				// draw "ground plane"
				//Demo.GridUtility (selected.Position,GridMesh);
				Grid (selected.Position);
				pluginReset = false;
			}
			
			lines.geometry.faces = [];
			lines.geometry.vertices = [];
			lines.removeAllLines();
				
			// update, draw and annotate each agent
			for (var i:int=0; i < all.length; i++)
			{
				// draw this agent
				var agent:LowSpeedTurn=all[i];
				agent.Draw ();

				// display speed near agent's screen position
				var textColor:uint=Colors.RGBToHex(0.8,0.8,1.0);
				var textOffset:Vector3=new Vector3(0,0.25,0);
				var textPosition:Vector3=Vector3.VectorAddition(agent.Position , textOffset);
				var annote:String = String(agent.Speed);
				text3D.text = annote;
				text3D.position = textPosition.ToNumber3D();
				//Drawing.Draw2dTextAt3dLocation (annote,textPosition,textColor);
				//Drawing.Draw2dTextAt3dLocation (annote,textPosition,textColor);
			}

			// highlight vehicle nearest mouse
			//Demo.HighlightVehicleUtility (nearMouse);
			HighlightVehicleUtility (nearMouse);
		}
		
		public function Grid(gridTarget:Vector3):void
		{		
			var center:Vector3 = new Vector3(Number(Math.round(gridTarget.x * 0.5) * 2),
												 Number(Math.round(gridTarget.y * 0.5) * 2) - .05,
												 Number(Math.round(gridTarget.z * 0.5) * 2));

			// colors for checkboard
			var gray1:uint = Colors.LightGray
			var gray2:uint = Colors.DarkGray;
			
			var size:int = 500;
			var subsquares:int = 50;
			
			var half:Number = size / 2;
			var spacing:Number = size / subsquares;

			var flag1:Boolean = false;
			var p:Number = -half;
			var corner:Vector3 = new Vector3();
			
			for (var i:int = 0; i < subsquares; i++)
			{
				var flag2:Boolean = flag1;
				var q:Number = -half;
				for (var j:int = 0; j < subsquares; j++)
				{
					corner.x = p;
					corner.y = -1;
					corner.z = q;

					corner = Vector3.VectorAddition(corner, center);
					
					var vertA:Vertex3D = corner.ToVertex3D();
					var vertB:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, 0)).ToVertex3D();
					var vertC:Vertex3D = Vector3.VectorAddition(corner, new Vector3(spacing, 0, spacing)).ToVertex3D();
					var vertD:Vertex3D = Vector3.VectorAddition(corner, new Vector3(0, 0, spacing)).ToVertex3D();
					
					GridMesh.geometry.vertices.push(vertA, vertB,vertC, vertD);
					
					var color:uint = flag2 ? gray1 : gray2;
					var t1:Triangle3D = new Triangle3D(GridMesh, [vertA,vertB,vertC], new ColorMaterial(color, 1));
					var t2:Triangle3D = new Triangle3D(GridMesh, [vertD,vertA,vertC], new ColorMaterial(color, 1));
					
					GridMesh.geometry.faces.push(t1);
					GridMesh.geometry.faces.push(t2);
					
					flag2 = !flag2;
					q += spacing;
				}
				flag1 = !flag1;
				p += spacing;
			}
			if (Papervision3D.useRIGHTHANDED)
			{
				GridMesh.geometry.flipFaces();
			}
			GridMesh.geometry.ready = true;
		}
		
		/**
		 * Draws a gray disk on the XZ plane under a given vehicle
		 * @param	vehicle
		 */
		public function HighlightVehicleUtility(v:IVehicle):void
		{
			if (v != null)
			{
				var cPosition:Vector3 = Demo.camera.Position;
				var radius:Number = v.Radius;  							 					 // adjusted radius
				var	center:Vector3 = v.Position;                   							 // center
				var axis:Vector3 = 	Vector3.VectorSubtraction(v.Position , cPosition);       // view axis
				var color:uint = 	Colors.LightGray;                        				 // drawing color
				var	segments:int = 20;                          						 	 // circle segments
				var filled:Boolean = true;
				var in3d:Boolean = false;
				
				if (Demo.IsDrawPhase())
				{
					var temp : Number3D = new Number3D(radius,0,0);
					var tempcurve:Number3D = new Number3D(0,0,0);
					var joinends : Boolean;
					var i:int;
					var pointcount : int;

					var angle:Number = (0-360)/segments;
					var curveangle : Number = angle/2;

					tempcurve.x = radius/Math.cos(curveangle * Number3D.toRADIANS);
					tempcurve.rotateY(curveangle+0);

					if(360-0<360)
					{
						joinends = false;
						pointcount = segments+1;
					}
				   else
					{
						joinends = true;
						pointcount = segments;
					}
				   
					temp.rotateY(0);

					var vertices:Array = new Array();
					var curvepoints:Array = new Array();

					for(i = 0; i< pointcount;i++)
					{
						vertices.push(new Vertex3D(center.x+temp.x, center.y+temp.y, center.z+temp.z));
						curvepoints.push(new Vertex3D(center.x+tempcurve.x, center.y+tempcurve.y, center.z+tempcurve.z));
						temp.rotateY(angle);
						tempcurve.rotateY(angle);
					}

					for(i = 0; i < segments ;i++)
					{
						var line:Line3D = new Line3D(lines, new LineMaterial(color), 2, vertices[i], vertices[(i+1)%vertices.length]);	
						line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
						lines.addLine(line);
					}	
				}
				else
				{
					DeferredCircle.AddToBuffer(lines,radius, axis, center, color, segments, filled, in3d);
				}
			}
		}

		public override  function Close ():void
		{
			for (var i:int = 0; i < all.length; i++)
			{
				destoryPV3DObject(all[i].objectMesh);
				destoryPV3DObject(all[i].lines);
			}
			
			destoryPV3DObject(GridMesh);
			destoryPV3DObject(lines);

			all.splice(0,all.length);
		}
		
		private function destoryPV3DObject(object:*):void 
		{
			Demo.container.removeChild(object);
			object.material.destroy();
			object = null;
		}

		public override  function Reset ():void
		{
			// reset each agent
			LowSpeedTurn.ResetStarts ();
			for (var i:int=0; i < all.length; i++)
			{
				all[i].Reset ();
			}
			pluginReset = true;
		}

		public override  function get Vehicles ():Vector.<IVehicle>
		{
			var vehicles:Vector.<IVehicle> = Vector.<IVehicle>(all);
			return vehicles;
		}
	}
}