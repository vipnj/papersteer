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
	import flash.display.DisplayObject;
	import flash.filters.ColorMatrixFilter;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.core.math.*;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.special.LineMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.Papervision3D;

	import tabinda.papersteer.*;
	import tabinda.demo.*;
	
	public class MapDriver extends SimpleVehicle
	{
		public var MapMesh:TriangleMesh3D;
		public var PathMesh:TriangleMesh3D;
		public var colMat1:ColorMaterial;
		public var colMat2:ColorMaterial;
		public var colMat3:ColorMaterial;
		public var uvArr:Array;
		public var lines:Lines3D;
		
		public var trail:Trail;
		
		// map of obstacles
		public var map:TerrainMap;

		// route for path following (waypoints and legs)
		public var path:GCRoute;

		// follow the path "upstream or downstream" (+1/-1)
		public var pathFollowDirection:int;

		// master look ahead (prediction) time
		public var baseLookAheadTime:Number;

		// vehicle dimentions in meters
		public var halfWidth:Number;
		public var halfLength:Number;

		// keep track of failure rate (when vehicle is on top of obstacle)
		public var collisionDetected:Boolean;
		public var collisionLastTime:Boolean;
		public var timeOfLastCollision:Number;
		public var sumOfCollisionFreeTimes:Number;
		public var countOfCollisionFreeTimes:int;

		// keep track of average speed
		public var totalDistance:Number;
		public var totalTime:Number;

		// keep track of path following failure rate
		// (these are probably obsolete now, replaced by stuckOffPathCount)
		public var pathFollowTime:Number;
		public var pathFollowOffTime:Number;

		// take note when current dt is zero (as in paused) for stat counters
		public var dtZero:Boolean;

		// state saved for annotation
		public var annotateAvoid:Vector3;
		public var wingDrawFlagL:Boolean, wingDrawFlagR:Boolean;

		// QQQ first pass at detecting "stuck" state
		public var stuck:Boolean;
		public var stuckCount:int;
		public var stuckCycleCount:int;
		public var stuckOffPathCount:int;

		public var qqqLastNearestObstacle:Vector3;

		public var lapsStarted:int;
		public var lapsFinished:int;

		// QQQ temporary global QQQoaJustScraping
		// QQQ replace this global flag with a cleaner mechanism
		public var QQQoaJustScraping:Boolean;

		public var hintGivenCount:int;
		public var hintTakenCount:int;

		// for "curvature-based incremental steering" -- contains the current
		// steering into which new incremental steering is blended
		public var currentSteering:Vector3;

		// use curved prediction and incremental steering:
		public var curvedSteering:Boolean;
		public var incrementalSteering:Boolean;

		// save obstacle avoidance stats for annotation
		// (nearest obstacle in each of the four zones)
		public static var savedNearestWR:Number = 0.0;
		public static var savedNearestR:Number = 0.0;
		public static var savedNearestL:Number = 0.0;
		public static var savedNearestWL:Number = 0.0;

		public var annoteMaxRelSpeed:Number;
		public var annoteMaxRelSpeedCurve:Number;
		public var annoteMaxRelSpeedPath:Number;

		// which of the three demo modes is selected
		public static var demoSelect:int = 2;

		// size of the world (the map actually)
		public static var worldSize:Number = 200.0;
		public static var worldDiag:Number = Number(Math.sqrt(worldSize * worldSize) / 2);

		// constructor
		public function MapDriver()
		{
			uvArr = new Array(new NumberUV(0, 0), new NumberUV(1, 0), new NumberUV(0, 1),new NumberUV(1,1));
			
			colMat1 = colMat2 = colMat3 = new ColorMaterial(0x000000, 1);
			colMat1.doubleSided = colMat2.doubleSided = colMat3.doubleSided = false;
			
			MapMesh = new TriangleMesh3D(colMat1 , new Array(), new Array());
			VehicleMesh = new TriangleMesh3D(colMat2 , new Array(), new Array());
			PathMesh = new TriangleMesh3D(colMat3 , new Array(), new Array());
			
			lines = new Lines3D(new LineMaterial(0x000000,1));
			
			map = MakeMap();
			path = MakePath();

			Reset();

			// to compute mean time between collisions
			sumOfCollisionFreeTimes = 0.0;
			countOfCollisionFreeTimes = 0.0;

			// keep track for reliability statistics
			collisionLastTime = false;
			timeOfLastCollision = Demo.clock.TotalSimulationTime;

			// keep track of average speed
			totalDistance = 0.0;
			totalTime = 0.0;

			// keep track of path following failure rate
			pathFollowTime = 0.0;
			pathFollowOffTime = 0.0;

			// innitialize counters for various performance data
			stuckCount = 0.0;
			stuckCycleCount = 0.0;
			stuckOffPathCount = 0.0;
			lapsStarted = 0.0;
			lapsFinished = 0.0;
			hintGivenCount = 0.0;
			hintTakenCount = 0.0;

			// follow the path "upstream or downstream" (+1/-1)
			pathFollowDirection = 1;

			// use curved prediction and incremental steering:
			curvedSteering = true;
			incrementalSteering = true;
		}

		// reset state
		public override function Reset():void
		{
			// reset the underlying vehicle class
			super.Reset();

			// initially stopped
			Speed = 0.0;

			// Assume top speed is 20 meters per second (44.7 miles per hour).
			// This value will eventually be supplied by a higher level module.
			MaxSpeed = 20.0;

			// steering force is clipped to this magnitude
			MaxForce = MaxSpeed * 0.4;

			// vehicle is 2 meters wide and 3 meters long
			halfWidth = 1.0;
			halfLength = 1.5;

			// init dynamically controlled radius
			AdjustVehicleRadiusForSpeed();

			// not previously avoiding
			annotateAvoid = Vector3.Zero;

			// 10 seconds with 200 points along the trail
			if (trail == null) 
			{
				trail = new Trail(10, 200);
				annotation.AddTrail(trail);
			}

			// prevent long streaks due to teleportation 
			annotation.ClearTrail(trail);

			// first pass at detecting "stuck" state
			stuck = false;

			// QQQ need to clean up this hack
			qqqLastNearestObstacle = Vector3.Zero;

			// master look ahead (prediction) time
			baseLookAheadTime = 3.0;

			if (demoSelect == 2)
			{
				lapsStarted++;
				var s:Number = worldSize;
				var d:Number = Number(pathFollowDirection);
				Position = (new Vector3(s * d * 0.6, 0, s * -0.4));
				RegenerateOrthonormalBasisUF(Vector3.ScalarMultiplication(d,Vector3.Right));
			}

			// reset bookeeping to detect stuck cycles
			ResetStuckCycleDetection();

			// assume no previous steering
			currentSteering = Vector3.Zero;

			// assume normal running state
			dtZero = false;

			// QQQ temporary global QQQoaJustScraping
			QQQoaJustScraping = false;

			// state saved for speedometer
			annoteMaxRelSpeed = annoteMaxRelSpeedCurve = annoteMaxRelSpeedPath = 0;
			annoteMaxRelSpeed = annoteMaxRelSpeedCurve = annoteMaxRelSpeedPath = 1;
		}
		
		public function removeTrail():void
		{
			annotation.RemoveTrail(trail);
		}


		// per frame simulation update
		public function Update(currentTime:Number, elapsedTime:Number):void
		{
			// take note when current dt is zero (as in paused) for stat counters
			dtZero = (elapsedTime == 0);

			// pretend we are bigger when going fast
			AdjustVehicleRadiusForSpeed();

			// state saved for speedometer
			//      annoteMaxRelSpeed = annoteMaxRelSpeedCurve = annoteMaxRelSpeedPath = 0;
			annoteMaxRelSpeed = annoteMaxRelSpeedCurve = annoteMaxRelSpeedPath = 1;

			// determine combined steering
			var steering:Vector3 = Vector3.Zero;
			var offPath:Boolean = !IsBodyInsidePath();
			if (stuck || offPath || DetectImminentCollision())
			{
				// bring vehicle to a stop if we are stuck (newly or previously
				// stuck, because off path or collision seemed imminent)
				// (QQQ combine with stuckCycleCount code at end of this function?)
				//ApplyBrakingForce (curvedSteering ? 3 : 2, elapsedTime); // QQQ
				ApplyBrakingForce((curvedSteering ? 3.0 : 2.0), elapsedTime); // QQQ
				// count "off path" events
				if (offPath && !stuck && (demoSelect == 2)) stuckOffPathCount++;
				stuck = true;

				// QQQ trying to prevent "creep" during emergency stops
				ResetAcceleration();
				currentSteering = Vector3.Zero;
			}
			else
			{
				// determine steering for obstacle avoidance (save for annotation)
				var avoid:Vector3 = annotateAvoid = SteerToAvoidObstaclesOnMap(LookAheadTimeOA(), map, HintForObstacleAvoidance());
				var needToAvoid:Boolean = Vector3.isNotEqual(avoid,Vector3.Zero);

				// any obstacles to avoid?
				if (needToAvoid)
				{
					// slow down and turn to avoid the obstacles
					var targetSpeed:Number = ((curvedSteering && QQQoaJustScraping) ? MaxSpeedForCurvature() : 0);
					annoteMaxRelSpeed = targetSpeed / MaxSpeed;
					var avoidWeight:Number = 3 + (3 * RelativeSpeed()); // ad hoc
					steering = Vector3.ScalarMultiplication(avoidWeight,avoid);
					steering = Vector3.VectorAddition(steering, SteerForTargetSpeed(targetSpeed));
				}
				else
				{
					// otherwise speed up and...
					steering = SteerForTargetSpeed(MaxSpeedForCurvature());

					// wander for demo 1
					if (demoSelect == 1)
					{
						var wander:Vector3 = SteerForWander(elapsedTime);
						wander.y = 0;
						var flat:Vector3 = wander;
						//check this
						var weighted:Vector3 = Vector3.ScalarMultiplication(6,VHelper.TruncateLength(flat, MaxForce));
						var a:Vector3 = Vector3.VectorAddition(Position , new Vector3(0, 0.2, 0));
						annotation.Line(a, Vector3.VectorAddition(a , Vector3.ScalarMultiplication(0.3,weighted)), Colors.White);
						steering = Vector3.VectorAddition(steering, weighted);
					}

					// follow the path in demo 2
					if (demoSelect == 2)
					{
						var pf:Vector3 = SteerToFollowPath(pathFollowDirection, LookAheadTimePF(), path);
						if (Vector3.isNotEqual(pf, Vector3.Zero))
						{
							// steer to remain on path
							if (pf.DotProduct(Forward) < 0)
							{
								steering = pf;
							}
							else
							{
								steering = Vector3.VectorAddition(pf , steering);
							}
						}
						else
						{
							// path aligment: when neither obstacle avoidance nor
							// path following is required, align with path segment
							var pathHeading:Vector3 = path.TangentAt(Position, pathFollowDirection);
							{
								var b:Vector3 = (Vector3.VectorAddition(Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(0.2, Up)) ,
										(Vector3.ScalarMultiplication(halfLength * 1.4,Forward))));
								var l:Number = 2;
								annotation.Line(b, Vector3.VectorAddition(b , Vector3.ScalarMultiplication(1,Forward)), Colors.Cyan);
								annotation.Line(b, Vector3.VectorAddition(b , Vector3.ScalarMultiplication(1,pathHeading)), Colors.Cyan);
							}
							steering = Vector3.VectorAddition(steering,(Vector3.ScalarMultiplication((path.NearWaypoint(Position) ?
										  0.5 : 0.1),SteerTowardHeading(pathHeading)
										 )));
						}
					}
				}
			}

			if (!stuck)
			{
				// convert from absolute to incremental steering signal
				if (incrementalSteering)
					steering = ConvertAbsoluteToIncrementalSteering(steering, elapsedTime);
				// enforce minimum turning radius
				steering = AdjustSteeringForMinimumTurningRadius(steering);
			}

			// apply selected steering force to vehicle, record data
			ApplySteeringForce(steering, elapsedTime);
			CollectReliabilityStatistics(currentTime, elapsedTime);

			// detect getting stuck in cycles -- we are moving but not
			// making progress down the route (annotate smoothedPosition)
			if (demoSelect == 2)
			{
				var circles:Boolean = WeAreGoingInCircles();
				if (circles && !stuck)
				{
					stuckCycleCount++;
				}
				if (circles)
				{
					stuck = true;
				}
				annotation.CircleOrDisk(0.5, Up, SmoothedPosition(), Colors.White, 7, circles, false);
			}

			// annotation
			PerFrameAnnotation();
			trail.Record(currentTime, Position);
		}

		public function AdjustVehicleRadiusForSpeed():void
		{
			var minRadius:Number = Number(Math.sqrt((halfWidth * halfWidth) + (halfLength * halfLength)));
			var safetyMargin:Number = (curvedSteering ? Utilities.Interpolate(RelativeSpeed(), 0.0, 1.5) : 0.0);
			Radius = (minRadius + safetyMargin);
		}

		public function CollectReliabilityStatistics(currentTime:Number, elapsedTime:Number):void
		{
			// detect obstacle avoidance failure and keep statistics
			collisionDetected = map.ScanLocalXZRectangle(this,
														   -halfWidth, halfWidth,
														   -halfLength, halfLength);

			// record stats to compute mean time between collisions
			var timeSinceLastCollision:Number = currentTime - timeOfLastCollision;
			if (collisionDetected && !collisionLastTime && timeSinceLastCollision > 1)
			{
				sumOfCollisionFreeTimes += timeSinceLastCollision;
				countOfCollisionFreeTimes++;
				timeOfLastCollision = currentTime;
			}
			collisionLastTime = collisionDetected;

			// keep track of average speed
			totalDistance += Speed * elapsedTime;
			totalTime += elapsedTime;

			// keep track of path following failure rate
			// QQQ for now, duplicating this code from the draw method:
			// if we are following a path but are off the path,
			// draw a red line to where we should be
			if (demoSelect == 2)
			{
				pathFollowTime += elapsedTime;
				if (!IsBodyInsidePath())
				{
					pathFollowOffTime += elapsedTime;
				}
			}
		}

		public function HintForObstacleAvoidance():Vector3
		{
			// used only when path following, return zero ("no hint") otherwise
			if (demoSelect != 2)
			{
				return Vector3.Zero;
			}

			// are we heading roughly parallel to the current path segment?
			var p:Vector3 = Position;
			var pathHeading:Vector3 = path.TangentAt(p, pathFollowDirection);
			
			if (pathHeading.DotProduct(Forward) < 0.8)
			{
				// if not, the "hint" is to turn to align with path heading
				var s:Vector3 = Vector3.ScalarMultiplication(halfWidth,Side);
				var f:Number = halfLength * 2;
				annotation.Line(Vector3.VectorAddition(p , s), Vector3.VectorAddition(Vector3.VectorAddition(p , s) , Vector3.ScalarMultiplication(f,Forward)), Colors.Black);
				annotation.Line(Vector3.VectorSubtraction(p , s), Vector3.VectorAddition(Vector3.VectorSubtraction(p , s) , Vector3.ScalarMultiplication(f,Forward)), Colors.Black);
				annotation.Line(p, Vector3.VectorAddition(p , Vector3.ScalarMultiplication(5,pathHeading)), Colors.Magenta);
				return pathHeading;
			}
			else
			{
				// when there is a valid nearest obstacle position
				var obstacle:Vector3 = qqqLastNearestObstacle;
				var o:Vector3 = Vector3.VectorAddition(obstacle , Vector3.ScalarMultiplication(0.1,Up));
				if (Vector3.isNotEqual(obstacle, Vector3.Zero))
				{
					// get offset, distance from obstacle to its image on path
					var outside:Number;
					var onPath:Vector3;
					var temp:Array = path.callMapPointToPath(obstacle, outside);
					onPath = temp[0];
					outside = temp[2];
					var offset:Vector3 = Vector3.VectorSubtraction(onPath , obstacle);
					var offsetDistance:Number = offset.Magnitude();

					// when the obstacle is inside the path tube
					if (outside < 0)
					{
						// when near the outer edge of a sufficiently wide tube
						var segmentIndex:int = path.IndexOfNearestSegment(onPath);
						var segmentRadius:Number = path.radii[segmentIndex];
						var w:Number = halfWidth * 6;
						var nearEdge:Boolean = offsetDistance > w;
						var wideEnough:Boolean = segmentRadius > (w * 2);
						if (nearEdge && wideEnough)
						{
							var obstacleDistance:Number = Vector3.VectorSubtraction(obstacle , p).Magnitude();
							var range:Number = Speed * LookAheadTimeOA();
							var farThreshold:Number = range * 0.8;
							var usableHint:Boolean = obstacleDistance > farThreshold;
							if (usableHint)
							{
								var tmp:Vector3 = offset;
								tmp.Normalize();
								var q:Vector3= Vector3.VectorAddition(p , Vector3.ScalarMultiplication(5,tmp));
								annotation.Line(p, q, Colors.Magenta);
								annotation.CircleOrDisk(0.4, Up, o, Colors.White, 7, false, false);
								return offset;
							}
						}
					}
					annotation.CircleOrDisk(0.4, Up, o, Colors.Black,7, false, false);
				}
			}
			// otherwise, no hint
			return Vector3.Zero;
		}

		// like steerToAvoidObstacles, but based on a BinaryTerrainMap indicating
		// the possitions of impassible regions
		//
		public function callSteerToAvoidObstaclesOnMap(minTimeToCollision:Number, map:TerrainMap):Vector3
		{
			return SteerToAvoidObstaclesOnMap(minTimeToCollision, map, Vector3.Zero); // no steer hint
		}

		// given a map of obstacles (currently a global, binary map) steer so as
		// to avoid collisions within the next minTimeToCollision seconds.
		//
		public function SteerToAvoidObstaclesOnMap(minTimeToCollision:Number, map:TerrainMap, steerHint:Vector3):Vector3
		{
			var spacing:Number = map.MinSpacing() / 2;
			var maxSide:Number = Radius;
			var maxForward:Number = minTimeToCollision * Speed;
			var maxSamples:int = int(maxForward / spacing);
			var step:Vector3 = Vector3.ScalarMultiplication(spacing,Forward);
			var fOffset:Vector3 = Position;
			var sOffset:Vector3 = Vector3.Zero;
			var s:Number = spacing / 2;

			var infinity:int = 9999; // qqq
			var nearestL:int = infinity;
			var nearestR:int = infinity;
			var nearestWL:int = infinity;
			var nearestWR:int = infinity;
			var nearestO:Vector3 = Vector3.Zero;
			wingDrawFlagL = false;
			wingDrawFlagR = false;

			var hintGiven:Boolean = Vector3.isNotEqual(steerHint, Vector3.Zero);
			if (hintGiven && !dtZero)
				hintGivenCount++;
			if (hintGiven)
				annotation.CircleOrDisk(halfWidth * 0.9, Up, Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(0.2,Up)), Colors.White, 7, false, false);

			// QQQ temporary global QQQoaJustScraping
			QQQoaJustScraping = true;

			var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
			var localCenterOfCurvature:Vector3 = Vector3.ScalarMultiplication(signedRadius,Side);
			var center:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
			var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
			var arcRadius:Number = signedRadius * -sign;
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * arcRadius;
			var rawLength:Number = Speed * minTimeToCollision * sign;
			var fracLimit:Number = 1.0 / 6.0;
			var distLimit:Number = circumference * fracLimit;
			var arcLength:Number = ArcLengthLimit(rawLength, distLimit);
			var arcAngle:Number = twoPi * arcLength / circumference;

			// XXX temp annotation to show limit on arc angle
			if (curvedSteering)
			{
				if ((Speed * minTimeToCollision) > (circumference * fracLimit))
				{
					var q:Number = twoPi * fracLimit;
					var fooz:Vector3 = Vector3.VectorSubtraction(Position , center);
					var temp:Array = VHelper.RotateAboutGlobalY(fooz, sign * q);
					var booz:Vector3 = temp[2];
					annotation.Line(center, Vector3.VectorAddition(center , fooz), Colors.Red);
					annotation.Line(center, Vector3.VectorAddition(center , booz), Colors.Red);
				}
			}

			// scan corridor straight ahead of vehicle,
			// keep track of nearest obstacle on left and right sides
			while (s < maxSide)
			{
				sOffset = Vector3.ScalarMultiplication(s,Side);
				s += spacing;
				var lOffset:Vector3 = Vector3.VectorAddition(fOffset , sOffset);
				var rOffset:Vector3 = Vector3.VectorSubtraction(fOffset , sOffset);

				var lObsPos:Vector3 = Vector3.Zero;
				var rObsPos:Vector3 = Vector3.Zero;

				var tmpArr1:Array = ScanObstacleMap(lOffset,
													   center,
													   arcAngle,
													   maxSamples,
													   0,
													   Colors.Yellow,
													   Colors.Red,
													  lObsPos);
				var tmpInt:int = tmpArr1[0];
				lObsPos = tmpArr1[1];
				
				var L:int = (curvedSteering ?  (tmpInt  / spacing) :  map.ScanXZray(lOffset, step, maxSamples));
				
				var tmpArr2:Array = ScanObstacleMap(rOffset,
													   center,
													   arcAngle,
													   maxSamples,
													   0,
													   Colors.Yellow,
													   Colors.Red,
													  rObsPos);
				var tmpInt2:int = tmpArr2[0];
				rObsPos = tmpArr2[1];
				
				var R:int = (curvedSteering ? (tmpInt2 / spacing):  map.ScanXZray(rOffset, step, maxSamples));

				if ((L > 0) && (L < nearestL))
				{
					nearestL = L;
					if (L < nearestR) nearestO = ((curvedSteering) ?
												  lObsPos :
												  Vector3.VectorAddition(lOffset , Vector3.ScalarMultiplication(Number(L),step)));
				}
				if ((R > 0) && (R < nearestR))
				{
					nearestR = R;
					if (R < nearestL) nearestO = ((curvedSteering) ?
												  rObsPos :
												  Vector3.VectorAddition(rOffset , Vector3.ScalarMultiplication(Number(R),step)));
				}

				if (!curvedSteering)
				{
					AnnotateAvoidObstaclesOnMap(lOffset, L, step);
					AnnotateAvoidObstaclesOnMap(rOffset, R, step);
				}

				if (curvedSteering)
				{
					// QQQ temporary global QQQoaJustScraping
					var outermost:Boolean = s >= maxSide;
					var eitherSide:Boolean = (L > 0) || (R > 0);
					if (!outermost && eitherSide)
					{
						QQQoaJustScraping = false;
					}
				}
			}
			qqqLastNearestObstacle = nearestO;

			// scan "wings"
			{
				var wingScans:int = 4;
				// see duplicated code at: QQQ draw sensing "wings"
				// QQQ should be a parameter of this method
				var wingWidth:Vector3 = Vector3.ScalarMultiplication(WingSlope() * maxForward,Side);

				var beforeColor:uint = Colors.RGBToHex(int(255.0 * 0.75), int(255.0 * 0.9), int(255.0 * 0.0));  // for annotation
				var afterColor:uint = Colors.RGBToHex(int(255.0 * 0.9), int(255.0 * 0.5), int(255.0 * 0.0));  // for annotation

				for (var i:int = 1; i <= wingScans; i++)
				{
					var fraction:Number = Number(i) / Number(wingScans);
					var endside:Vector3 = Vector3.VectorAddition(sOffset , Vector3.ScalarMultiplication(fraction,wingWidth));
					var corridorFront:Vector3 = Vector3.ScalarMultiplication(maxForward,Forward);

					// "loop" from -1 to 1
					for (var j:int = -1; j < 2; j += 2)
					{
						var k:Number = Number(j); // prevent VC7.1 warning
						var start:Vector3 = Vector3.VectorAddition(fOffset , Vector3.ScalarMultiplication(k,sOffset));
						var end:Vector3 = Vector3.VectorAddition(fOffset , Vector3.VectorAddition(corridorFront , Vector3.ScalarMultiplication(k,endside)));
						var ray:Vector3 = Vector3.VectorSubtraction(end , start);
						var rayLength:Number = ray.Magnitude();
						var step2:Vector3 = Vector3.ScalarMultiplication(1/rayLength,Vector3.ScalarMultiplication(spacing,ray));
						var raySamples:int = int(rayLength / spacing);
						var endRadius:Number =
							WingSlope() * maxForward * fraction *
							(signedRadius < 0 ? 1 : -1) * (j == 1 ? 1 : -1);
						var ignore:Vector3;
						
						var tmpArr3:Array = ScanObstacleMap(start,
																  center,
																  arcAngle,
																  raySamples,
																  endRadius,
																  beforeColor,
																  afterColor,
																 ignore);
						var tmpInt3:int = tmpArr3[0];
						ignore = tmpArr3[1];
						var scan:int = (curvedSteering ? (tmpInt3 / spacing) :  map.ScanXZray(start, step2, raySamples));

						if (!curvedSteering)
							AnnotateAvoidObstaclesOnMap(start, scan, step2);

						if (j == 1)
						{
							if ((scan > 0) && (scan < nearestWL)) nearestWL = scan;
						}
						else
						{
							if ((scan > 0) && (scan < nearestWR)) nearestWR = scan;
						}
					}
				}
				wingDrawFlagL = nearestWL != infinity;
				wingDrawFlagR = nearestWR != infinity;
			}

			// for annotation
			savedNearestWR = Number(nearestWR);
			savedNearestR = Number(nearestR);
			savedNearestL = Number(nearestL);
			savedNearestWL = Number(nearestWL);

			// flags for compound conditions, used below
			var obstacleFreeC:Boolean = nearestL == infinity && nearestR == infinity;
			var obstacleFreeL:Boolean = nearestL == infinity && nearestWL == infinity;
			var obstacleFreeR:Boolean = nearestR == infinity && nearestWR == infinity;
			var obstacleFreeWL:Boolean = nearestWL == infinity;
			var obstacleFreeWR:Boolean = nearestWR == infinity;
			var obstacleFreeW:Boolean = obstacleFreeWL && obstacleFreeWR;

			// when doing curved steering and we have already detected "just
			// scarping" but neither wing is free, recind the "just scarping"
			// QQQ temporary global QQQoaJustScraping
			var JS:Boolean = curvedSteering && QQQoaJustScraping;
			var cancelJS:Boolean = !obstacleFreeWL && !obstacleFreeWR;
			if (JS && cancelJS) QQQoaJustScraping = false;


			// ----------------------------------------------------------
			// now we have measured everything, decide which way to steer
			// ----------------------------------------------------------


			// no obstacles found on path, return zero steering
			if (obstacleFreeC)
			{
				qqqLastNearestObstacle = Vector3.Zero;
				AnnotationNoteOAClauseName("obstacleFreeC");

				// qqq  this may be in the wrong place (what would be the right
				// qqq  place?!) but I'm trying to say "even if the path is
				// qqq  clear, don't go too fast when driving between obstacles
				if (obstacleFreeWL || obstacleFreeWR || RelativeSpeed() < 0.7)
					return Vector3.Zero;
				else
					return Vector3.Negate(Forward);
			}

			// if the nearest obstacle is way out there, take hint if any
			//      if (hintGiven && (Math.Min (nearestL, nearestR) > (maxSamples * 0.8f)))
			if (hintGiven && (Math.min(Number(nearestL), Number(nearestR)) > (maxSamples * 0.8)))
			{
				AnnotationNoteOAClauseName("nearest obstacle is way out there");
				AnnotationHintWasTaken();
				if (steerHint.DotProduct(Side) > 0)
					return Side;
				else
					return Vector3.Negate(Side);
			}

			// QQQ experiment 3-9-04
			//
			// since there are obstacles ahead, if we are already near
			// maximum curvature, we MUST turn in opposite direction
			//
			// are we turning more sharply than the minimum turning radius?
			// (code from adjustSteeringForMinimumTurningRadius)
			var maxCurvature:Number = 1 / (MinimumTurningRadius() * 1.2);
			if (Math.abs(Curvature) > maxCurvature)
			{
				var blue:uint = Colors.RGBToHex(0, 0, int(255.0 * 0.8));
				AnnotationNoteOAClauseName("min turn radius");
				annotation.CircleOrDisk(MinimumTurningRadius() * 1.2, Up,
										center, blue, 7, false, false);
				return Vector3.ScalarMultiplication(sign,Side);
			}

			// if either side is obstacle-free, turn in that direction
			if (obstacleFreeL || obstacleFreeR)
			{
				AnnotationNoteOAClauseName("obstacle-free side");
			}

			if (obstacleFreeL)
			{
				return Side;
			}
			if (obstacleFreeR)
			{
				return Vector3.Negate(Side);
			}

			// if wings are clear, turn away from nearest obstacle straight ahead
			if (obstacleFreeW)
			{
				AnnotationNoteOAClauseName("obstacleFreeW");
				// distance to obs on L and R side of corridor roughtly the same
				var same:Boolean = Math.abs(nearestL - nearestR) < 5; // within 5
				// if they are about the same and a hint is given, use hint
				if (same && hintGiven)
				{
					AnnotationHintWasTaken();
					if (steerHint.DotProduct(Side) > 0)
						return Side;
					else
						return Vector3.Negate(Side);
				}
				else
				{
					// otherwise steer toward the less cluttered side
					if (nearestL > nearestR)
						return Side;
					else
						return Vector3.Negate(Side);
				}
			}

			// if the two wings are about equally clear and a steering hint is
			// provided, use it
			var equallyClear:Boolean = Math.abs(nearestWL - nearestWR) < 2; // within 2
			if (equallyClear && hintGiven)
			{
				AnnotationNoteOAClauseName("equallyClear");
				AnnotationHintWasTaken();
				if (steerHint.DotProduct(Side) > 0)
				{
					return Side;
				}
				else
				{
					return Vector3.Negate(Side);
				}
				
			}

			// turn towards the side whose "wing" region is less cluttered
			// (the wing whose nearest obstacle is furthest away)
			AnnotationNoteOAClauseName("wing less cluttered");
			if (nearestWL > nearestWR)
			{
				return Side;
			}
			else
			{
				return Vector3.Negate(Side);
			}
		}

		// QQQ reconsider calling sequence
		// called when steerToAvoidObstaclesOnMap decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function AnnotateAvoidObstaclesOnMap(scanOrigin:Vector3, scanIndex:int, scanStep:Vector3):void
		{
			if (scanIndex > 0)
			{
				var hit:Vector3 = Vector3.VectorAddition(scanOrigin , Vector3.ScalarMultiplication(Number(scanIndex),scanStep));
				annotation.Line(scanOrigin, hit, Colors.RGBToHex(int(255.0 * 0.7), int(255.0 * 0.3 ), int(255.0 * 0.3)));
			}
		}

		public function AnnotationNoteOAClauseName(clauseName:String):void
		{
			// does noting now, idea was that it might draw 2d text near vehicle
			// with this state information
			//

			// print version:
			//
			// if (!dtZero) std.cout << clauseName << std.endl;

			// was had been in caller:
			//
			//if (!dtZero)
			//{
			//    int WR = nearestWR; debugPrint (WR);
			//    int R  = nearestR;  debugPrint (R);
			//    int L  = nearestL;  debugPrint (L);
			//    int WL = nearestWL; debugPrint (WL);
			//} 
		}

		public function  AnnotationHintWasTaken():void
		{
			if (!dtZero)
			{
				hintTakenCount++;
			}

			var r:Number = halfWidth * 0.9;
			var ff :Vector3 = Vector3.ScalarMultiplication(r, Forward);
			var ss:Vector3= Vector3.ScalarMultiplication(r,Side);
			var pp:Vector3 = Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(0.2,Up));
			annotation.Line(Vector3.VectorAddition(Vector3.VectorAddition(pp , ff) , ss), Vector3.VectorSubtraction(pp , Vector3.VectorAddition(ff , ss)), Colors.White);
			annotation.Line(Vector3.VectorSubtraction(pp , Vector3.VectorSubtraction(ff , ss)), Vector3.VectorSubtraction(pp , Vector3.VectorAddition(ff , ss)), Colors.White);
			annotation.Line(Vector3.VectorSubtraction(pp , Vector3.VectorSubtraction(ff , ss)), Vector3.VectorSubtraction(Vector3.VectorAddition(pp , ff) , ss), Colors.White);
			annotation.Line(Vector3.VectorAddition(Vector3.VectorAddition(pp , ff) , ss), Vector3.VectorSubtraction(Vector3.VectorAddition(pp , ff) , ss), Colors.White);

			//OpenSteerDemo.clock.setPausedState (true);
		}

		// scan across the obstacle map along a given arc
		// (possibly with radius adjustment ramp)
		// returns approximate distance to first obstacle found
		//
		// QQQ 1: this calling sequence does not allow for zero curvature case
		// QQQ 2: in library version of this, "map" should be a parameter
		// QQQ 3: instead of passing in colors, call virtual annotation function?
		// QQQ 4: need flag saying to continue after a hit, for annotation
		// QQQ 5: I needed to return both distance-to and position-of the first
		//        obstacle. I added returnObstaclePosition but maybe this should
		//        return a "scan results object" with a flag for obstacle found,
		//        plus distant and position if so.
		//
		public function ScanObstacleMap(start:Vector3, center:Vector3, arcAngle:Number,segments:int, endRadiusChange:Number, beforeColor:uint, afterColor:uint, returnObstaclePosition:Vector3):Array
		{
			// "spoke" is initially the vector from center to start,
			// which is then rotated step by step around center
			var spoke:Vector3 = Vector3.VectorSubtraction(start , center);
			// determine the angular step per segment
			var step:Number = arcAngle / segments;
			// store distance to, and position of first obstacle
			var obstacleDistance:Number = 0;
			returnObstaclePosition = Vector3.Zero;
			// for spiral "ramps" of changing radius
			var startRadius:Number = (endRadiusChange == 0) ? 0 : spoke.Magnitude();

			// traverse each segment along arc
			var sin:Number = 0, cos:Number = 0;
			var oldPoint:Vector3 = start;
			var obstacleFound:Boolean = false;
			for (var i:int = 0; i < segments; i++)
			{
				// rotate "spoke" to next step around circle
				// (sin and cos values get filled in on first call)
				var temp:Array = VHelper.RotateAboutGlobalY(spoke, step, sin,cos);
				sin = temp[0];
				cos = temp[1];
				spoke = temp[2];
				// for spiral "ramps" of changing radius
				var adjust:Number = ((endRadiusChange == 0) ?
									  1.0 :
									  Utilities.Interpolate(Number(i + 1) / Number(segments),
												   1.0,
												   (Math.max(0,
															(startRadius +
															 endRadiusChange))
													/ startRadius)));

				// construct new scan point: center point, offset by rotated
				// spoke (possibly adjusting the radius if endRadiusChange!=0)
				var newPoint:Vector3 = Vector3.VectorAddition(center , Vector3.ScalarMultiplication(adjust,spoke));

				// once an obstacle if found "our work here is done" -- continue
				// to loop only for the sake of annotation (make that optional?)
				if (obstacleFound)
				{
					annotation.Line(oldPoint, newPoint, afterColor);
				}
				else
				{
					// no obstacle found on this scan so far,
					// scan map along current segment (a chord of the arc)
					var offset:Vector3 = Vector3.VectorSubtraction(newPoint , oldPoint);
					var d2:Number = offset.Magnitude() * 2;

					// when obstacle found: set flag, save distance and position
					if (!map.IsPassable(newPoint))
					{
						obstacleFound = true;
						obstacleDistance = d2 * 0.5 * (i + 1);
						returnObstaclePosition = newPoint;
					}
					annotation.Line(oldPoint, newPoint, beforeColor);
				}
				// save new point for next time around loop
				oldPoint = newPoint;
			}
			// return distance to first obstacle (or zero if none found)
			var tmpArr2:Array = new Array();
			tmpArr2.push(obstacleDistance);
			tmpArr2.push(returnObstaclePosition);
			return tmpArr2;
		}

		public function  DetectImminentCollision():Boolean
		{
			// QQQ  this should be integrated into steerToAvoidObstaclesOnMap
			// QQQ  since it shares so much infrastructure
			// QQQ  less so after changes on 3-16-04
			var returnFlag:Boolean = false;
			var spacing:Number = map.MinSpacing() / 2;
			var maxSide:Number = halfWidth + spacing;
			var minDistance:Number = curvedSteering ? 2.0 : 2.5; // meters
			var predictTime:Number = curvedSteering ? .75 : 1.3; // seconds
			var maxForward:Number = Speed * CombinedLookAheadTime(predictTime, minDistance);
			var step:Vector3 = Vector3.ScalarMultiplication(spacing,Forward);
			var s:Number = curvedSteering ? (spacing / 4) : (spacing / 2);

			var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
			var localCenterOfCurvature:Vector3 = Vector3.ScalarMultiplication(signedRadius,Side);
			var center:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
			var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
			var arcRadius:Number = signedRadius * -sign;
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * arcRadius;
			var qqqLift:Vector3 = new Vector3(0, 0.2, 0);
			var ignore:Vector3;

			// scan region ahead of vehicle
			while (s < maxSide)
			{
				var sOffset:Vector3 = Vector3.ScalarMultiplication(s,Side);
				var lOffset:Vector3 = Vector3.VectorAddition(Position , sOffset);
				var rOffset:Vector3 = Vector3.VectorSubtraction(Position , sOffset);
				var bevel:Number = 0.3;
				var fraction:Number = s / maxSide;
				var scanDist:Number = (halfLength +
										Utilities.Interpolate(fraction,
													 maxForward,
													 maxForward * bevel));
				var angle:Number = (scanDist * twoPi * sign) / circumference;
				var samples:int = int(scanDist / spacing);
				
				var tmpArr1:Array = ScanObstacleMap(Vector3.VectorAddition(lOffset , qqqLift),
													   center,
													   angle,
													   samples,
													   0,
													   Colors.Magenta,
													   Colors.Cyan,
													   ignore);
				var tmpInt:int = int(tmpArr1[0]);
				ignore = tmpArr1[1];
				
				var L:int = (curvedSteering ? (tmpInt / spacing) :  map.ScanXZray(lOffset, step, samples));
				
				var tmpArr2:Array = ScanObstacleMap(Vector3.VectorAddition(rOffset , qqqLift),
													   center,
													   angle,
													   samples,
													   0,
													   Colors.Magenta,
													   Colors.Cyan,
													   ignore);
				var tmpInt2:int = int(tmpArr2[0]);
				ignore = tmpArr2[1];
				var R:int = (curvedSteering ? (tmpInt2 / spacing) :  map.ScanXZray(rOffset, step, samples));

				returnFlag = returnFlag || (L > 0);
				returnFlag = returnFlag || (R > 0);

				// annotation
				if (!curvedSteering)
				{
					var d:Vector3 = Vector3.ScalarMultiplication(Number(samples),step);
					annotation.Line(lOffset, Vector3.VectorAddition(lOffset , d), Colors.White);
					annotation.Line(rOffset, Vector3.VectorAddition(rOffset , d), Colors.White);
				}

				// increment sideways displacement of scan line
				s += spacing;
			}
			return returnFlag;
		}

		// see comments at SimpleVehicle.predictFuturePosition, in this instance
		// I just need the future position (not a LocalSpace), so I'll keep the
		// calling sequence and just conditionalize its body
		//
		// this should be const, but easier for now to ignore that
		public override function PredictFuturePosition(predictionTime:Number):Vector3
		{
			if (curvedSteering)
			{
				// QQQ this chunk of code is repeated in far too many places,
				// QQQ it has to be moved inside some utility
				// QQQ 
				// QQQ and now, worse, I rearranged it to try the "limit arc
				// QQQ angle" trick
				var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
				var localCenterOfCurvature:Vector3 = Vector3.ScalarMultiplication(signedRadius, Side);
				var center:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
				var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
				var arcRadius:Number = signedRadius * -sign;
				var twoPi:Number = 2 * Number(Math.PI);
				var circumference:Number = twoPi * arcRadius;
				var rawLength:Number = Speed * predictionTime * sign;
				var arcLength:Number = ArcLengthLimit(rawLength, circumference * 0.25);
				var arcAngle:Number = twoPi * arcLength / circumference;

				var spoke:Vector3 = Vector3.VectorSubtraction(Position , center);
				var newSpoke:Vector3= spoke.RotateAboutGlobalY(arcAngle);
				var prediction:Vector3 = Vector3.VectorAddition(newSpoke , center);

				// QQQ unify with annotatePathFollowing
				var futurePositionColor:uint = Colors.RGBToHex(int(255.0 * 0.5), int(255.0 * 0.5), int(255.0 * 0.6));
				AnnotationXZArc(Position, center, arcLength, 20, futurePositionColor);
				return prediction;
			}
			else
			{
				return Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(predictionTime,Velocity));
			}
		}

		// QQQ experimental fix for arcLength limit in predictFuturePosition
		// QQQ and steerToAvoidObstaclesOnMap.
		//
		// args are the intended arc length (signed!), and the limit which is
		// a given (positive!) fraction of the arc's (circle's) circumference
		//
		public function ArcLengthLimit(length:Number, limit:Number):Number
		{
			if (length > 0)
				return Math.min(length, limit);
			else
				return -Math.min(-length, limit);
		}

		// this is a version of the one in SteerLibrary.h modified for "slow when
		// heading off path".  I put it here because the changes were not
		// compatible with Pedestrians.cpp.  It needs to be merged back after
		// things settle down.
		//
		// its been modified in other ways too (such as "reduce the offset if
		// facing in the wrong direction" and "increase the target offset to
		// compensate the fold back") plus I changed the type of "path" from
		// Pathway to GCRoute to use methods like indexOfNearestSegment and
		// dotSegmentUnitTangents
		//
		// and now its been modified again for curvature-based prediction
		//
		public override function SteerToFollowPath(direction:int, predictionTime:Number, path:Pathway):Vector3 //Mhack - should be GCRoute
		{
			if (curvedSteering)
				return SteerToFollowPathCurve(direction, predictionTime, GCRoute(path));
			else
				return SteerToFollowPathLinear(direction, predictionTime, GCRoute(path));
		}

		public function SteerToFollowPathLinear(direction:int, predictionTime:Number, path:GCRoute):Vector3
		{
			// our goal will be offset from our path distance by this amount
			var pathDistanceOffset:Number = direction * predictionTime * Speed;

			// predict our future position
			var futurePosition:Vector3 = PredictFuturePosition(predictionTime);

			// measure distance along path of our current and predicted positions
			var nowPathDistance:Number =
				path.MapPointToPathDistance(Position);

			// are we facing in the correction direction?
			var pathHeading:Vector3 = Vector3.ScalarMultiplication(Number(direction),path.TangentAt(Position));
			var correctDirection:Boolean = pathHeading.DotProduct(Forward) > 0;

			// find the point on the path nearest the predicted future position
			// XXX need to improve calling sequence, maybe change to return a
			// XXX special path-defined object which includes two Vector3s and a 
			// XXX bool (onPath,tangent (ignored), withinPath)
			var futureOutside:Number;
			var temp:Array = path.callMapPointToPath(futurePosition, futureOutside);
			var onPath:Vector3 = temp[0];
			futureOutside = temp[2];

			// determine if we are currently inside the path tube
			var nowOutside:Number;
			var temp2:Array = path.callMapPointToPath(Position,  nowOutside);
			var nowOnPath:Vector3 = temp2[0];
			nowOutside = temp2[2];
			
			// no steering is required if our present and future positions are
			// inside the path tube and we are facing in the correct direction
			var m:Number = -Radius;
			var whollyInside:Boolean = (futureOutside < m) && (nowOutside < m);
			if (whollyInside && correctDirection)
			{
				// all is well, return zero steering
				return Vector3.Zero;
			}
			else
			{
				// otherwise we need to steer towards a target point obtained
				// by adding pathDistanceOffset to our current path position
				// (reduce the offset if facing in the wrong direction)
				var targetPathDistance:Number = (nowPathDistance +
												  (pathDistanceOffset *
												   (correctDirection ? 1 : 0.1)));
				var target:Vector3 = path.MapPathDistanceToPoint(targetPathDistance);


				// if we are on one segment and target is on the next segment and
				// the dot of the tangents of the two segments is negative --
				// increase the target offset to compensate the fold back
				var ip:int = path.IndexOfNearestSegment(Position);
				var it:int = path.IndexOfNearestSegment(target);
				if (((ip + direction) == it) &&
					(path.DotSegmentUnitTangents(it, ip) < -0.1))
				{
					var newTargetPathDistance:Number =
						nowPathDistance + (pathDistanceOffset * 2);
					target = path.MapPathDistanceToPoint(newTargetPathDistance);
				}

				AnnotatePathFollowing(futurePosition, onPath, target, futureOutside);

				// if we are currently outside head directly in
				// (QQQ new, experimental, makes it turn in more sharply)
				if (nowOutside > 0)
				{
					return SteerForSeek(nowOnPath);
				}

				// steering to seek target on path
				var seek:Vector3 = VHelper.TruncateLength(SteerForSeek(target), MaxForce);

				// return that seek steering -- except when we are heading off
				// the path (currently on path and future position is off path)
				// in which case we put on the brakes.
				if ((nowOutside < 0) && (futureOutside > 0))
					return Vector3.VectorSubtraction(VHelper.PerpendicularComponent(seek, Forward) , Vector3.ScalarMultiplication(MaxForce,Forward));
				else
					return seek;
			}
		}

		// Path following case for curved prediction and incremental steering
		// (called from steerToFollowPath for the curvedSteering case)
		//
		// QQQ this does not handle the case when we AND futurePosition
		// QQQ are outside, say when approach the path from far away
		//
		public function SteerToFollowPathCurve(direction:int,predictionTime:Number, path:GCRoute):Vector3
		{
			// predict our future position (based on current curvature and speed)
			var futurePosition:Vector3 = PredictFuturePosition(predictionTime);
			// find the point on the path nearest the predicted future position
			var futureOutside:Number;
			var temp:Array = path.callMapPointToPath(futurePosition, futureOutside);
			var onPath:Vector3 = temp[0];
			futureOutside = temp[2];
			var pathHeading:Vector3 = path.TangentAt(onPath, direction);
			var rawBraking:Vector3 = Vector3.ScalarMultiplication(MaxForce * -1,Forward);
			var braking:Vector3 = ((futureOutside < 0) ? Vector3.Zero : rawBraking);
			//qqq experimental wrong-way-fixer
			var nowOutside:Number;
			var nowTangent:Vector3 = Vector3.Zero;
			var p:Vector3 = Position;
			
			var temp2:Array = path.MapPointToPath(p, nowTangent, nowOutside);
			var nowOnPath:Vector3 = temp2[0];
			nowTangent = temp2[1];
			nowOutside = temp2[2];
			
			nowTangent = Vector3.ScalarMultiplication(Number(direction),nowTangent);
			var alignedness:Number = nowTangent.DotProduct(Forward);

			// facing the wrong way?
			if (alignedness < 0)
			{
				annotation.Line(p, Vector3.VectorAddition(p , Vector3.ScalarMultiplication(10,nowTangent)), Colors.Cyan);

				// if nearly anti-parallel
				if (alignedness < -0.707)
				{
					var towardCenter:Vector3 = Vector3.VectorSubtraction(nowOnPath , p);
					var turn:Vector3 = (towardCenter.DotProduct(Side) > 0 ?
									   Vector3.ScalarMultiplication(MaxForce,Side) :
									   Vector3.ScalarMultiplication(MaxForce * -1,Side));
					return Vector3.VectorAddition(turn , rawBraking);
				}
				else
				{
					return Vector3.VectorAddition(VHelper.PerpendicularComponent(SteerTowardHeading(pathHeading), Forward) , braking);
				}
			}

			// is the predicted future position(+radius+margin) inside the path?
			if (futureOutside < -(Radius + 1.0)) //QQQ
			{
				// then no steering is required
				return Vector3.Zero;
			}
			else
			{
				// otherwise determine corrective steering (including braking)
				annotation.Line(futurePosition, Vector3.VectorAddition(futurePosition , pathHeading), Colors.Red);
				AnnotatePathFollowing(futurePosition, onPath,
									   Position, futureOutside);

				// two cases, if entering a turn (a waypoint between path segments)
				if (path.NearWaypoint(onPath) && (futureOutside > 0))
				{
					// steer to align with next path segment
					annotation.Circle3D(0.5, futurePosition, Up, Colors.Red, 8);
					return Vector3.VectorAddition(SteerTowardHeading(pathHeading) , braking);
				}
				else
				{
					// otherwise steer away from the side of the path we
					// are heading for
					var pathSide:Vector3 = LocalRotateForwardToSide(pathHeading);
					var towardFP:Vector3 = Vector3.VectorAddition(futurePosition , onPath);
					var whichSide:Number = (pathSide.DotProduct(towardFP) < 0) ? 1.0 : -1.0;
					return Vector3.VectorAddition(Vector3.ScalarMultiplication(MaxForce * whichSide,Side) , braking);
				}
			}
		}

		public function PerFrameAnnotation():void
		{
			var p:Vector3 = Position;

			// draw the circular collision boundary
			annotation.CircleOrDisk(Radius, Up, p, Colors.Black, 7, false, false);

			// draw forward sensing corridor and wings ( for non-curved case)
			if (!curvedSteering)
			{
				var corLength:Number = Speed * LookAheadTimeOA();
				if (corLength > halfLength)
				{
					var corFront:Vector3 = Vector3.ScalarMultiplication(corLength,Forward);
					var corBack:Vector3 = Vector3.Zero; // (was bbFront)
					var corSide:Vector3 = Vector3.ScalarMultiplication(Radius,Side);
					var c1:Vector3 = Vector3.VectorAddition(p , Vector3.VectorAddition(corSide , corBack));
					var c2:Vector3 = Vector3.VectorAddition(p , Vector3.VectorAddition(corSide , corFront));
					var c3:Vector3 = Vector3.VectorSubtraction(p , Vector3.VectorAddition(corSide , corFront));
					var c4:Vector3 = Vector3.VectorSubtraction(p , Vector3.VectorAddition(corSide , corBack));
					var color:uint = ((Vector3.isNotEqual(annotateAvoid, Vector3.Zero)) ? Colors.Red : Colors.Yellow);
					annotation.Line(c1, c2, color);
					annotation.Line(c2, c3, color);
					annotation.Line(c3, c4, color);

					// draw sensing "wings"
					var wingWidth:Vector3 = Vector3.ScalarMultiplication(WingSlope() * corLength,Side);
					var wingTipL:Vector3 = Vector3.VectorAddition(c2 , wingWidth);
					var wingTipR:Vector3 = Vector3.VectorSubtraction(c3 , wingWidth);
					var wingColor:uint = Colors.Orange;
					if (wingDrawFlagL) annotation.Line(c2, wingTipL, wingColor);
					if (wingDrawFlagL) annotation.Line(c1, wingTipL, wingColor);
					if (wingDrawFlagR) annotation.Line(c3, wingTipR, wingColor);
					if (wingDrawFlagR) annotation.Line(c4, wingTipR, wingColor);
				}
			}

			// annotate steering acceleration
			var above:Vector3 = Vector3.VectorAddition(Position , new Vector3(0, 0.2, 0));
			var accel:Vector3 = Vector3.ScalarMultiplication(1/MaxForce,Vector3.ScalarMultiplication(5,Acceleration));
			var aColor:uint = Colors.RGBToHex(int(255.0 * 0.4), int(255.0 * 0.4), int(255.0 * 0.8));
			annotation.Line(above, Vector3.VectorAddition(above , accel), aColor);
		}

		// draw vehicle's body and annotation
		public function Draw():void
		{
			VehicleMesh.geometry.faces = [];
			VehicleMesh.geometry.vertices = [];
				
			// for now: draw as a 2d bounding box on the groundq
			var bodyColor:uint = Colors.Black;
			if (stuck) bodyColor = Colors.Yellow;
			if (!IsBodyInsidePath()) bodyColor = Colors.Orange;
			if (collisionDetected) bodyColor = Colors.Red;

			// draw vehicle's bounding box on gound plane (its "shadow")
			var p:Vector3 = Position;
			var bbSide:Vector3 = Vector3.ScalarMultiplication(halfWidth, Side);
			var bbFront:Vector3 = Vector3.ScalarMultiplication(halfLength, Forward);
			var bbHeight:Vector3 = new Vector3(0, 0.1, 0);
			
			var vertA:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(Vector3.VectorSubtraction(p , bbFront) , bbSide) , bbHeight).ToVertex3D();
			var vertB:Vertex3D = Vector3.VectorAddition(Vector3.VectorAddition(Vector3.VectorAddition(p , bbFront) , bbSide) , bbHeight).ToVertex3D();
			var vertC:Vertex3D = Vector3.VectorAddition(Vector3.VectorSubtraction(Vector3.VectorAddition(p , bbFront) , bbSide) , bbHeight).ToVertex3D();
			var vertD:Vertex3D = Vector3.VectorAddition(Vector3.VectorSubtraction(Vector3.VectorSubtraction(p , bbFront) , bbSide) , bbHeight).ToVertex3D();
			
			VehicleMesh.geometry.vertices.push(vertA, vertB,vertC, vertD);
				
			var color:uint = bodyColor;
			var colMaterial:ColorMaterial = new ColorMaterial(color, 1);
			colMaterial.doubleSided = true;
			
			var t1:Triangle3D = new Triangle3D(VehicleMesh, [vertA,vertB,vertC], colMaterial);
			var t2:Triangle3D = new Triangle3D(VehicleMesh, [vertD,vertA,vertC], colMaterial);
				
			VehicleMesh.geometry.faces.push(t1);
			VehicleMesh.geometry.faces.push(t2);
				
			VehicleMesh.geometry.ready = true;

			// annotate trail
			var darkGreen:uint = Colors.VectorToHex(new Vector3(0, (255.0 * 0.6), 0));
			trail.TrailColor = darkGreen;
			trail.TickColor = Colors.Black;
			annotation.DrawAllTrails();
		}

		// called when steerToFollowPath decides steering is required
		public function AnnotatePathFollowing(future:Vector3, onPath:Vector3, target:Vector3,outside:Number):void
		{
			var toTargetColor:uint = Colors.RGBToHex(0, int(255.0 * 0.6), 0);
			var insidePathColor:uint = Colors.RGBToHex(int(255.0 * 0.6), int(255.0 * 0.6), 0);
			var outsidePathColor:uint = Colors.RGBToHex(0, 0, int(255.0 * 0.6));
			var futurePositionColor:uint = Colors.RGBToHex(int(255.0 * 0.5), int(255.0 * 0.5), int(255.0 * 0.6));

			// draw line from our position to our predicted future position
			if (!curvedSteering)
			{
				annotation.Line(Position, future, futurePositionColor);
			}

			// draw line from our position to our steering target on the path
			annotation.Line(Position, target, toTargetColor);

			// draw a two-toned line between the future test point and its
			// projection onto the path, the change from dark to light color
			// indicates the boundary of the tube.

			var o:Number = outside + Radius + (curvedSteering ? 1.0 : 0.0);
			var boundaryOffset:Vector3 = Vector3.VectorSubtraction(onPath , future);
			boundaryOffset.Normalize();
			boundaryOffset = Vector3.ScalarMultiplication(o,boundaryOffset);

			var onPathBoundary:Vector3 = Vector3.VectorAddition(future , boundaryOffset);
			annotation.Line(onPath, onPathBoundary, insidePathColor);
			annotation.Line(onPathBoundary, future, outsidePathColor);
		}

		public function DrawMap():void
		{
			MapMesh.geometry.faces = [];
			MapMesh.geometry.vertices = [];
			
			var xs:Number = map.xSize / Number(map.resolution);
			var zs:Number = map.zSize / Number(map.resolution);
			var alongRow:Vector3 = new Vector3(xs, 0, 0);
			var nextRow:Vector3 = new Vector3(-map.xSize, 0, zs);
			var g:Vector3 = new Vector3((map.xSize - xs) / -2, 0, (map.zSize - zs) / -2);
			g = Vector3.VectorAddition(g, map.center);
			var orangeRockColor:uint = Colors.VectorToHex(new Vector3((255.0 * 0.5), (255.0 * 0.2), (255.0 * 0.0)));
			var colMaterial:ColorMaterial = new ColorMaterial(orangeRockColor, 1);
			colMaterial.doubleSided = true;
			for (var j:int = 0; j < map.resolution; j++)
			{
				for (var i:int = 0; i < map.resolution; i++)
				{	
					if (map.GetMapBit(i, j))
					{
						// squares
						var rockHeight:Number = 0.0;
						var v1:Vector3 = new Vector3(+xs / 2, rockHeight, +zs / 2);
						var v2:Vector3 = new Vector3(+xs / 2, rockHeight, -zs / 2);
						var v3:Vector3 = new Vector3( -xs / 2, rockHeight, -zs / 2);
						var v4:Vector3 = new Vector3( -xs / 2, rockHeight, +zs / 2);
						
						var vertA:Vertex3D = Vector3.VectorAddition(g, v1).ToVertex3D();
						var vertB:Vertex3D = Vector3.VectorAddition(g, v2).ToVertex3D();
						var vertC:Vertex3D = Vector3.VectorAddition(g, v3).ToVertex3D();
						var vertD:Vertex3D = Vector3.VectorAddition(g, v4).ToVertex3D();
						
						MapMesh.geometry.vertices.push(vertA, vertB, vertC, vertD);

						var t1:Triangle3D = new Triangle3D(MapMesh, [vertA,vertB,vertC], colMaterial);
						var t2:Triangle3D = new Triangle3D(MapMesh, [vertD,vertA,vertC], colMaterial);
							
						MapMesh.geometry.faces.push(t1);
						MapMesh.geometry.faces.push(t2);
					}
					g = Vector3.VectorAddition(g,alongRow);
				}
				g = Vector3.VectorAddition(g,nextRow);
			}
			MapMesh.geometry.ready = true;
		}

		// draw the GCRoute as a series of circles and "wide lines"
		// (QQQ this should probably be a method of Path (or a
		// closely-related utility function) in which case should pass
		// color in, certainly shouldn't be recomputing it each draw)
		public function DrawPath():void
		{
			PathMesh.geometry.faces = [];
			PathMesh.geometry.vertices = [];
			
			lines.geometry.faces = [];
			lines.geometry.vertices = [];
			lines.removeAllLines();
				
			var pathColor:Vector3 = new Vector3(0, 0.5, 0.5);
			var sandColor:Vector3 = new Vector3(0.8, 0.7, 0.5);
			var vColor:Vector3 = Utilities.Interpolate2(0.1, sandColor, pathColor);
			var color:uint = Colors.VectorToHex(vColor);

			var down:Vector3 = new Vector3(0, -0.1, 0);
			for (var i:int = 0; i < path.pointCount; i++)
			{
				var endPoint0:Vector3 = Vector3.VectorAddition(path.points[i] , down);
				if (i > 0)
				{
					var endPoint1:Vector3 = Vector3.VectorAddition(path.points[i - 1] , down);

					var legWidth:Number = path.radii[i];
				
					DrawXZWideLine(endPoint0, endPoint1, color, legWidth * 2);
					DrawLine(path.points[i], path.points[i - 1], Colors.VectorToHex(pathColor));
					DrawCircleOrDisk(legWidth, Vector3.Zero,endPoint0, color, 7,true,false);
					DrawCircleOrDisk(legWidth, Vector3.Zero,endPoint1, color, 7,true,false);
				}
			}
		}
		
		private function DrawXZWideLine(startPoint:Vector3, endPoint:Vector3, color:uint, width:Number):void
		{			
			var offset:Vector3 = Vector3.VectorSubtraction(endPoint , startPoint);
			offset.Normalize();
            var perp:Vector3 = Demo.localSpace.LocalRotateForwardToSide(offset);
			var radius:Vector3 = Vector3.ScalarMultiplication(width / 2, perp);
			
			var vertA:Vertex3D = Vector3.VectorAddition(startPoint , radius).ToVertex3D();
			var vertB:Vertex3D = Vector3.VectorAddition(endPoint , radius).ToVertex3D();
			var vertC:Vertex3D = Vector3.VectorSubtraction(endPoint , radius).ToVertex3D();
			var vertD:Vertex3D = Vector3.VectorSubtraction(startPoint , radius).ToVertex3D();

			PathMesh.geometry.vertices.push(vertA, vertB,vertC, vertD);
					
			var color:uint = Colors.RGBToHex((255.0 * 0.8), int(255.0 * 0.7), int(255.0 * 0.5));
			var colMaterial:ColorMaterial = new ColorMaterial(color, 1);
			colMaterial.doubleSided = true;
			
			var t1:Triangle3D = new Triangle3D(PathMesh, [vertA,vertB,vertC], colMaterial);
			var t2:Triangle3D = new Triangle3D(PathMesh, [vertD,vertA,vertC], colMaterial);
				
			PathMesh.geometry.faces.push(t1);
			PathMesh.geometry.faces.push(t2);
			
			PathMesh.geometry.ready = true;
		}
		
		private function DrawLine(startPoint:Vector3, endPoint:Vector3, color:uint):void
		{
			lines.addLine(new Line3D(lines, new LineMaterial(color,1),1,new Vertex3D(startPoint.x,startPoint.y,startPoint.z),new Vertex3D(endPoint.x,endPoint.y,endPoint.z)));
		}
		
		private function DrawCircleOrDisk(radius:Number,axis:Vector3,center:Vector3,color:uint,segments:int,filled:Boolean,in3d:Boolean):void
		{
			if (Demo.IsDrawPhase())
			{
				var temp : Number3D = new Number3D(Radius,0,0);
				var tempcurve:Number3D = new Number3D(0,0,0);
				var joinends : Boolean;
				var i:int;
				var pointcount : int;
				
				var angle:Number = (0-360)/segments;
				var curveangle : Number = angle/2;

				tempcurve.x = Radius/Math.cos(curveangle * Number3D.toRADIANS);
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
					var line:Line3D = new Line3D(lines, new LineMaterial(Colors.White), 2, vertices[i], vertices[(i+1)%vertices.length]);	
					line.addControlVertex(curvepoints[i].x, curvepoints[i].y, curvepoints[i].z );
					lines.addLine(line);
				}
			}
			else
			{
				DeferredCircle.AddToBuffer(lines,Radius, axis, center, color, segments, filled, in3d);
			}
		}
		
		public function MakePath():GCRoute
		{
			// a few constants based on world size
			var m:Number = worldSize * 0.4; // main diamond size
			var n:Number = worldSize / 8;    // notch size
			var o:Number = worldSize * 2;    // outside of the sand

			// construction vectors
			var p:Vector3 = new Vector3(0, 0, m);
			var q:Vector3 = new Vector3(0, 0, m - n);
			var r:Vector3 = new Vector3(-m, 0, 0);
			var s:Vector3 = new Vector3(2 * n, 0, 0);
			var t:Vector3 = new Vector3(o, 0, 0);
			var u:Vector3 = new Vector3(-o, 0, 0);
			var v:Vector3 = new Vector3(n, 0, 0);
			var w:Vector3 = new Vector3(0, 0, 0);

			// path vertices
			var a:Vector3 = Vector3.VectorSubtraction(t , p);
			var b:Vector3 = Vector3.VectorSubtraction(Vector3.VectorAddition(s , v) , p);
			var c:Vector3 = Vector3.VectorSubtraction(s , q);
			var d:Vector3 = Vector3.VectorAddition(s , q);
			var e:Vector3 = Vector3.VectorAddition(Vector3.VectorSubtraction(s, v) , p);
			var f:Vector3 = Vector3.VectorSubtraction(p , w);
			var g:Vector3 = Vector3.VectorSubtraction(r , w);
			var h:Vector3 = Vector3.VectorSubtraction(Vector3.Negate(p) , w);
			var i:Vector3 = Vector3.VectorSubtraction(u , p);

			// return Path object
			var pathPointCount:int = 9;
			var pathPoints:Vector.<Vector3> = new Vector.<Vector3>(9);
			pathPoints[0] = a;
			pathPoints[1] = b;
			pathPoints[2] = c;
			pathPoints[3] = d;
			pathPoints[4] = e;
			pathPoints[5] = f;
			pathPoints[6] = g;
			pathPoints[7] = h;
			pathPoints[8] = i;
			var k:Number = 10.0;
			var pathRadii:Vector.<Number> = new Vector.<Number>(9);
			pathRadii[0] = k;
			pathRadii[1] = k;
			pathRadii[2] = k;
			pathRadii[3] = k;
			pathRadii[4] = k;
			pathRadii[5] = k;
			pathRadii[6] = k;
			pathRadii[7] = k;
			pathRadii[8] = k;
			return new GCRoute(pathPointCount, pathPoints, pathRadii, false);
		}

		public function MakeMap():TerrainMap 
		{
			return new TerrainMap(Vector3.Zero, worldSize, worldSize, int(worldSize + 1));
		}

		public function HandleExitFromMap():Boolean
		{
			if (demoSelect == 2)
			{
				// for path following, do wrap-around (teleport) and make new map
				var px:Number = Position.x;
				var fx:Number = Forward.x;
				var ws :Number= worldSize * 0.51; // slightly past edge
				if (((fx > 0) && (px > ws)) || ((fx < 0) && (px < -ws)))
				{
					// bump counters
					lapsStarted++;
					lapsFinished++;

					var camOffsetBefore:Vector3 = Vector3.VectorSubtraction(Demo.camera.Position , Position);

					// set position on other side of the map (set new X coordinate)
					SetPosition((((px < 0) ? 1 : -1) *
								  ((worldSize * 0.5) +
								   (Speed * LookAheadTimePF()))),
								 Position.y,
								 Position.z);

					// reset bookeeping to detect stuck cycles
					ResetStuckCycleDetection();

					// new camera position and aimpoint to compensate for teleport
					Demo.camera.Target = Position;
					Demo.camera.Position = Vector3.VectorAddition(Position , camOffsetBefore);
					
					// make camera jump immediately to new position
					Demo.camera.DoNotSmoothNextMove();

					// prevent long streaks due to teleportation 
					trail.Clear();

					return true;
				}
			}
			else
			{
				// for the non-path-following demos:
				// reset simulation if the vehicle drives through the fence
				if (Position.Magnitude() > worldDiag) Reset();
			}
			return false;
		}


		// QQQ move this utility to SimpleVehicle?
		public function RelativeSpeed():Number { return Speed / MaxSpeed; }

		public function WingSlope():Number
		{
			return Utilities.Interpolate(RelativeSpeed(),
								(curvedSteering ? 0.3 : 0.35),
								0.06);
		}

		public function ResetStuckCycleDetection():void
		{
			ResetSmoothedPosition(Vector3.VectorAddition(Position , Vector3.ScalarMultiplication(-80,Forward))); // qqq
		}

		// QQQ just a stop gap, not quite right
		// (say for example we were going around a circle with radius > 10)
		public function WeAreGoingInCircles():Boolean
		{
			var offset:Vector3 = Vector3.VectorSubtraction(SmoothedPosition() , Position);
			return offset.Magnitude() < 10;
		}

		public function LookAheadTimeOA():Number
		{
			var minTime:Number = (baseLookAheadTime *
								   (curvedSteering ?
									Utilities.Interpolate(RelativeSpeed(), 0.4, 0.7) :
									0.66));
			return CombinedLookAheadTime(minTime, 3);
		}

		public function LookAheadTimePF():Number
		{
			return CombinedLookAheadTime(baseLookAheadTime, 3);
		}

		// QQQ maybe move to SimpleVehicle ?
		// compute a "look ahead time" with two components, one based on
		// minimum time to (say) a collision and one based on minimum distance
		// arg 1 is "seconds into the future", arg 2 is "meters ahead"
		public function CombinedLookAheadTime(minTime:Number, minDistance:Number):Number
		{
			if (Speed == 0) return 0;
			return Math.max(minTime, minDistance / Speed);
		}

		// is vehicle body inside the path?
		// (actually tests if all four corners of the bounbding box are inside)
		//
		public function IsBodyInsidePath():Boolean
		{
			if (demoSelect == 2)
			{
				var bbSide:Vector3 = Vector3.ScalarMultiplication(halfWidth,Side);
				var bbFront:Vector3 = Vector3.ScalarMultiplication(halfLength,Forward);
				return (path.IsInsidePath(Vector3.VectorAddition(Vector3.VectorSubtraction(Position , bbFront) , bbSide)) &&
						path.IsInsidePath(Vector3.VectorAddition(Vector3.VectorAddition(Position , bbFront) , bbSide)) &&
						path.IsInsidePath(Vector3.VectorSubtraction(Vector3.VectorAddition(Position , bbFront) , bbSide)) &&
						path.IsInsidePath(Vector3.VectorSubtraction(Vector3.VectorSubtraction(Position , bbFront) , bbSide)));
			}
			return true;
		}

		public function ConvertAbsoluteToIncrementalSteering(absolute:Vector3, elapsedTime:Number):Vector3
		{
			var curved:Vector3 = ConvertLinearToCurvedSpaceGlobal(absolute);
			currentSteering = Utilities.BlendIntoAccumulator2(elapsedTime * 8.0, curved, currentSteering);
			{
				// annotation
				var u:Vector3 = new Vector3(0, 0.5, 0);
				var p:Vector3 = Position;
				annotation.Line(Vector3.VectorAddition(p , u), Vector3.VectorAddition(Vector3.VectorAddition(p , u) , absolute), Colors.Red);
				annotation.Line(Vector3.VectorAddition(p , u), Vector3.VectorAddition(Vector3.VectorAddition(p , u) , curved), Colors.Yellow);
				annotation.Line(Vector3.ScalarMultiplication(2,Vector3.VectorAddition(p , u)), Vector3.ScalarMultiplication(2+currentSteering,Vector3.VectorAddition(p , u)), Colors.Green);
			}
			return currentSteering;
		}

		// QQQ new utility 2-25-04 -- may replace inline code elsewhere
		//
		// Given a location in this vehicle's linear local space, convert it into
		// the curved space defined by the vehicle's current path curvature.  For
		// example, forward() gets mapped on a point 1 unit along the circle
		// centered on the current center of curvature and passing through the
		// vehicle's position().
		//
		public function ConvertLinearToCurvedSpaceGlobal(linear:Vector3):Vector3
		{
			var trimmedLinear:Vector3 = VHelper.TruncateLength(linear, MaxForce);

			// ---------- this block imported from steerToAvoidObstaclesOnMap
			var  signedRadius:Number = 1 / (NonZeroCurvatureQQQ() /*QQQ*/ * 1);
			var localCenterOfCurvature:Vector3 = Vector3.ScalarMultiplication(signedRadius,Side);
			var center:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
			var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
			var arcLength:Number = trimmedLinear.DotProduct(Forward);
			//
			var arcRadius:Number = signedRadius * -sign;
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * arcRadius;
			var arcAngle:Number = twoPi * arcLength / circumference;
			// ---------- this block imported from steerToAvoidObstaclesOnMap

			// ---------- this block imported from scanObstacleMap
			// vector from center of curvature to position of vehicle
			var initialSpoke:Vector3 = Vector3.VectorSubtraction(Position , center);
			// rotate by signed arc angle
			var temp:Array = VHelper.RotateAboutGlobalY(initialSpoke, arcAngle * sign);
			var spoke:Vector3 = temp[2];
			// ---------- this block imported from scanObstacleMap

			var fromCenter:Vector3 = Vector3.Negate(localCenterOfCurvature);
			fromCenter.Normalize();
			var dRadius:Number = trimmedLinear.DotProduct( fromCenter);
			var radiusChangeFactor:Number = (dRadius + arcRadius) / arcRadius;
			var resultLocation:Vector3 = Vector3.VectorAddition(center , Vector3.ScalarMultiplication(radiusChangeFactor,spoke));
			{
				var center2:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
				AnnotationXZArc(Position, center2, Speed * sign * -3, 20, Colors.White);
			}
			// return the vector from vehicle position to the coimputed location
			// of the curved image of the original linear offset
			return Vector3.VectorSubtraction(resultLocation , Position);
		}

		// approximate value for the Polaris Ranger 6x6: 16 feet, 5 meters
		public function MinimumTurningRadius():Number { return 5.0; }

		public function AdjustSteeringForMinimumTurningRadius(steering:Vector3):Vector3
		{
			var maxCurvature:Number = 1 / (MinimumTurningRadius() * 1.1);

			// are we turning more sharply than the minimum turning radius?
			if (Math.abs(Curvature) > maxCurvature)
			{
				// remove the tangential (non-thrust) component of the steering
				// force, replace it with a force pointing away from the center
				// of curvature, causing us to "widen out" easing off from the
				// minimum turing radius
				var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
				var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
				var thrust:Vector3 = VHelper.ParallelComponent(steering, Forward);
				var trimmed:Vector3 = VHelper.TruncateLength(thrust, MaxForce);
				var widenOut:Vector3 = Vector3.ScalarMultiplication(MaxForce * sign,Side);
				{
					// annotation
					var localCenterOfCurvature:Vector3 = Vector3.ScalarMultiplication(signedRadius,Side);
					var center:Vector3 = Vector3.VectorAddition(Position , localCenterOfCurvature);
					annotation.CircleOrDisk(MinimumTurningRadius(), Up,
											center, Colors.Blue, 7, false, false);
				}
				return Vector3.VectorAddition(trimmed , widenOut);
			}

			// otherwise just return unmodified input
			return steering;
		}

		// QQQ This is to work around the bug that scanObstacleMap's current
		// QQQ arguments preclude the driving straight [curvature()==0] case.
		// QQQ This routine returns the current vehicle path curvature, unless it
		// QQQ is *very* close to zero, in which case a small positive number is
		// QQQ returned (corresponding to a radius of 100,000 meters).  
		// QQQ
		// QQQ Presumably it would be better to get rid of this routine and
		// QQQ redesign the arguments of scanObstacleMap
		//
		public function NonZeroCurvatureQQQ():Number
		{
			var c:Number = Curvature;
			var minCurvature:Number = 1.0 / 100000.0; // 100,000 meter radius
			var tooSmall:Boolean = (c < minCurvature) && (c > -minCurvature);
			return (tooSmall ? minCurvature : c);
		}

		// QQQ ad hoc speed limitation based on path orientation...
		// QQQ should be renamed since it is based on more than curvature
		//
		public function MaxSpeedForCurvature():Number
		{
			var maxRelativeSpeed:Number = 1;

			if (curvedSteering)
			{
				// compute an ad hoc "relative curvature"
				var absC:Number = Math.abs(Curvature);
				var maxC:Number = 1 / MinimumTurningRadius();
				var relativeCurvature:Number = Number(Math.sqrt(Utilities.Clip(absC / maxC, 0, 1)));

				// map from full throttle when straight to 10% at max curvature
				var curveSpeed:Number = Utilities.Interpolate(relativeCurvature, 1.0, 0.1);
				annoteMaxRelSpeedCurve = curveSpeed;

				if (demoSelect != 2)
				{
					maxRelativeSpeed = curveSpeed;
				}
				else
				{
					// heading (unit tangent) of the path segment of interest
					var pathHeading:Vector3 = path.TangentAt(Position, pathFollowDirection);
					// measure how parallel we are to the path
					var parallelness:Number = pathHeading.DotProduct(Forward);

					// determine relative speed for this heading
					var mw:Number = 0.2;
					var headingSpeed:Number = ((parallelness < 0) ? mw :
												Utilities.Interpolate(parallelness, mw, 1.0));
					maxRelativeSpeed = Math.min(curveSpeed, headingSpeed);
					annoteMaxRelSpeedPath = headingSpeed;
				}
			}
			annoteMaxRelSpeed = maxRelativeSpeed;
			return MaxSpeed * maxRelativeSpeed;
		}

		// xxx library candidate
		// xxx assumes (but does not check or enforce) heading is unit length
		//
		public function SteerTowardHeading(desiredGlobalHeading:Vector3):Vector3
		{
			var headingError:Vector3 = Vector3.VectorSubtraction(desiredGlobalHeading , Forward);
			headingError.Normalize();
			headingError = Vector3.ScalarMultiplication(MaxForce,headingError);

			return headingError;
		}

		// XXX this should eventually be in a library, make it a first
		// XXX class annotation queue, tie in with drawXZArc
		public function AnnotationXZArc(start:Vector3, center:Vector3, arcLength:Number, segments:int, color:uint):void
		{
			// "spoke" is initially the vector from center to start,
			// it is then rotated around its tail
			var spoke:Vector3 = Vector3.VectorSubtraction(start , center);

			// determine the angular step per segment
			var radius:Number= spoke.Magnitude();
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * radius;
			var arcAngle:Number = twoPi * arcLength / circumference;
			var step:Number = arcAngle / segments;

			// draw each segment along arc
			var sin:Number = 0, cos:Number = 0;
			for (var i:int = 0; i < segments; i++)
			{
				var old:Vector3 = Vector3.VectorAddition(spoke , center);

				// rotate point to next step around circle
				var temp:Array = VHelper.RotateAboutGlobalY(spoke, step, sin, cos);
				sin = temp[0];
				cos = temp[1];
				spoke = temp[2];
				annotation.Line(Vector3.VectorAddition(spoke , center), old, color);
			}
		}
	}
}
