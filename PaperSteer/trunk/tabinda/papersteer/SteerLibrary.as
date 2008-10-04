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
	//FIXME: this class should not be abstract
	// was an abstract class
	public class SteerLibrary extends LocalSpace implements AbstractVehicle
	{
		// Mass (defaults to unity so acceleration=force)
		private var mass:Number;

		// size of bounding sphere, for obstacle avoidance, etc.
		private var radius:Number;

		// speed along Forward direction. Because local space is
		// velocity-aligned, velocity = Forward * Speed
		private var speed:Number;

		// the maximum steering force this vehicle can apply
		// (steering force is clipped to this magnitude)
		private var maxForce:Number;

		// the maximum speed this vehicle is allowed to move
		// (velocity is clipped to this magnitude)
		private var maxSpeed:Number;
		
		// The acceleration is smoothed
		private var acceleration:Vector3D;
		
		//HACK: This should not be... Find a way to access Game.Services
		public static var annotation:IAnnotationService = new Annotation();

		// Constructor: initializes state
		public function SteerLibrary()
		{
			// set inital state
			Reset();
		}

		// reset state
		public function Reset():void
		{
			// initial state of wander behavior
			WanderSide = 0;
			WanderUp = 0;

			// default to non-gaudyPursuitAnnotation
			GaudyPursuitAnnotation = false;
		}
		
		// get/set Mass
		public function get Mass ():Number
		{
			return mass;
		}
		public function set Mass (val:Number):void
		{
			mass=val;
		}

		// get velocity of vehicle
		public function get Velocity ():Vector3D
		{
			return Vector3D.ScalarMultiplication(speed,Forward);
		}
		
		// predict position of this vehicle at some time in the future
		// (assumes velocity remains constant)
		public  function PredictFuturePosition (predictionTime:Number):Vector3D
		{
			return Vector3D.VectorAddition(Position , Vector3D.ScalarMultiplication(predictionTime,Velocity));
		}

		// get/set speed of vehicle  (may be faster than taking mag of velocity)
		public function get Speed ():Number
		{
			return speed;
		}
		public  function set Speed (val:Number):void
		{
			speed=val;
		}
		
		public function get Acceleration():Vector3D
		{
			return acceleration;
		}

		// size of bounding sphere, for obstacle avoidance, etc.
		public function get Radius ():Number
		{
			return radius;
		}
		public  function set Radius (val:Number):void
		{
			radius=val;
		}

		// get/set maxForce
		public function get MaxForce ():Number
		{
			return maxForce;
		}
		public  function set MaxForce (val:Number):void
		{
			maxForce=val;
		}

		// get/set maxSpeed
		public  function get MaxSpeed ():Number
		{
			return maxSpeed;
		}
		public  function set MaxSpeed (val:Number):void
		{
			maxSpeed=val;
		}

		// -------------------------------------------------- steering behaviors

		// Wander behavior
		public var WanderSide:Number;
		public var WanderUp:Number;

        public function SteerForWander(dt:Number):Vector3D
		{
			// random walk WanderSide and WanderUp between -1 and +1
			var speed:Number = 12 * dt; // maybe this (12) should be an argument?
			WanderSide = Utilities.ScalarRandomWalk(WanderSide, speed, -1, +1);
			WanderUp = Utilities.ScalarRandomWalk(WanderUp, speed, -1, +1);

			// return a pure lateral steering vector: (+/-Side) + (+/-Up)
			return Vector3D.VectorAddition(Vector3D.ScalarMultiplication(WanderSide,this.Side) , Vector3D.ScalarMultiplication(WanderUp,this.Up));
		}

		// Seek behavior
        public function SteerForSeek(target:Vector3D):Vector3D
		{
            var desiredVelocity:Vector3D = Vector3D.VectorSubtraction(target, this.Position);
			return Vector3D.VectorSubtraction(desiredVelocity , this.Velocity);
		}

		// Flee behavior
        public function SteerForFlee(target:Vector3D):Vector3D
		{
            var desiredVelocity:Vector3D = Vector3D.VectorSubtraction(this.Position , target);
			return Vector3D.VectorSubtraction(desiredVelocity , this.Velocity);
		}

		// xxx proposed, experimental new seek/flee [cwr 9-16-02]
        public function xxxSteerForFlee(target:Vector3D):Vector3D
		{
			//  const Vector3 offset = position - target;
            var offset:Vector3D = Vector3D.VectorSubtraction(this.Position , target);
            var desiredVelocity:Vector3D = offset.TruncateLength(this.MaxSpeed); //xxxnew
			return Vector3D.VectorSubtraction(desiredVelocity , this.Velocity);
		}

        public function xxxSteerForSeek(target:Vector3D):Vector3D
		{
			//  const Vector3 offset = target - position;
            var offset:Vector3D = Vector3D.VectorSubtraction(target , this.Position);
            var desiredVelocity:Vector3D = offset.TruncateLength(this.MaxSpeed); //xxxnew
			return Vector3D.VectorSubtraction(desiredVelocity , this.Velocity);
		}

		// Path Following behaviors
        public function SteerToFollowPath(direction:int, predictionTime:Number, path:Pathway):Vector3D
		{
			// our goal will be offset from our path distance by this amount
			var pathDistanceOffset:Number = direction * predictionTime * this.Speed;

			// predict our future position
            var futurePosition:Vector3D = this.PredictFuturePosition(predictionTime);

			// measure distance along path of our current and predicted positions
			var nowPathDistance:Number = path.MapPointToPathDistance(this.Position);
			var futurePathDistance:Number = path.MapPointToPathDistance(futurePosition);

			// are we facing in the correction direction?
			var rightway:Boolean = ((pathDistanceOffset > 0) ?
								   (nowPathDistance < futurePathDistance) :
								   (nowPathDistance > futurePathDistance));

			// find the point on the path nearest the predicted future position
			// XXX need to improve calling sequence, maybe change to return a
			// XXX special path-defined object which includes two Vector3s and a 
			// XXX bool (onPath,tangent (ignored), withinPath)
            var tangent:Vector3D;
			var outside:Number;
            var onPath:Vector3D = path.MapPointToPath(futurePosition, tangent,outside);

			// no steering is required if (a) our future position is inside
			// the path tube and (b) we are facing in the correct direction
			if ((outside < 0) && rightway)
			{
				// all is well, return zero steering
				return Vector3D.Zero;
			}
			else
			{
				// otherwise we need to steer towards a target point obtained
				// by adding pathDistanceOffset to our current path position

				var targetPathDistance:Number = nowPathDistance + pathDistanceOffset;
                var target:Vector3D = path.MapPathDistanceToPoint(targetPathDistance);

				annotation.PathFollowing(futurePosition, onPath, target, outside);

				// return steering to seek target on path
				return SteerForSeek(target);
			}
		}

        public function SteerToStayOnPath(predictionTime:Number, path:Pathway):Vector3D
		{
			// predict our future position
            var futurePosition:Vector3D = this.PredictFuturePosition(predictionTime);

			// find the point on the path nearest the predicted future position
            var tangent:Vector3D;
			var outside:Number;
            var onPath:Vector3D = path.MapPointToPath(futurePosition, tangent, outside);

			if (outside < 0)
			{
				// our predicted future position was in the path,
				// return zero steering.
				return Vector3D.Zero;
			}
			else
			{
				// our predicted future position was outside the path, need to
				// steer towards it.  Use onPath projection of futurePosition
				// as seek target
				annotation.PathFollowing(futurePosition, onPath, onPath, outside);
				return SteerForSeek(onPath);
			}
		}

		// ------------------------------------------------------------------------
		// Obstacle Avoidance behavior
		//
		// Returns a steering force to avoid a given obstacle.  The purely
		// lateral steering force will turn our this towards a silhouette edge
		// of the obstacle.  Avoidance is required when (1) the obstacle
		// intersects the this's current path, (2) it is in front of the
		// this, and (3) is within minTimeToCollision seconds of travel at the
		// this's current velocity.  Returns a zero vector value (Vector3::zero)
		// when no avoidance is required.
        public function SteerToAvoidObstacle(minTimeToCollision:Number, obstacle:IObstacle):Vector3D
		{
            var avoidance:Vector3D = obstacle.SteerToAvoid(this, minTimeToCollision);

			// XXX more annotation modularity problems (assumes spherical obstacle)
			if (avoidance != Vector3D.Zero)
			{
				annotation.AvoidObstacle(minTimeToCollision * this.Speed);
			}
			return avoidance;
		}

		// avoids all obstacles in an ObstacleGroup
        public function SteerToAvoidObstacles(minTimeToCollision, obstacles:Array):Vector3D
			//where Obstacle : IObstacle
		{
            var avoidance:Vector3D = Vector3D.Zero;
			var nearest:PathIntersection = new PathIntersection();
			var next:PathIntersection = new PathIntersection();
			var minDistanceToCollision:Number = minTimeToCollision * this.Speed;

			next.intersect = false;
			nearest.intersect = false;

			// test all obstacles for intersection with my forward axis,
			// select the one whose point of intersection is nearest
			for each (var o:IObstacle in obstacles)
			{
				//FIXME: this should be a generic call on Obstacle, rather than this code which presumes the obstacle is spherical
				FindNextIntersectionWithSphere(o as SphericalObstacle, /*ref*/ next);

				if (nearest.intersect == false || (next.intersect != false && next.distance < nearest.distance))
					nearest = next;
			}

			// when a nearest intersection was found
			if ((nearest.intersect != false) && (nearest.distance < minDistanceToCollision))
			{
				// show the corridor that was checked for collisions
				annotation.AvoidObstacle(minDistanceToCollision);

				// compute avoidance steering force: take offset from obstacle to me,
				// take the component of that which is lateral (perpendicular to my
				// forward direction), set length to maxForce, add a bit of forward
				// component (in capture the flag, we never want to slow down)
                var offset:Vector3D = Vector3D.VectorSubtraction(this.Position , nearest.obstacle.Center);
                avoidance = offset.PerpendicularComponent(this.Forward);
				avoidance.fNormalize();
				avoidance = Vector3D.ScalarMultiplication(this.MaxForce,avoidance);
				avoidance = avoidance.UnaryVectorAddition(Vector3D.ScalarMultiplication(this.MaxForce * 0.75,this.Forward));
			}

			return avoidance;
		}

		// ------------------------------------------------------------------------
		// Unaligned collision avoidance behavior: avoid colliding with other
		// nearby vehicles moving in unconstrained directions.  Determine which
		// (if any) other other this we would collide with first, then steers
		// to avoid the site of that potential collision.  Returns a steering
		// force vector, which is zero length if there is no impending collision.
        public function SteerToAvoidNeighbors(minTimeToCollision:Number, others:Array):Vector3D
			//where TVehicle : IVehicle
		{
			// first priority is to prevent immediate interpenetration
            var separation:Vector3D = SteerToAvoidCloseNeighbors(0, others);
			if (separation != Vector3D.Zero) return separation;

			// otherwise, go on to consider potential future collisions
			var steer:Number = 0;
			var threat:IVehicle = null;

			// Time (in seconds) until the most immediate collision threat found
			// so far.  Initial value is a threshold: don't look more than this
			// many frames into the future.
			var minTime:Number = minTimeToCollision;

			// xxx solely for annotation
            var xxxThreatPositionAtNearestApproach:Vector3D = Vector3D.Zero;
            var xxxOurPositionAtNearestApproach:Vector3D = Vector3D.Zero;

			// for each of the other vehicles, determine which (if any)
			// pose the most immediate threat of collision.
			for each (var other:IVehicle in others)
			{
				if (other != this)/*this*///)
				{
					// avoid when future positions are this close (or less)
					var collisionDangerThreshold:Number = this.Radius * 2;

					// predicted time until nearest approach of "this" and "other"
					var time:Number = PredictNearestApproachTime(other);

					// If the time is in the future, sooner than any other
					// threatened collision...
					if ((time >= 0) && (time < minTime))
					{
						// if the two will be close enough to collide,
						// make a note of it
						if (ComputeNearestApproachPositions(other, time) < collisionDangerThreshold)
						{
							minTime = time;
							threat = other;
							xxxThreatPositionAtNearestApproach = hisPositionAtNearestApproach;
							xxxOurPositionAtNearestApproach = ourPositionAtNearestApproach;
						}
					}
				}
			}

			// if a potential collision was found, compute steering to avoid
			if (threat != null)
			{
				// parallel: +1, perpendicular: 0, anti-parallel: -1
                var parallelness:Number = this.Forward.DotProduct( threat.Forward);
				var angle:Number = 0.707;

				if (parallelness < -angle)
				{
					// anti-parallel "head on" paths:
					// steer away from future threat position
                    var offset:Vector3D = Vector3D.VectorSubtraction(xxxThreatPositionAtNearestApproach , this.Position);
                    var sideDot:Number = offset.DotProduct(this.Side);
					steer = (sideDot > 0) ? -1.0 : 1.0;
				}
				else
				{
					if (parallelness > angle)
					{
						// parallel paths: steer away from threat
						offset = Vector3D.VectorSubtraction(threat.Position , this.Position);
                        sideDot = offset.DotProduct(this.Side);
						steer = (sideDot > 0) ? -1.0 : 1.0;
					}
					else
					{
						// perpendicular paths: steer behind threat
						// (only the slower of the two does this)
						if (threat.Speed <= this.Speed)
						{
                            sideDot = this.Side.DotProduct(threat.Velocity);
							steer = (sideDot > 0) ? -1.0 : 1.0;
						}
					}
				}

				annotation.AvoidNeighbor(threat, steer, xxxOurPositionAtNearestApproach, xxxThreatPositionAtNearestApproach);
			}

			return Vector3D.ScalarMultiplication(steer,this.Side);
		}

		// Given two vehicles, based on their current positions and velocities,
		// determine the time until nearest approach
		public function PredictNearestApproachTime(other:IVehicle):Number
		{
			// imagine we are at the origin with no velocity,
			// compute the relative velocity of the other this
            var myVelocity:Vector3D = this.Velocity;
            var otherVelocity:Vector3D = other.Velocity;
            var relVelocity:Vector3D = Vector3D.VectorSubtraction(otherVelocity , myVelocity);
			var relSpeed:Number = relVelocity.Magnitude();

			// for parallel paths, the vehicles will always be at the same distance,
			// so return 0 (aka "now") since "there is no time like the present"
			if (relSpeed == 0) return 0;

			// Now consider the path of the other this in this relative
			// space, a line defined by the relative position and velocity.
			// The distance from the origin (our this) to that line is
			// the nearest approach.

			// Take the unit tangent along the other this's path
            var relTangent:Vector3D = relVelocity.UnaryScalarDivision(relSpeed);

			// find distance from its path to origin (compute offset from
			// other to us, find length of projection onto path)
            var relPosition:Vector3D = Vector3D.VectorSubtraction(this.Position , other.Position);
            var projection:Number = relTangent.DotProduct(relPosition);

			return projection / relSpeed;
		}

		// Given the time until nearest approach (predictNearestApproachTime)
		// determine position of each this at that time, and the distance
		// between them
		public function ComputeNearestApproachPositions(other:IVehicle,time:Number):Number
		{
            var myTravel:Vector3D = Vector3D.ScalarMultiplication(this.Speed * time,this.Forward);
            var otherTravel:Vector3D = Vector3D.ScalarMultiplication(other.Speed * time,other.Forward);

            var myFinal:Vector3D = Vector3D.VectorAddition(this.Position , myTravel);
            var otherFinal:Vector3D = Vector3D.VectorAddition(other.Position , otherTravel);

			// xxx for annotation
			ourPositionAtNearestApproach = myFinal;
			hisPositionAtNearestApproach = otherFinal;

			return Vector3D.Distance(myFinal, otherFinal);
		}

		/// XXX globals only for the sake of graphical annotation
        var hisPositionAtNearestApproach:Vector3D;
        var ourPositionAtNearestApproach:Vector3D;

		// ------------------------------------------------------------------------
		// avoidance of "close neighbors" -- used only by steerToAvoidNeighbors
		//
		// XXX  Does a hard steer away from any other agent who comes withing a
		// XXX  critical distance.  Ideally this should be replaced with a call
		// XXX  to steerForSeparation.
        public function SteerToAvoidCloseNeighbors(minSeparationDistance:Number, others:Array):Vector3D
			//where TVehicle : IVehicle
		{
			// for each of the other vehicles...
			for each (var other:IVehicle in others)
			{
				if (other != this)/*this*///)
				{
					var sumOfRadii:Number = this.Radius + other.Radius;
					var minCenterToCenter :Number= minSeparationDistance + sumOfRadii;
					var offset:Vector3D = Vector3D.VectorSubtraction(other.Position , this.Position);
					var currentDistance:Number = offset.Magnitude();

					if (currentDistance < minCenterToCenter)
					{
						annotation.AvoidCloseNeighbor(other, minSeparationDistance);
                        offset.PerpendicularComponent(this.Forward);
						offset.Negate();
						return offset;
					}
				}
			}

			// otherwise return zero
			return Vector3D.Zero;
		}

		// ------------------------------------------------------------------------
		// used by boid behaviors
		public function IsInBoidNeighborhood(other:IVehicle, minDistance:Number, maxDistance:Number, cosMaxAngle:Number):Boolean
		{
			if (other == this)
			{
				return false;
			}
			else
			{
                var offset:Vector3D = Vector3D.VectorSubtraction(other.Position , this.Position);
				var distanceSquared:Number = offset.SquaredMagnitude();

				// definitely in neighborhood if inside minDistance sphere
				if (distanceSquared < (minDistance * minDistance))
				{
					return true;
				}
				else
				{
					// definitely not in neighborhood if outside maxDistance sphere
					if (distanceSquared > (maxDistance * maxDistance))
					{
						return false;
					}
					else
					{
						// otherwise, test angular offset from forward axis
                        var unitOffset:Vector3D = offset.UnaryScalarDivision(Number(Math.sqrt(distanceSquared)));
                        var forwardness:Number = this.Forward.DotProduct(unitOffset);
						return forwardness > cosMaxAngle;
					}
				}
			}
		}

		// ------------------------------------------------------------------------
		// Separation behavior -- determines the direction away from nearby boids
        public function SteerForSeparation(maxDistance:Number, cosMaxAngle:Number, flock:Array):Vector3D
		{
			// steering accumulator and count of neighbors, both initially zero
            var steering:Vector3D = Vector3D.Zero;
			var neighbors:int = 0;

			// for each of the other vehicles...
			for (var i:int = 0; i < flock.length; i++)
			{
				var other:IVehicle = flock[i];
				if (IsInBoidNeighborhood(other, this.Radius * 3, maxDistance, cosMaxAngle))
				{
					// add in steering contribution
					// (opposite of the offset direction, divided once by distance
					// to normalize, divided another time to get 1/d falloff)
					var offset:Vector3D = Vector3D.VectorSubtraction(other.Position , this.Position);
                    var distanceSquared:Number = offset.DotProduct(offset);
					steering = Vector3D.VectorAddition(steering,(offset.UnaryScalarDivision(-distanceSquared)));

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, then normalize to pure direction
            if (neighbors > 0)
            {
                steering = (steering.UnaryScalarDivision(Number(neighbors)));
                steering.fNormalize();
            }

			return steering;
		}

		// ------------------------------------------------------------------------
		// Alignment behavior
        public function SteerForAlignment(maxDistance:Number, cosMaxAngle:Number, flock:Array):Vector3D
		{
			// steering accumulator and count of neighbors, both initially zero
			var steering:Vector3D = Vector3D.Zero;
			var neighbors:int = 0;

			// for each of the other vehicles...
			for (var i:int = 0; i < flock.length; i++)
			{
				var other:IVehicle = flock[i];
				if (IsInBoidNeighborhood(other, this.Radius * 3, maxDistance, cosMaxAngle))
				{
					// accumulate sum of neighbor's heading
					steering = Vector3D.VectorAddition(steering,other.Forward);

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, subtract off current heading to get error-
			// correcting direction, then normalize to pure direction
            if (neighbors > 0)
            {
                steering = Vector3D.VectorSubtraction(steering.UnaryScalarDivision(Number(neighbors)) , this.Forward);
                steering.fNormalize();
            }

			return steering;
		}

		// ------------------------------------------------------------------------
		// Cohesion behavior
        public function SteerForCohesion(maxDistance:Number, cosMaxAngle:Number, flock:Array):Vector3D
		{
			// steering accumulator and count of neighbors, both initially zero
			var steering:Vector3D = Vector3D.Zero;
			var neighbors:int = 0;

			// for each of the other vehicles...
			for (var i:int = 0; i < flock.length; i++)
			{
				var other:IVehicle = flock[i];
				if (IsInBoidNeighborhood(other, this.Radius * 3, maxDistance, cosMaxAngle))
				{
					// accumulate sum of neighbor's positions
					steering = Vector3D.VectorAddition(steering,other.Position);

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, subtract off current position to get error-
			// correcting direction, then normalize to pure direction
			if (neighbors > 0)
            {
				steering = Vector3D.VectorSubtraction(steering.UnaryScalarDivision(Number(neighbors)) , this.Position);
                steering.fNormalize();
            }

			return steering;
		}

		// ------------------------------------------------------------------------
		// pursuit of another this (& version with ceiling on prediction time)
        public function SteerForPursuit(quarry:IVehicle):Vector3D
		{
			return SteerForPursuit2(quarry, Number.MAX_VALUE);
		}

        public function SteerForPursuit2(quarry:IVehicle,maxPredictionTime:Number):Vector3D
		{
			// offset from this to quarry, that distance, unit vector toward quarry
            var offset:Vector3D = Vector3D.VectorSubtraction(quarry.Position , this.Position);
			var distance:Number = offset.Magnitude();
            var unitOffset:Vector3D = offset.UnaryScalarDivision(distance);

			// how parallel are the paths of "this" and the quarry
			// (1 means parallel, 0 is pependicular, -1 is anti-parallel)
            var parallelness:Number = this.Forward.DotProduct(quarry.Forward);

			// how "forward" is the direction to the quarry
			// (1 means dead ahead, 0 is directly to the side, -1 is straight back)
            var forwardness:Number = this.Forward.DotProduct(unitOffset);

			var directTravelTime:Number = distance / this.Speed;
			var f:int = Utilities.IntervalComparison(forwardness, -0.707, 0.707);
			var p:int = Utilities.IntervalComparison(parallelness, -0.707, 0.707);

			var timeFactor:Number = 0;   // to be filled in below
			var color:uint = 0x000000;// Colors.Black; // to be filled in below (xxx just for debugging)

			// Break the pursuit into nine cases, the cross product of the
			// quarry being [ahead, aside, or behind] us and heading
			// [parallel, perpendicular, or anti-parallel] to us.
			switch (f)
			{
			case +1:
				switch (p)
				{
				case +1:          // ahead, parallel
					timeFactor = 4;
					color = 0x000000;// Colors.Black;
					break;
				case 0:           // ahead, perpendicular
					timeFactor = 1.8;
					color = 0x999999;// Colors.Gray;
					break;
				case -1:          // ahead, anti-parallel
					timeFactor = 0.85;
					color = 0xFFFFFF;// Colors.White;
					break;
				}
				break;
			case 0:
				switch (p)
				{
				case +1:          // aside, parallel
					timeFactor = 1;
					color = 0xFF0000;// Colors.Red;
					break;
				case 0:           // aside, perpendicular
					timeFactor = 0.8;
					color = 0xFFFF00;// Colors.Yellow;
					break;
				case -1:          // aside, anti-parallel
					timeFactor = 4;
					color = 0x00FF00;// Colors.Green;
					break;
				}
				break;
			case -1:
				switch (p)
				{
				case +1:          // behind, parallel
					timeFactor = 0.5;
					color = 0x33CCCC;// Colors.Cyan;
					break;
				case 0:           // behind, perpendicular
					timeFactor = 2;
					color = 0x0000FF;// Colors.Blue;
					break;
				case -1:          // behind, anti-parallel
					timeFactor = 2;
					color = 0x0000F0;// Colors.Magenta;
					break;
				}
				break;
			}

			// estimated time until intercept of quarry
			var et:Number = directTravelTime * timeFactor;

			// xxx experiment, if kept, this limit should be an argument
			var etl:Number = (et > maxPredictionTime) ? maxPredictionTime : et;

			// estimated position of quarry at intercept
			var target:Vector3D = quarry.PredictFuturePosition(etl);

			// annotation
			annotation.Line(this.Position, target, GaudyPursuitAnnotation ? color : 0x666666);

			return SteerForSeek(target);
		}

		// for annotation
		public var GaudyPursuitAnnotation:Boolean;

		// ------------------------------------------------------------------------
		// evasion of another this
        public function SteerForEvasion(menace:IVehicle, maxPredictionTime:Number):Vector3D
		{
			// offset from this to menace, that distance, unit vector toward menace
			var offset:Vector3D = Vector3D.VectorSubtraction(menace.Position , this.Position);
			var distance:Number = offset.Magnitude();

			var roughTime:Number = distance / menace.Speed;
			var predictionTime:Number = ((roughTime > maxPredictionTime) ? maxPredictionTime : roughTime);

			var target:Vector3D = menace.PredictFuturePosition(predictionTime);

			return SteerForFlee(target);
		}

		// ------------------------------------------------------------------------
		// tries to maintain a given speed, returns a maxForce-clipped steering
		// force along the forward/backward axis
        public function SteerForTargetSpeed(targetSpeed:Number):Vector3D
		{
			var mf:Number = this.MaxForce;
			var speedError:Number = targetSpeed - this.Speed;
			return Vector3D.ScalarMultiplication(Utilities.Clip(speedError, -mf, +mf),this.Forward);
		}

		// ----------------------------------------------------------- utilities
		// XXX these belong somewhere besides the steering library
		// XXX above AbstractVehicle, below SimpleVehicle
		// XXX ("utility this"?)

		// xxx cwr experimental 9-9-02 -- names OK?
        public function IsAhead(target:Vector3D):Boolean
		{
			return IsAhead2(target, 0.707);
		}
        public function IsAside(target:Vector3D):Boolean
		{
			return IsAside2(target, 0.707);
		}
        public function IsBehind(target:Vector3D):Boolean
		{
			return IsBehind2(target, -0.707);
		}

        public function IsAhead2(target:Vector3D, cosThreshold:Number):Boolean
		{
			var targetDirection:Vector3D = Vector3D.VectorSubtraction(target, this.Position);
            targetDirection.fNormalize();
            return this.Forward.DotProduct(targetDirection) > cosThreshold;
		}
        public function IsAside2(target:Vector3D, cosThreshold:Number):Boolean
		{
			var targetDirection:Vector3D = Vector3D.VectorSubtraction(target , this.Position);
            targetDirection.fNormalize();
            var dp:Number = this.Forward.DotProduct(targetDirection);
			return (dp < cosThreshold) && (dp > -cosThreshold);
		}
        public function IsBehind2(target:Vector3D, cosThreshold:Number):Boolean
		{
			var targetDirection:Vector3D = Vector3D.VectorSubtraction(target , this.Position);
            targetDirection.fNormalize();
            return this.Forward.DotProduct(targetDirection) < cosThreshold;
		}

		// xxx experiment cwr 9-6-02
		protected function FindNextIntersectionWithSphere(obs:SphericalObstacle ,intersection:PathIntersection ):void
		{
			// This routine is based on the Paul Bourke's derivation in:
			//   Intersection of a Line and a Sphere (or circle)
			//   http://www.swin.edu.au/astronomy/pbourke/geometry/sphereline/

			var b:Number, c:Number, d:Number, p:Number, q:Number, s:Number;
			var lc:Vector3D;

			// initialize pathIntersection object
			intersection.intersect = false;
			intersection.obstacle = obs;

			// find "local center" (lc) of sphere in boid's coordinate space
			lc = this.LocalizePosition(obs.Center);

			// computer line-sphere intersection parameters
			b = -2 * lc.z;
			c = Utilities.Square(lc.x) + Utilities.Square(lc.y) + Utilities.Square(lc.z) -
				Utilities.Square(obs.Radius + this.Radius);
			d = (b * b) - (4 * c);

			// when the path does not intersect the sphere
			if (d < 0) return;

			// otherwise, the path intersects the sphere in two points with
			// parametric coordinates of "p" and "q".
			// (If "d" is zero the two points are coincident, the path is tangent)
			s = Number(Math.sqrt(d));
			p = (-b + s) / 2;
			q = (-b - s) / 2;

			// both intersections are behind us, so no potential collisions
			if ((p < 0) && (q < 0)) return;

			// at least one intersection is in front of us
			intersection.intersect = true;
			intersection.distance =
				((p > 0) && (q > 0)) ?
				// both intersections are in front of us, find nearest one
				((p < q) ? p : q) :
				// otherwise only one intersections is in front, select it
				((p > 0) ? p : q);
		}
	}
}
