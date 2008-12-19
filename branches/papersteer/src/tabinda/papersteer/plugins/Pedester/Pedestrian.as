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

package tabinda.papersteer.plugins.Pedester
{
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.materials.ColorMaterial;
	
	import tabinda.papersteer.*;
	import tabinda.demo.*;

	public class Pedestrian extends SimpleVehicle
	{
		public var PedMesh:TriangleMesh3D;
		public var colMat:ColorMaterial;
		public var uvArr:Array;
		
		var trail:Trail;

		// called when steerToFollowPath decides steering is required
		public function AnnotatePathFollowing(future:Vector3, onPath:Vector3, target:Vector3, outside:Number):void
		{
			var yellow:uint = Colors.Yellow;
			var lightOrange:uint = Colors.toHex(int(255.0 * 1.0), int(255.0 * 0.5), 0);
			var darkOrange:uint = Colors.toHex(int(255.0 * 0.6), int(255.0 * 0.3), 0);
			var yellowOrange:uint = Colors.toHex(int(255.0 * 1.0), int(255.0 * 0.75), 0);

			// draw line from our position to our predicted future position
			annotation.Line(Position, future, yellow);

			// draw line from our position to our steering target on the path
			annotation.Line(Position, target, Colors.Orange);

			// draw a two-toned line between the future test point and its
			// projection onto the path, the change from dark to light color
			// indicates the boundary of the tube.
            var boundaryOffset:Vector3 = Vector3.VectorSubtraction(onPath , future);
            boundaryOffset.fNormalize();
            boundaryOffset = Vector3.ScalarMultiplication(outside,boundaryOffset);
			var onPathBoundary:Vector3 = Vector3.VectorAddition(future , boundaryOffset);
			annotation.Line(onPath, onPathBoundary, darkOrange);
			annotation.Line(onPathBoundary, future, lightOrange);
		}

		// called when steerToAvoidCloseNeighbors decides steering is required
		// (parameter names commented out to prevent compiler warning from "-W")
		public function AnnotateAvoidCloseNeighbor(other:IVehicle, additionalDistance:Number):void
		{
			// draw the word "Ouch!" above colliding vehicles
           var headOn:Boolean = Forward.DotProduct(other.Forward) < 0;
			var green:uint = Colors.toHex(int(255.0 * 0.4), int(255.0 * 0.8), int(255.0 * 0.1));
			var red:uint = Colors.toHex((int(255.0 * 1), int(255.0 * 0.1), 0));
			var color:uint = headOn ? red : green;
			var text:String = headOn ? "OUCH!" : "pardon me";
			var location:Vector3 = Vector3.VectorAddition(Position , new Vector3(0, 0.5, 0));
			if (annotation.IsEnabled)
			{
				Drawing.Draw2dTextAt3dLocation(text, location, color);
			}
		}

		// (parameter names commented out to prevent compiler warning from "-W")
		public function AnnotateAvoidNeighbor(threat:IVehicle, steer:Number, ourFuture:Vector3, threatFuture:Vector3):void
		{
			var green:uint = Colors.toHex(int(255.0 * 0.15), int(255.0 * 0.6), 0);

			annotation.Line(Position, ourFuture, green);
			annotation.Line(threat.Position, threatFuture, green);
			annotation.Line(ourFuture, threatFuture, Colors.Red);
			annotation.CircleXZ(Radius, ourFuture, green, 12);
			annotation.CircleXZ(Radius, threatFuture, green, 12);
		}

		// xxx perhaps this should be a call to a general purpose annotation for
		// xxx "local xxx axis aligned box in XZ plane" -- same code in in
		// xxx CaptureTheFlag.cpp
		public function AnnotateAvoidObstacle(minDistanceToCollision:Number):void
		{
			var boxSide:Vector3 = Vector3.ScalarMultiplication(Radius,Side);
			var boxFront:Vector3 = Vector3.ScalarMultiplication(minDistanceToCollision,Forward);
			var FR:Vector3 = Vector3.VectorSubtraction(Vector3.VectorAddition(Position , boxFront) , boxSide);
			var FL:Vector3 = Vector3.VectorAddition(Vector3.VectorAddition(Position , boxFront) , boxSide);
			var BR:Vector3 = Vector3.VectorSubtraction(Position , boxSide);
			var BL:Vector3 = Vector3.VectorAddition(Position , boxSide);
			annotation.Line(FR, FL, Colors.White);
			annotation.Line(FL, BL, Colors.White);
			annotation.Line(BL, BR, Colors.White);
			annotation.Line(BR, FR, Colors.White);
		}

		// constructor
		public function Pedestrian(pd:IProximityDatabase)
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1));
			
			colMat = new ColorMaterial(0x000000, 1);
			colMat.doubleSided = true;
			PedMesh = new TriangleMesh3D(colMat , new Array(), new Array(), null);
			Demo.scene.addChild(PedMesh);
			
			// allocate a token for this boid in the proximity database
			proximityToken = null;
			NewPD(pd);

			// reset Pedestrian state
			Reset();
		}

		// reset all instance state
		public override function Reset():void
		{
			// reset the vehicle 
			super.Reset();

			// max speed and max steering force (maneuverability) 
			MaxSpeed = 2.0;
			MaxForce = 8.0;

			// initially stopped
			Speed = 0.0;

			// size of bounding sphere, for obstacle avoidance, etc.
			Radius = 0.5; // width = 0.7, add 0.3 margin, take half

			// set the path for this Pedestrian to follow
			path = Globals.GetTestPath();

			// set initial position
			// (random point on path + random horizontal offset)
			var d:Number = path.TotalPathLength * Math.random();
			var r:Number = path.radius;
			var randomOffset:Vector3 = Vector3.ScalarMultiplication(r,VHelper.RandomVectorOnUnitRadiusXZDisk());
			Position = Vector3.VectorAddition(path.MapPathDistanceToPoint(d) , randomOffset);

			// randomize 2D heading
			RandomizeHeadingOnXZPlane();

			// pick a random direction for path following (upstream or downstream)
			pathDirection = (Math.random() > 0.5) ? -1 : +1;

			// trail parameters: 3 seconds with 60 points along the trail
			trail = new Trail(3, 60);

			// notify proximity database that our position has changed
			if (proximityToken != null)
			{
				proximityToken.UpdateForNewPosition(Position);
			}
		}

		// per frame simulation update
		public function Update(currentTime:Number, elapsedTime:Number):void
		{
			// apply steering force to our momentum
			ApplySteeringForce(DetermineCombinedSteering(elapsedTime), elapsedTime);

			// reverse direction when we reach an endpoint
			if (Globals.UseDirectedPathFollowing)
			{
				if (Vector3.Distance(Position, Globals.Endpoint0) < path.radius)
				{
					pathDirection = +1;
					annotation.CircleXZ(path.radius, Globals.Endpoint0, Colors.DarkRed, 20);
				}
				if (Vector3.Distance(Position, Globals.Endpoint1) < path.radius)
				{
					pathDirection = -1;
					annotation.CircleXZ(path.radius, Globals.Endpoint1, Colors.DarkRed, 20);
				}
			}

			// annotation
			annotation.VelocityAcceleration3(this, 5, 0);
			trail.Record(currentTime, Position);

			// notify proximity database that our position has changed
			proximityToken.UpdateForNewPosition(Position);
		}

		// compute combined steering force: move forward, avoid obstacles
		// or neighbors if needed, otherwise follow the path and wander
		public function DetermineCombinedSteering(elapsedTime:Number):Vector3
		{
			// move forward
			var steeringForce:Vector3 = Forward;

			// probability that a lower priority behavior will be given a
			// chance to "drive" even if a higher priority behavior might
			// otherwise be triggered.
			const leakThrough:Number = 0.1;

			// determine if obstacle avoidance is required
			var obstacleAvoidance:Vector3 = Vector3.Zero;
			if (leakThrough < Math.random())
			{
				const oTime:Number = 6; // minTimeToCollision = 6 seconds
				obstacleAvoidance = SteerToAvoidObstacles(oTime, Globals.Obstacles);
			}

			// if obstacle avoidance is needed, do it
			if (obstacleAvoidance != Vector3.Zero)
			{
				steeringForce = Vector3.VectorAddition(steeringForce,obstacleAvoidance);
			}
			else
			{
				// otherwise consider avoiding collisions with others
				var collisionAvoidance:Vector3 = Vector3.Zero;
				const caLeadTime:Number = 3;

				// find all neighbors within maxRadius using proximity database
				// (radius is largest distance between vehicles traveling head-on
				// where a collision is possible within caLeadTime seconds.)
				var maxRadius:Number = caLeadTime * MaxSpeed * 2;
				neighbors.splice(0,neighbors.length);
				neighbors = proximityToken.FindNeighbors(Position, maxRadius, neighbors);

				if (neighbors.length > 0 && leakThrough < Math.random())
					collisionAvoidance = Vector3.ScalarMultiplication(10,SteerToAvoidNeighbors(caLeadTime, neighbors));

				// if collision avoidance is needed, do it
				if (collisionAvoidance != Vector3.Zero)
				{
					steeringForce = Vector3.VectorAddition(steeringForce,collisionAvoidance);
				}
				else
				{
					// add in wander component (according to user switch)
					if (Globals.WanderSwitch)
						steeringForce = Vector3.VectorAddition(steeringForce,SteerForWander(elapsedTime));

					// do (interactively) selected type of path following
					const pfLeadTime:Number = 3;
					var pathFollow:Vector3 =
						(Globals.UseDirectedPathFollowing ?
						 SteerToFollowPath(pathDirection, pfLeadTime, path) :
						 SteerToStayOnPath(pfLeadTime, path));

					// add in to steeringForce
					steeringForce = Vector3.ScalarMultiplication(0.5,pathFollow);
				}
			}

			// return steering constrained to global XZ "ground" plane
            steeringForce.y = 0;
			return steeringForce;
		}


		// draw this pedestrian into scene
		public function Draw():void
		{
			PedMesh.geometry.vertices.splice(0);
			PedMesh.geometry.faces.splice(0);
			
			Drawing.DrawBasic2dCircularVehicle(this, PedMesh,uvArr,Colors.Gray);
			trail.Draw(Annotation.drawer);
		}

		// switch to new proximity database -- just for demo purposes
		public function NewPD(pd:IProximityDatabase ):void
		{
			// delete this boid's token in the old proximity database
			if (proximityToken != null)
			{
				proximityToken.Dispose();
				proximityToken = null;
			}

			// allocate a token for this boid in the proximity database
			proximityToken = pd.AllocateToken(this);
		}

		// a pointer to this boid's interface object for the proximity database
		var proximityToken:ITokenForProximityDatabase;

		// allocate one and share amoung instances just to save memory usage
		// (change to per-instance allocation to be more MP-safe)
		static var neighbors:Vector.<IVehicle> = new Vector.<IVehicle>();

		// path to be followed by this pedestrian
		// XXX Ideally this should be a generic Pathway, but we use the
		// XXX getTotalPathLength and radius methods (currently defined only
		// XXX on PolylinePathway) to set random initial positions.  Could
		// XXX there be a "random position inside path" method on Pathway?
		var path:PolylinePathway;

		// direction for path following (upstream or downstream)
		var  pathDirection:int;
	}
}
