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
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;*/

package tabinda.papersteer.plugins.MapDrive
{
	public class MapDriver extends SimpleVehicle
	{
		var trail:Trail;

		// constructor
		public function MapDriver()
		{
			map = MakeMap();
			path = MakePath();

			Reset();

			// to compute mean time between collisions
			sumOfCollisionFreeTimes = 0;
			countOfCollisionFreeTimes = 0;

			// keep track for reliability statistics
			collisionLastTime = false;
			timeOfLastCollision = Demo.Clock.TotalSimulationTime;

			// keep track of average speed
			totalDistance = 0;
			totalTime = 0;

			// keep track of path following failure rate
			pathFollowTime = 0;
			pathFollowOffTime = 0;

			// innitialize counters for various performance data
			stuckCount = 0;
			stuckCycleCount = 0;
			stuckOffPathCount = 0;
			lapsStarted = 0;
			lapsFinished = 0;
			hintGivenCount = 0;
			hintTakenCount = 0;

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
			Speed = 0;

			// Assume top speed is 20 meters per second (44.7 miles per hour).
			// This value will eventually be supplied by a higher level module.
			MaxSpeed = 20;

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
			if (trail == null) trail = new Trail(10, 200);

			// prevent long streaks due to teleportation 
			trail.Clear();

			// first pass at detecting "stuck" state
			stuck = false;

			// QQQ need to clean up this hack
			qqqLastNearestObstacle = Vector3.Zero;

			// master look ahead (prediction) time
			baseLookAheadTime = 3;

			if (demoSelect == 2)
			{
				lapsStarted++;
				var s:Number = worldSize;
				var d:Number = Number(pathFollowDirection);
				Position = (new Vector3(s * d * 0.6, 0, s * -0.4));
				RegenerateOrthonormalBasisUF(Vector3.Right * d);
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
				var needToAvoid:Boolean = avoid != Vector3.Zero;

				// any obstacles to avoid?
				if (needToAvoid)
				{
					// slow down and turn to avoid the obstacles
					var targetSpeed:Number = ((curvedSteering && QQQoaJustScraping) ? MaxSpeedForCurvature() : 0);
					annoteMaxRelSpeed = targetSpeed / MaxSpeed;
					var avoidWeight:Number = 3 + (3 * RelativeSpeed()); // ad hoc
					steering = avoid * avoidWeight;
					steering += SteerForTargetSpeed(targetSpeed);
				}
				else
				{
					// otherwise speed up and...
					steering = SteerForTargetSpeed(MaxSpeedForCurvature());

					// wander for demo 1
					if (demoSelect == 1)
					{
						var wander:Vector3 = SteerForWander(elapsedTime);
						wander.Y = 0;
						var flat:Vector3 = wander;
						var weighted:Vector3 = Vector3Helpers.TruncateLength(flat, MaxForce) * 6;
						var a:Vector3 = Position + new Vector3(0, 0.2, 0);
						annotation.Line(a, a + (weighted * 0.3), Color.White);
						steering += weighted;
					}

					// follow the path in demo 2
					if (demoSelect == 2)
					{
						var pf:Vector3 = SteerToFollowPath(pathFollowDirection, LookAheadTimePF(), path);
						if (pf != Vector3.Zero)
						{
							// steer to remain on path
							if (Vector3.Dot(pf, Forward) < 0)
								steering = pf;
							else
								steering = pf + steering;
						}
						else
						{
							// path aligment: when neither obstacle avoidance nor
							// path following is required, align with path segment
							var pathHeading:Vector3 = path.TangentAt(Position, pathFollowDirection);
							{
								var b = (Position + (Up * 0.2) + (Forward * halfLength * 1.4));
								var l:Number = 2;
								annotation.Line(b, b + (Forward * l), Color.Cyan);
								annotation.Line(b, b + (pathHeading * l), Color.Cyan);
							}
							steering += (SteerTowardHeading(pathHeading) *
										 (path.NearWaypoint(Position) ?
										  0.5 : 0.1));
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
				if (circles && !stuck) stuckCycleCount++;
				if (circles) stuck = true;
				annotation.CircleOrDisk(0.5, Up, SmoothedPosition, Color.White, 12, circles, false);
			}

			// annotation
			PerFrameAnnotation();
			trail.Record(currentTime, Position);
		}

		public function AdjustVehicleRadiusForSpeed():void
		{
			var minRadius:Number = Number(Math.Sqrt(Utilities.Square(halfWidth) + Utilities.Square(halfLength)));
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
				if (!IsBodyInsidePath()) pathFollowOffTime += elapsedTime;
			}
		}

		public function HintForObstacleAvoidance():Vector3
		{
			// used only when path following, return zero ("no hint") otherwise
			if (demoSelect != 2) return Vector3.Zero;

			// are we heading roughly parallel to the current path segment?
			var p:Vector3 = Position;
			var pathHeading:Vector3 = path.TangentAt(p, pathFollowDirection);
			if (Vector3.Dot(pathHeading, Forward) < 0.8)
			{
				// if not, the "hint" is to turn to align with path heading
				var s:Vector3 = Side * halfWidth;
				var f:Number = halfLength * 2;
				annotation.Line(p + s, p + s + (Forward * f), Color.Black);
				annotation.Line(p - s, p - s + (Forward * f), Color.Black);
				annotation.Line(p, p + (pathHeading * 5), Color.Magenta);
				return pathHeading;
			}
			else
			{
				// when there is a valid nearest obstacle position
				var obstacle:Vector3 = qqqLastNearestObstacle;
				var o:Vector3 = obstacle + (Up * 0.1);
				if (obstacle != Vector3.Zero)
				{
					// get offset, distance from obstacle to its image on path
					var outside:Number;
					var onPath:Vector3 = path.MapPointToPath(obstacle, outside);
					var offset:Vector3 = onPath - obstacle;
					var offsetDistance:Number = offset.Length();

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
							var obstacleDistance:Number = (obstacle - p).Length();
							var range:Number = Speed * LookAheadTimeOA();
							var farThreshold:Number = range * 0.8;
							var usableHint:Boolean = obstacleDistance > farThreshold;
							if (usableHint)
							{
								var temp:Vector3 = offset;
								temp.Normalize();
								var q:Vector3= p + (temp * 5);
								annotation.Line(p, q, Color.Magenta);
								annotation.CircleOrDisk(0.4, Up, o, Color.White, 12, false, false);
								return offset;
							}
						}
					}
					annotation.CircleOrDisk(0.4, Up, o, Color.Black, 12, false, false);
				}
			}
			// otherwise, no hint
			return Vector3.Zero;
		}

		// like steerToAvoidObstacles, but based on a BinaryTerrainMap indicating
		// the possitions of impassible regions
		//
		public function SteerToAvoidObstaclesOnMap(minTimeToCollision:Number, map:TerrainMap):Vector3
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
			var step:Vector3 = Forward * spacing;
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

			var hintGiven:Boolean = steerHint != Vector3.Zero;
			if (hintGiven && !dtZero)
				hintGivenCount++;
			if (hintGiven)
				annotation.CircleOrDisk(halfWidth * 0.9, Up, Position + (Up * 0.2), Color.White, 12, false, false);

			// QQQ temporary global QQQoaJustScraping
			QQQoaJustScraping = true;

			var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
			var localCenterOfCurvature:Vector3 = Side * signedRadius;
			var center:Vector3 = Position + localCenterOfCurvature;
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
					var fooz:Vector3 = Position - center;
					var booz:Vector3 = Vector3Helpers.RotateAboutGlobalY(fooz, sign * q);
					annotation.Line(center, center + fooz, Color.Red);
					annotation.Line(center, center + booz, Color.Red);
				}
			}

			// assert loops will terminate
			System.Diagnostics.Debug.Assert(spacing > 0);

			// scan corridor straight ahead of vehicle,
			// keep track of nearest obstacle on left and right sides
			while (s < maxSide)
			{
				sOffset = Side * s;
				s += spacing;
				var lOffset:Vector3 = fOffset + sOffset;
				var rOffset:Vector3 = fOffset - sOffset;

				var lObsPos:Vector3= Vector3.Zero, rObsPos = Vector3.Zero;

				var L:int = (curvedSteering ?
							   int(ScanObstacleMap(lOffset,
													   center,
													   arcAngle,
													   maxSamples,
													   0,
													   Color.Yellow,
													   Color.Red,
													  lObsPos)
									  / spacing) :
							   map.ScanXZray(lOffset, step, maxSamples));
				var R:int = (curvedSteering ?
							   int(ScanObstacleMap(rOffset,
														center,
													   arcAngle,
													   maxSamples,
													   0,
													   Color.Yellow,
													   Color.Red,
													   rObsPos)
									  / spacing):
							   map.ScanXZray(rOffset, step, maxSamples));

				if ((L > 0) && (L < nearestL))
				{
					nearestL = L;
					if (L < nearestR) nearestO = ((curvedSteering) ?
												  lObsPos :
												  lOffset + (step * Number(L)));
				}
				if ((R > 0) && (R < nearestR))
				{
					nearestR = R;
					if (R < nearestL) nearestO = ((curvedSteering) ?
												  rObsPos :
												  rOffset + (step * Number(R)));
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
					if (!outermost && eitherSide) QQQoaJustScraping = false;
				}
			}
			qqqLastNearestObstacle = nearestO;

			// scan "wings"
			{
				var wingScans:int = 4;
				// see duplicated code at: QQQ draw sensing "wings"
				// QQQ should be a parameter of this method
				var wingWidth:Vector3 = Side * WingSlope() * maxForward;

				var beforeColor:Color = new Color(int(255.0 * 0.75), int(255.0 * 0.9), int(255.0 * 0.0));  // for annotation
				var afterColor:Color = new Color(int(255.0 * 0.9), int(255.0 * 0.5), int(255.0 * 0.0));  // for annotation

				for (var i:int = 1; i <= wingScans; i++)
				{
					var fraction:Number = Number(i) / Number(wingScans);
					var endside:Vector3 = sOffset + (wingWidth * fraction);
					var corridorFront:Vector3 = Forward * maxForward;

					// "loop" from -1 to 1
					for (var j:int = -1; j < 2; j += 2)
					{
						var k:Number = Number(j); // prevent VC7.1 warning
						var start:Vector3 = fOffset + (sOffset * k);
						var end:Vector3 = fOffset + corridorFront + (endside * k);
						var ray:Vector3 = end - start;
						var rayLength:Number = ray.Length();
						var step2:Vector3 = ray * spacing / rayLength;
						var raySamples:int = int(rayLength / spacing);
						var endRadius:Number =
							WingSlope() * maxForward * fraction *
							(signedRadius < 0 ? 1 : -1) * (j == 1 ? 1 : -1);
						var ignore:Vector3;
						var scan:int = (curvedSteering ?
										  int((ScanObstacleMap(start,
																  center,
																  arcAngle,
																  raySamples,
																  endRadius,
																  beforeColor,
																  afterColor,
																 ignore)
												 / spacing)) :
										  map.ScanXZray(start, step2, raySamples));

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
					return -Forward;
			}

			// if the nearest obstacle is way out there, take hint if any
			//      if (hintGiven && (Math.Min (nearestL, nearestR) > (maxSamples * 0.8f)))
			if (hintGiven && (Math.min(Number(nearestL), Number(nearestR)) > (maxSamples * 0.8)))
			{
				AnnotationNoteOAClauseName("nearest obstacle is way out there");
				AnnotationHintWasTaken();
				if (Vector3.Dot(steerHint, Side) > 0)
					return Side;
				else
					return -Side;
			}

			// QQQ experiment 3-9-04
			//
			// since there are obstacles ahead, if we are already near
			// maximum curvature, we MUST turn in opposite direction
			//
			// are we turning more sharply than the minimum turning radius?
			// (code from adjustSteeringForMinimumTurningRadius)
			var maxCurvature:Number = 1 / (MinimumTurningRadius() * 1.2);
			if (Math.Abs(Curvature) > maxCurvature)
			{
				var blue:Color = new Color(0, 0, int(255.0 * 0.8));
				AnnotationNoteOAClauseName("min turn radius");
				annotation.CircleOrDisk(MinimumTurningRadius() * 1.2, Up,
										center, blue, 40, false, false);
				return Side * sign;
			}

			// if either side is obstacle-free, turn in that direction
			if (obstacleFreeL || obstacleFreeR)
				AnnotationNoteOAClauseName("obstacle-free side");

			if (obstacleFreeL) return Side;
			if (obstacleFreeR) return -Side;

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
					if (Vector3.Dot(steerHint, Side) > 0)
						return Side;
					else
						return -Side;
				}
				else
				{
					// otherwise steer toward the less cluttered side
					if (nearestL > nearestR)
						return Side;
					else
						return -Side;
				}
			}

			// if the two wings are about equally clear and a steering hint is
			// provided, use it
			var equallyClear:Boolean = Math.abs(nearestWL - nearestWR) < 2; // within 2
			if (equallyClear && hintGiven)
			{
				AnnotationNoteOAClauseName("equallyClear");
				AnnotationHintWasTaken();
				if (Vector3.Dot(steerHint, Side) > 0) return Side; else return -Side;
			}

			// turn towards the side whose "wing" region is less cluttered
			// (the wing whose nearest obstacle is furthest away)
			AnnotationNoteOAClauseName("wing less cluttered");
			if (nearestWL > nearestWR) return Side; else return -Side;
		}

		// QQQ reconsider calling sequence
		// called when steerToAvoidObstaclesOnMap decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function AnnotateAvoidObstaclesOnMap(scanOrigin:Vector3, scanIndex:int, scanStep:Vector3):void
		{
			if (scanIndex > 0)
			{
				var hit:Vector3 = scanOrigin + (scanStep * Number(scanIndex));
				annotation.Line(scanOrigin, hit, new Color(int(255.0 * 0.7), int(255.0 * 0.3 ), int(255.0 * 0.3)));
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
			if (!dtZero) hintTakenCount++;

			var r:Number = halfWidth * 0.9;
			var ff :Vector3= Forward * r;
			var ss:Vector3= Side * r;
			var pp:Vector3 = Position + (Up * 0.2);
			annotation.Line(pp + ff + ss, pp - ff + ss, Color.White);
			annotation.Line(pp - ff - ss, pp - ff + ss, Color.White);
			annotation.Line(pp - ff - ss, pp + ff - ss, Color.White);
			annotation.Line(pp + ff + ss, pp + ff - ss, Color.White);

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
		public function ScanObstacleMap(start:Vector3, center:Vector3, arcAngle:Number,segments:int, endRadiusChange:Number, beforeColor:Color, afterColor:Color, returnObstaclePosition:Vector3):Number
		{
			// "spoke" is initially the vector from center to start,
			// which is then rotated step by step around center
			var  spoke:Vector3 = start - center;
			// determine the angular step per segment
			var step:Number = arcAngle / segments;
			// store distance to, and position of first obstacle
			var obstacleDistance:Number = 0;
			returnObstaclePosition = Vector3.Zero;
			// for spiral "ramps" of changing radius
			var startRadius:Number = (endRadiusChange == 0) ? 0 : spoke.Length();

			// traverse each segment along arc
			var sin:Number = 0, cos = 0;
			var oldPoint:Vector3 = start;
			var obstacleFound:Boolean = false;
			for (var i:int = 0; i < segments; i++)
			{
				// rotate "spoke" to next step around circle
				// (sin and cos values get filled in on first call)
				spoke = Vector3Helpers.RotateAboutGlobalY(spoke, step, sin,cos);

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
				var newPoint:Vector3 = center + (spoke * adjust);

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
					var offset:Vector3 = newPoint - oldPoint;
					var d2:Number = offset.Length() * 2;

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
			return obstacleDistance;
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
			var step:Vector3 = Forward * spacing;
			var s:Number = curvedSteering ? (spacing / 4) : (spacing / 2);

			var signedRadius:Number = 1 / NonZeroCurvatureQQQ();
			var localCenterOfCurvature:Vector3 = Side * signedRadius;
			var center:Vector3 = Position + localCenterOfCurvature;
			var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
			var arcRadius:Number = signedRadius * -sign;
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * arcRadius;
			var qqqLift:Vector3 = new Vector3(0, 0.2, 0);
			var ignore:Vector3;

			// scan region ahead of vehicle
			while (s < maxSide)
			{
				var sOffset:Vector3 = Side * s;
				var lOffset:Vector3 = Position + sOffset;
				var rOffset:Vector3 = Position - sOffset;
				var bevel:Number = 0.3;
				var fraction:Number = s / maxSide;
				var scanDist:Number = (halfLength +
										Utilities.Interpolate(fraction,
													 maxForward,
													 maxForward * bevel));
				var angle:Number = (scanDist * twoPi * sign) / circumference;
				var samples:int = int(scanDist / spacing);
				var L:int = (curvedSteering ?
							   int((ScanObstacleMap(lOffset + qqqLift,
													   center,
													   angle,
													   samples,
													   0,
													   Color.Magenta,
													   Color.Cyan,
													   ignore)
									  / spacing)) :
							   map.ScanXZray(lOffset, step, samples));
				var R:int = (curvedSteering ?
							   int((ScanObstacleMap(rOffset + qqqLift,
													   center,
													   angle,
													   samples,
													   0,
													   Color.Magenta,
													   Color.Cyan,
													   ignore)
									  / spacing)) :
							   map.ScanXZray(rOffset, step, samples));

				returnFlag = returnFlag || (L > 0);
				returnFlag = returnFlag || (R > 0);

				// annotation
				if (!curvedSteering)
				{
					var d:Vector3 = step * Number(samples);
					annotation.Line(lOffset, lOffset + d, Color.White);
					annotation.Line(rOffset, rOffset + d, Color.White);
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
				var localCenterOfCurvature:Vector3 = Side * signedRadius;
				var center:Vector3 = Position + localCenterOfCurvature;
				var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
				var arcRadius:Number = signedRadius * -sign;
				var twoPi:Number = 2 * Number(Math.PI);
				var circumference:Number = twoPi * arcRadius;
				var rawLength:Number = Speed * predictionTime * sign;
				var arcLength:Number = ArcLengthLimit(rawLength, circumference * 0.25);
				var arcAngle:Number = twoPi * arcLength / circumference;

				var spoke:Vector3 = Position - center;
				var newSpoke:Vector3 = Vector3Helpers.RotateAboutGlobalY(spoke, arcAngle);
				var prediction:Vector3 = newSpoke + center;

				// QQQ unify with annotatePathFollowing
				var futurePositionColor:Color = new Color(int(255.0 * 0.5), int(255.0 * 0.5), int(255.0 * 0.6));
				AnnotationXZArc(Position, center, arcLength, 20, futurePositionColor);
				return prediction;
			}
			else
			{
				return Position + (Velocity * predictionTime);
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
		public function SteerToFollowPath(direction:int, predictionTime:Number, path:GCRoute):Vector3
		{
			if (curvedSteering)
				return SteerToFollowPathCurve(direction, predictionTime, path);
			else
				return SteerToFollowPathLinear(direction, predictionTime, path);
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
			var pathHeading:Vector3 = path.TangentAt(Position) * Number(direction);
			var correctDirection:Boolean = Vector3.Dot(pathHeading, Forward) > 0;

			// find the point on the path nearest the predicted future position
			// XXX need to improve calling sequence, maybe change to return a
			// XXX special path-defined object which includes two Vector3s and a 
			// XXX bool (onPath,tangent (ignored), withinPath)
			var futureOutside:Number;
			var onPath:Vector3 = path.MapPointToPath(futurePosition, futureOutside);

			// determine if we are currently inside the path tube
			var nowOutside:Number;
			var nowOnPath:Vector3 = path.MapPointToPath(Position,  nowOutside);

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
				if (nowOutside > 0) return SteerForSeek(nowOnPath);

				// steering to seek target on path
				var seek:Vector3 = Vector3Helpers.TruncateLength(SteerForSeek(target), MaxForce);

				// return that seek steering -- except when we are heading off
				// the path (currently on path and future position is off path)
				// in which case we put on the brakes.
				if ((nowOutside < 0) && (futureOutside > 0))
					return (Vector3Helpers.PerpendicularComponent(seek, Forward) - (Forward * MaxForce));
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
			var onPath:Vector3 = path.MapPointToPath(futurePosition,futureOutside);
			var pathHeading:Vector3 = path.TangentAt(onPath, direction);
			var rawBraking:Vector3 = Forward * MaxForce * -1;
			var braking:Vector3 = ((futureOutside < 0) ? Vector3.Zero : rawBraking);
			//qqq experimental wrong-way-fixer
			var nowOutside:Number;
			var nowTangent:Vector3 = Vector3.Zero;
			var p:Vector3 = Position;
			var nowOnPath:Vector3 = path.MapPointToPath(p, nowTangent, nowOutside);
			nowTangent *= Number(direction);
			var alignedness:Number = Vector3.Dot(nowTangent, Forward);

			// facing the wrong way?
			if (alignedness < 0)
			{
				annotation.Line(p, p + (nowTangent * 10), Color.Cyan);

				// if nearly anti-parallel
				if (alignedness < -0.707)
				{
					var towardCenter:Vector3 = nowOnPath - p;
					var turn:Vector3 = (Vector3.Dot(towardCenter, Side) > 0 ?
									   Side * MaxForce :
									   Side * MaxForce * -1);
					return (turn + rawBraking);
				}
				else
				{
					return (Vector3Helpers.PerpendicularComponent(SteerTowardHeading(pathHeading), Forward) + braking);
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
				annotation.Line(futurePosition, futurePosition + pathHeading, Color.Red);
				AnnotatePathFollowing(futurePosition, onPath,
									   Position, futureOutside);

				// two cases, if entering a turn (a waypoint between path segments)
				if (path.NearWaypoint(onPath) && (futureOutside > 0))
				{
					// steer to align with next path segment
					annotation.Circle3D(0.5, futurePosition, Up, Color.Red, 8);
					return SteerTowardHeading(pathHeading) + braking;
				}
				else
				{
					// otherwise steer away from the side of the path we
					// are heading for
					var pathSide:Vector3 = LocalRotateForwardToSide(pathHeading);
					var towardFP:Vector3 = futurePosition - onPath;
					var whichSide:Number = (Vector3.Dot(pathSide, towardFP) < 0) ? 1.0 : -1.0;
					return (Side * MaxForce * whichSide) + braking;
				}
			}
		}

		public function PerFrameAnnotation():void
		{
			var p:Vector3 = Position;

			// draw the circular collision boundary
			annotation.CircleOrDisk(Radius, Up, p, Color.Black, 32, false, false);

			// draw forward sensing corridor and wings ( for non-curved case)
			if (!curvedSteering)
			{
				var corLength:Number = Speed * LookAheadTimeOA();
				if (corLength > halfLength)
				{
					var corFront:Vector3 = Forward * corLength;
					var corBack:Vector3 = Vector3.Zero; // (was bbFront)
					var corSide:Vector3 = Side * Radius;
					var c1:Vector3 = p + corSide + corBack;
					var c2:Vector3 = p + corSide + corFront;
					var c3:Vector3 = p - corSide + corFront;
					var c4:Vector3 = p - corSide + corBack;
					var color:Color = ((annotateAvoid != Vector3.Zero) ? Color.Red : Color.Yellow);
					annotation.Line(c1, c2, color);
					annotation.Line(c2, c3, color);
					annotation.Line(c3, c4, color);

					// draw sensing "wings"
					var wingWidth:Vector3 = Side * WingSlope() * corLength;
					var wingTipL:Vector3 = c2 + wingWidth;
					var wingTipR:Vector3 = c3 - wingWidth;
					var wingColor:Color = Color.Orange;
					if (wingDrawFlagL) annotation.Line(c2, wingTipL, wingColor);
					if (wingDrawFlagL) annotation.Line(c1, wingTipL, wingColor);
					if (wingDrawFlagR) annotation.Line(c3, wingTipR, wingColor);
					if (wingDrawFlagR) annotation.Line(c4, wingTipR, wingColor);
				}
			}

			// annotate steering acceleration
			var above:Vector3 = Position + new Vector3(0, 0.2, 0);
			var accel:Vector3 = Acceleration * 5 / MaxForce;
			var aColor:Color = new Color(int(255.0 * 0.4), int(255.0 * 0.4), int(255.0 * 0.8));
			annotation.Line(above, above + accel, aColor);
		}

		// draw vehicle's body and annotation
		public function Draw():void
		{
			// for now: draw as a 2d bounding box on the ground
			var bodyColor:Color = Color.Black;
			if (stuck) bodyColor = Color.Yellow;
			if (!IsBodyInsidePath()) bodyColor = Color.Orange;
			if (collisionDetected) bodyColor = Color.Red;

			// draw vehicle's bounding box on gound plane (its "shadow")
			var p:Vector3 = Position;
			var bbSide:Vector3 = Side * halfWidth;
			var bbFront:Vector3 = Forward * halfLength;
			var bbHeight:Vector3 = new Vector3(0, 0.1, 0);
			Drawing.DrawQuadrangle(p - bbFront + bbSide + bbHeight,
							p + bbFront + bbSide + bbHeight,
							p + bbFront - bbSide + bbHeight,
							p - bbFront - bbSide + bbHeight,
							bodyColor);

			// annotate trail
			var darkGreen:Color = new Color(0, int(255.0 * 0.6), 0);
			trail.TrailColor = darkGreen;
			trail.TickColor = Color.Black;
			trail.Draw(Annotation.drawer);
		}

		// called when steerToFollowPath decides steering is required
		public function AnnotatePathFollowing(future:Vector3, onPath:Vector3, target:Vector3,outside:Number):void
		{
			var toTargetColor:Color = new Color(0, int(255.0 * 0.6), 0);
			var insidePathColor:Color = new Color(int(255.0 * 0.6), int(255.0 * 0.6), 0);
			var outsidePathColor:Color = new Color(0, 0, int(255.0 * 0.6));
			var futurePositionColo:Color = new Color(int(255.0 * 0.5), int(255.0 * 0.5), int(255.0 * 0.6));

			// draw line from our position to our predicted future position
			if (!curvedSteering)
				annotation.Line(Position, future, futurePositionColor);

			// draw line from our position to our steering target on the path
			annotation.Line(Position, target, toTargetColor);

			// draw a two-toned line between the future test point and its
			// projection onto the path, the change from dark to light color
			// indicates the boundary of the tube.

			var o:Number = outside + Radius + (curvedSteering ? 1.0 : 0.0);
			var boundaryOffset:Vector3 = (onPath - future);
			boundaryOffset.Normalize();
			boundaryOffset *= o;

			varonPathBoundary = future + boundaryOffset;
			annotation.Line(onPath, onPathBoundary, insidePathColor);
			annotation.Line(onPathBoundary, future, outsidePathColor);
		}

		public function DrawMap():void
		{
			var xs:Number = map.xSize / Number(map.resolution);
			var zs:Number = map.zSize / Number(map.resolution);
			var alongRow:Vector3 = new Vector3(xs, 0, 0);
			var nextRow:Vector3 = new Vector3(-map.xSize, 0, zs);
			var g:Vector3 = new Vector3((map.xSize - xs) / -2, 0, (map.zSize - zs) / -2);
			g += map.center;
			for (var j:int = 0; j < map.resolution; j++)
			{
				for (var i:int = 0; i < map.resolution; i++)
				{
					if (map.GetMapBit(i, j))
					{
						// spikes
						// Vector3 spikeTop (0, 5.0f, 0);
						// drawLine (g, g+spikeTop, Color.White);

						// squares
						var rockHeight:Number = 0;
						var v1:Vector3 = new Vector3(+xs / 2, rockHeight, +zs / 2);
						var v2:Vector3 = new Vector3(+xs / 2, rockHeight, -zs / 2);
						var v3:Vector3 = new Vector3(-xs / 2, rockHeight, -zs / 2);
						var v4:Vector3 = new Vector3(-xs / 2, rockHeight, +zs / 2);
						// Vector3 redRockColor (0.6f, 0.1f, 0.0f);
						var orangeRockColor:Color = new Color(int(255.0 * 0.5), int(255.0 * 0.2), int(255.0 * 0.0));
						Drawing.DrawQuadrangle(g + v1, g + v2, g + v3, g + v4, orangeRockColor);

						// pyramids
						// Vector3 top (0, xs/2, 0);
						// Vector3 redRockColor (0.6f, 0.1f, 0.0f);
						// Vector3 orangeRockColor (0.5f, 0.2f, 0.0f);
						// drawTriangle (g+v1, g+v2, g+top, redRockColor);
						// drawTriangle (g+v2, g+v3, g+top, orangeRockColor);
						// drawTriangle (g+v3, g+v4, g+top, redRockColor);
						// drawTriangle (g+v4, g+v1, g+top, orangeRockColor);
					}
					g += alongRow;
				}
				g += nextRow;
			}
		}

		// draw the GCRoute as a series of circles and "wide lines"
		// (QQQ this should probably be a method of Path (or a
		// closely-related utility function) in which case should pass
		// color in, certainly shouldn't be recomputing it each draw)
		public function DrawPath():void
		{
			var pathColor:Vector3 = new Vector3(0, 0.5, 0.5);
			var sandColor:Vector3 = new Vector3(0.8, 0.7, 0.5);
			var vColor:Vector3 = Utilities.Interpolate(0.1, sandColor, pathColor);
			var color:Color = new Color(vColor);

			var down:Vector3 = new Vector3(0, -0.1, 0);
			for (var i:int = 0; i < path.pointCount; i++)
			{
				var endPoint0:Vector3 = path.points[i] + down;
				if (i > 0)
				{
					var endPoint1:Vector3 = path.points[i - 1] + down;

					var legWidth:Number = path.radii[i];

					Drawing.DrawXZWideLine(endPoint0, endPoint1, color, legWidth * 2);
					Drawing.DrawLine(path.points[i], path.points[i - 1], new Color(pathColor));
					Drawing.DrawXZDisk(legWidth, endPoint0, color, 24);
					Drawing.DrawXZDisk(legWidth, endPoint1, color, 24);
				}
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
			var a:Vector3 = t - p;
			var b:Vector3 = s + v - p;
			var c:Vector3 = s - q;
			var d:Vector3 = s + q;
			var e:Vector3 = s - v + p;
			var f:Vector3 = p - w;
			var g:Vector3 = r - w;
			var h:Vector3 = -p - w;
			var i:Vector3 = u - p;

			// return Path object
			var pathPointCount:int = 9;
			var pathPoints:Array = new Array( a, b, c, d, e, f, g, h, i);
			var k:Number = 10.0;
			var pathRadii:Array = new Array( k, k, k, k, k, k, k, k, k );
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
				var px:Number = Position.X;
				var fx:Number = Forward.X;
				var ws :Number= worldSize * 0.51; // slightly past edge
				if (((fx > 0) && (px > ws)) || ((fx < 0) && (px < -ws)))
				{
					// bump counters
					lapsStarted++;
					lapsFinished++;

					var camOffsetBefore:Vector3 = Demo.Camera.Position - Position;

					// set position on other side of the map (set new X coordinate)
					SetPosition((((px < 0) ? 1 : -1) *
								  ((worldSize * 0.5) +
								   (Speed * LookAheadTimePF()))),
								 Position.Y,
								 Position.Z);

					// reset bookeeping to detect stuck cycles
					ResetStuckCycleDetection();

					// new camera position and aimpoint to compensate for teleport
					Demo.Camera.Target = Position;
					Demo.Camera.Position = (Position + camOffsetBefore);

					// make camera jump immediately to new position
					Demo.Camera.DoNotSmoothNextMove();

					// prevent long streaks due to teleportation 
					trail.Clear();

					return true;
				}
			}
			else
			{
				// for the non-path-following demos:
				// reset simulation if the vehicle drives through the fence
				if (Position.Length() > worldDiag) Reset();
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
			ResetSmoothedPosition(Position + (Forward * -80)); // qqq
		}

		// QQQ just a stop gap, not quite right
		// (say for example we were going around a circle with radius > 10)
		public function WeAreGoingInCircles():Boolean
		{
			var offset:Vector3 = SmoothedPosition - Position;
			return offset.Length() < 10;
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
				var bbSide:Vector3 = Side * halfWidth;
				var bbFront:Vector3 = Forward * halfLength;
				return (path.IsInsidePath(Position - bbFront + bbSide) &&
						path.IsInsidePath(Position + bbFront + bbSide) &&
						path.IsInsidePath(Position + bbFront - bbSide) &&
						path.IsInsidePath(Position - bbFront - bbSide));
			}
			return true;
		}

		public function ConvertAbsoluteToIncrementalSteering(absolute:Vector3, elapsedTime:Number):Vector3
		{
			var curved:Vector3 = ConvertLinearToCurvedSpaceGlobal(absolute);
			Utilities.BlendIntoAccumulator(elapsedTime * 8.0, curved, currentSteering);
			{
				// annotation
				var u:Vector3 = new Vector3(0, 0.5, 0);
				var p:Vector3 = Position;
				annotation.Line(p + u, p + u + absolute, Color.Red);
				annotation.Line(p + u, p + u + curved, Color.Yellow);
				annotation.Line(p + u * 2, p + u * 2 + currentSteering, Color.Green);
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
			var trimmedLinear:Vector3 = Vector3Helpers.TruncateLength(linear, MaxForce);

			// ---------- this block imported from steerToAvoidObstaclesOnMap
			var  signedRadius:Number = 1 / (NonZeroCurvatureQQQ() /*QQQ*/ * 1);
			var localCenterOfCurvature:Vector3 = Side * signedRadius;
			var center:Vector3 = Position + localCenterOfCurvature;
			var sign:Number = signedRadius < 0 ? 1.0 : -1.0;
			var arcLength:Number = Vector3.Dot(trimmedLinear, Forward);
			//
			var arcRadius:Number = signedRadius * -sign;
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * arcRadius;
			var arcAngle:Number = twoPi * arcLength / circumference;
			// ---------- this block imported from steerToAvoidObstaclesOnMap

			// ---------- this block imported from scanObstacleMap
			// vector from center of curvature to position of vehicle
			var initialSpoke:Vector3 = Position - center;
			// rotate by signed arc angle
			var spoke:Vector3 = Vector3Helpers.RotateAboutGlobalY(initialSpoke, arcAngle * sign);
			// ---------- this block imported from scanObstacleMap

			var fromCenter:Vector3 = -localCenterOfCurvature;
			fromCenter.Normalize();
			var dRadius:Number = Vector3.Dot(trimmedLinear, fromCenter);
			var radiusChangeFactor:Number = (dRadius + arcRadius) / arcRadius;
			var resultLocation:Vector3 = center + (spoke * radiusChangeFactor);
			{
				var center2:Vector3 = Position + localCenterOfCurvature;
				AnnotationXZArc(Position, center2, Speed * sign * -3, 20, Color.White);
			}
			// return the vector from vehicle position to the coimputed location
			// of the curved image of the original linear offset
			return resultLocation - Position;
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
				var thrust:Vector3 = Vector3Helpers.ParallelComponent(steering, Forward);
				var trimmed:Vector3 = Vector3Helpers.TruncateLength(thrust, MaxForce);
				var widenOut:Vector3 = Side * MaxForce * sign;
				{
					// annotation
					var localCenterOfCurvature:Vector3 = Side * signedRadius;
					var center:Vector3 = Position + localCenterOfCurvature;
					annotation.CircleOrDisk(MinimumTurningRadius(), Up,
											center, Color.Blue, 40, false, false);
				}
				return trimmed + widenOut;
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
				var relativeCurvature:Number = Number(Math.Sqrt(Utilities.Clip(absC / maxC, 0, 1)));

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
					var parallelness:Number = Vector3.Dot(pathHeading, Forward);

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
			var headingError:Vector3 = desiredGlobalHeading - Forward;
			headingError.Normalize();
			headingError *= MaxForce;

			return headingError;
		}

		// XXX this should eventually be in a library, make it a first
		// XXX class annotation queue, tie in with drawXZArc
		public function AnnotationXZArc(start:Vector3, center:Vector3, arcLength:Number, segments:int, color:Color):void
		{
			// "spoke" is initially the vector from center to start,
			// it is then rotated around its tail
			var spoke:Vector3 = start - center;

			// determine the angular step per segment
			var radius:Number= spoke.Length();
			var twoPi:Number = 2 * Number(Math.PI);
			var circumference:Number = twoPi * radius;
			var arcAngle:Number = twoPi * arcLength / circumference;
			var step:Number = arcAngle / segments;

			// draw each segment along arc
			var sin:Number = 0, cos = 0;
			for (var i:int = 0; i < segments; i++)
			{
				var old:Vector3 = spoke + center;

				// rotate point to next step around circle
				spoke = Vector3Helpers.RotateAboutGlobalY(spoke, step, sin, cos);

				annotation.Line(spoke + center, old, color);
			}
		}

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
		public static var savedNearestWR:Number = 0;
		public static var savedNearestR:Number = 0;
		public static var savedNearestL:Number = 0;
		public static var savedNearestWL:Number = 0;

		public var annoteMaxRelSpeed:Number;
		public var annoteMaxRelSpeedCurve:Number;
		public var annoteMaxRelSpeedPath:Number;

		// which of the three demo modes is selected
		public static var demoSelect:int = 2;

		// size of the world (the map actually)
		public static var worldSize:Number = 200;
		public static var worldDiag:Number = Number(Math.Sqrt(Utilities.Square(worldSize) / 2));
	}
}
