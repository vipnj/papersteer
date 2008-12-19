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

package tabinda.as3steer
{
	/** This mixin class with the super class adds the "steering library"
	* functionality to a given base class.  SteerLibraryMixin assumes its base
	* class supports the AbstractVehicle interface.
	*/
	public class SteerLibrary extends AbstractVehicle
	{
		// Randomiser
		var randomGenerator:Number = Math.random();

		// Wander behavior
		var WanderSide:Number;
		var WanderUp:Number;

		/// XXX globals only for the sake of graphical annotation
		var hisPositionAtNearestApproach:Vector3;
		var ourPositionAtNearestApproach:Vector3;

		var gaudyPursuitAnnotation:Boolean;

		// reset state
		public function resetSteering():void
		{
			// initial state of wander behavior
			WanderSide=0;
			WanderUp=0;

			// default to non-gaudyPursuitAnnotation
			gaudyPursuitAnnotation=false;

			randomGenerator=Math.random();
		}

		function isAhead1(target:Vector3):Boolean
		{
			return isAhead2(target,0.707);
		}
		function isAside1(target:Vector3):Boolean
		{
			return isAside2(target,0.707);
		}
		function isBehind1(target:Vector3):Boolean
		{
			return isBehind2(target,-0.707);
		}

		function isAhead2(target:Vector3,cosThreshold:Number)
		{
			var targetDirection:Vector3=Vector3.VectorSubtraction(target , Position());
			targetDirection.Normalise();
			return (forward().DotProduct(targetDirection) > cosThreshold);
		}
		function isAside2(target:Vector3,cosThreshold:Number):Boolean
		{
			var targetDirection:Vector3=Vector3.VectorSubtraction(target , Position());
			targetDirection.Normalise();
			var dp:Number=forward().DotProduct(targetDirection);
			return dp < cosThreshold && dp > - cosThreshold;
		}
		function isBehind2(target:Vector3,cosThreshold:Number):Boolean
		{
			var targetDirection:Vector3=Vector3.VectorSubtraction(target , Position());
			targetDirection.Normalise();
			return forward().DotProduct(targetDirection) < cosThreshold;
		}

		// called when steerToAvoidObstacles decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function annotateAvoidObstacle(minDistanceToCollision:Number):void
		{
		}

		// called when steerToFollowPath decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function annotatePathFollowing(future:Vector3,onPath:Vector3,target:Vector3,outside:Number):void
		{
		}

		// called when steerToAvoidCloseNeighbors decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function annotateAvoidCloseNeighbor(otherVehicle:AbstractVehicle,seperationDistance:Number):void
		{
		}

		// called when steerToAvoidNeighbors decides steering is required
		// (default action is to do nothing, layered classes can overload it)
		public function annotateAvoidNeighbor(vehicle:AbstractVehicle,steer:Number,position:Vector3,threatPosition:Vector3):void
		{
		}

		public function steerForWander(dt:Number):Vector3
		{
			// random walk WanderSide and WanderUp between -1 and +1
			var speed:Number=12 * dt;// maybe this (12) should be an argument?
			WanderSide=scalarRandomWalk(WanderSide,speed,-1,+1);
			WanderUp=scalarRandomWalk(WanderUp,speed,-1,+1);

			// return a pure lateral steering vector: (+/-Side) + (+/-Up)
			return Vector3.VectorAddition(Vector3.ScalarMultiplication1(side() , WanderSide) , Vector3.ScalarMultiplication1(up(),  WanderUp));
		}


		public function steerForSeek(target:Vector3):Vector3
		{
			var desiredVelocity:Vector3=Vector3.VectorSubtraction(target , Position());
			return Vector3.VectorSubtraction(desiredVelocity , velocity());
		}


		// ----------------------------------------------------------------------------
		// Flee behavior
		public function steerForFlee(target:Vector3):Vector3
		{
			var desiredVelocity:Vector3=Vector3.VectorSubtraction(Position() , target);
			return Vector3.VectorSubtraction(desiredVelocity , velocity());
		}

		// ----------------------------------------------------------------------------
		// xxx proposed, experimental new seek/flee [cwr 9-16-02]
		public function xxxsteerForFlee(target:Vector3):Vector3
		{

			var offset:Vector3=Vector3.VectorSubtraction(Position() , target);
			var desiredVelocity:Vector3=truncateLength(offset,maxSpeed());
			return Vector3.VectorSubtraction(desiredVelocity , velocity());
		}
		public function xxxsteerForSeek(target:Vector3):Vector3
		{

			var offset:Vector3=Vector3.VectorSubtraction(target , Position());
			var desiredVelocity:Vector3=truncateLength(offset,maxSpeed());
			return Vector3.VectorSubtraction(desiredVelocity , velocity());
		}


		// ----------------------------------------------------------------------------
		// Path Following behaviors
		public function steerToStayOnPath(predictionTime:Number,path:Pathway):Vector3
		{
			// predict our future position
			var futurePosition:Vector3=predictFuturePosition(predictionTime);
			var tStruct:mapReturnStruct=new mapReturnStruct();
			var onPath:Vector3=path.mapPointToPath(futurePosition,tStruct);

			if (tStruct.outside < 0)
			{
				// our predicted future position was in the path,
				// return zero steering.
				return Vector3.ZERO;
			}
			else
			{
				// our predicted future position was outside the path, need to
				// steer towards it.  Use onPath projection of futurePosition
				// as seek target
				annotatePathFollowing(futurePosition,onPath,onPath,tStruct.outside);
				return steerForSeek(onPath);
			}
		}

		public function steerToFollowPath(direction:int,predictionTime:Number,path:Pathway):Vector3
		{
			// our goal will be offset from our path distance by this amount
			var pathDistanceOffset:Number=direction * predictionTime * speed();

			// predict our future position
			var futurePosition:Vector3=predictFuturePosition(predictionTime);
			
			// measure distance along path of our current and predicted positions
			var nowPathDistance:Number=path.mapPointToPathDistance(Position());
			var futurePathDistance:Number=path.mapPointToPathDistance(futurePosition);

			// are we facing in the correction direction?
			var rightway:Boolean=pathDistanceOffset > 0?nowPathDistance < futurePathDistance:nowPathDistance > futurePathDistance;

			// find the point on the path nearest the predicted future position
			// XXX need to improve calling sequence, maybe change to return a
			// XXX special path-defined object which includes two Vector3s and a 
			// XXX bool (onPath,tangent (ignored), withinPath)
			var tStruct:mapReturnStruct=new mapReturnStruct  ;
			var onPath:Vector3=path.mapPointToPath(futurePosition,tStruct);

			// no steering is required if (a) our future position is inside
			// the path tube and (b) we are facing in the correct direction
			if ((tStruct.outside < 0) && rightway)
			{
				// all is well, return zero steering
				return Vector3.ZERO;
			}
			else
			{
				// otherwise we need to steer towards a target point obtained
				// by adding pathDistanceOffset to our current path position
				var targetPathDistance:Number=nowPathDistance + pathDistanceOffset;
				var target:Vector3=path.mapPathDistanceToPoint(targetPathDistance);

				annotatePathFollowing(futurePosition,onPath,target,tStruct.outside);

				// return steering to seek target on path
				return steerForSeek(target);
			}
		}

		// ----------------------------------------------------------------------------
		// Obstacle Avoidance behavior
		//
		// Returns a steering force to avoid a given obstacle.  The purely lateral
		// steering force will turn our vehicle towards a silhouette edge of the
		// obstacle.  Avoidance is required when (1) the obstacle intersects the
		// vehicle's current path, (2) it is in front of the vehicle, and (3) is
		// within minTimeToCollision seconds of travel at the vehicle's current
		// velocity.  Returns a zero vector value (Vector3::zero) when no avoidance is
		// required.
		//
		// XXX The current (4-23-03) scheme is to dump all the work on the various
		// XXX Obstacle classes, making them provide a "steer vehicle to avoid me"
		// XXX method.  This may well change.
		//
		// XXX 9-12-03: this routine is probably obsolete: its name is too close to
		// XXX the new steerToAvoidObstacles and the arguments are reversed
		// XXX (perhaps there should be another version of steerToAvoidObstacles
		// XXX whose second arg is "const Obstacle& obstacle" just in case we want
		// XXX to avoid a non-grouped obstacle)
		public function steerToAvoidObstacle(minTimeToCollision:Number,obstacle:Obstacle):Vector3
		{
			var avoidance:Vector3=obstacle.steerToAvoid(this,minTimeToCollision);

			// XXX more annotation modularity problems (assumes spherical obstacle)
			if (avoidance != Vector3.ZERO)
			{
				annotateAvoidObstacle(minTimeToCollision * speed());
			}

			return avoidance;
		}

		// this version avoids all of the obstacles in an ObstacleGroup
		//
		// XXX 9-12-03: note this does NOT use the Obstacle::steerToAvoid protocol
		// XXX like the older steerToAvoidObstacle does/did.  It needs to be fixed
		public function steerToAvoidObstacles(minTimeToCollision:Number,obstacles:Array):Vector3
		{
			var avoidance:Vector3=new Vector3();
			var nearest:PathIntersection,next:PathIntersection;

			nearest=new PathIntersection();
			next=new PathIntersection();

			var minDistanceToCollision:Number=minTimeToCollision * speed();

			next.intersect=0;// false;
			nearest.intersect=0;// false;

			// test all obstacles for intersection with my forward axis,
			// select the one whose point of intersection is nearest
			for (var i:int=0; i < obstacles.length; i++)
			{
				var o:SphericalObstacle=SphericalObstacle(obstacles[i]);
				// xxx this should be a generic call on Obstacle, rather than
				// xxx this code which presumes the obstacle is spherical
				findNextIntersectionWithSphere(o,next);

				if (nearest.intersect == 0 || next.intersect != 0 && next.distance < nearest.distance)
				{
					nearest=next;
				}
			}

			// when a nearest intersection was found
			if (nearest.intersect != 0 && nearest.distance < minDistanceToCollision)
			{
				// show the corridor that was checked for collisions
				annotateAvoidObstacle(minDistanceToCollision);

				// compute avoidance steering force: take offset from obstacle to me,
				// take the component of that which is lateral (perpendicular to my
				// forward direction), set length to maxForce, add a bit of forward
				// component (in capture the flag, we never want to slow down)
				var offset:Vector3=Vector3.VectorSubtraction(Position() , nearest.obstacle.center);
				avoidance=Utility.perpendicularComponent(offset,forward());

				avoidance.Normalise();
				avoidance= Vector3.ScalarMultiplication1(avoidance,maxForce());
				avoidance= Vector3.VectorAddition(avoidance,Vector3.ScalarMultiplication1(Vector3.ScalarMultiplication1(forward() , maxForce()) , 0.75));
			}

			return avoidance;
		}

		// ----------------------------------------------------------------------------
		// Unaligned collision avoidance behavior: avoid colliding with other nearby
		// vehicles moving in unconstrained directions.  Determine which (if any)
		// other other vehicle we would collide with first, then steers to avoid the
		// site of that potential collision.  Returns a steering force vector, which
		// is zero length if there is no impending collision.
		public function steerToAvoidNeighbors(minTimeToCollision:Number,others:Array):Vector3
		{
			// first priority is to prevent immediate interpenetration
			var separation:Vector3=steerToAvoidCloseNeighbors(0,others);
			if (separation != Vector3.ZERO)
			{
				return separation;
			}

			// otherwise, go on to consider potential future collisions
			var steer:Number=0;
			var threat:AbstractVehicle=null;

			// Time (in seconds) until the most immediate collision threat found
			// so far.  Initial value is a threshold: don't look more than this
			// many frames into the future.
			var minTime:Number=minTimeToCollision;

			// xxx solely for annotation
			var xxxThreatPositionAtNearestApproach:Vector3=new Vector3();
			var xxxOurPositionAtNearestApproach:Vector3=new Vector3();

			// for each of the other vehicles, determine which (if any)
			// pose the most immediate threat of collision.
			for (var i:int=0; i < others.length; i++)
			{
				var other:AbstractVehicle=AbstractVehicle(others[i]);
				if (other != this)
				{
					// avoid when future positions are this close (or less)
					var collisionDangerThreshold:Number=radius() * 2;

					// predicted time until nearest approach of "this" and "other"
					var time:Number=predictNearestApproachTime(other);

					// If the time is in the future, sooner than any other
					// threatened collision...
					if (time >= 0 && time < minTime)
					{
						// if the two will be close enough to collide,
						// make a note of it
						if (computeNearestApproachPositions(other,time) < collisionDangerThreshold)
						{
							minTime=time;
							threat=other;
							xxxThreatPositionAtNearestApproach=hisPositionAtNearestApproach;
							xxxOurPositionAtNearestApproach=ourPositionAtNearestApproach;
						}
					}
				}
			}

			// if a potential collision was found, compute steering to avoid
			if (threat != null)
			{
				// parallel: +1, perpendicular: 0, anti-parallel: -1
				var parallelness:Number=forward().DotProduct(threat.forward());
				var angle:Number=0.707;

				if (parallelness < - angle)
				{
					// anti-parallel "head on" paths:
					// steer away from future threat position
					var offset:Vector3=Vector3.VectorSubtraction(xxxThreatPositionAtNearestApproach , Position());
					var sideDot:Number=offset.DotProduct(side());
					steer=sideDot > 0?-1.0:1.0;
				}
				else
				{
					if (parallelness > angle)
					{
						// parallel paths: steer away from threat
						offset=Vector3.VectorSubtraction(threat.Position() , Position());
						sideDot=offset.DotProduct(side());
						steer=sideDot > 0?-1.0:1.0;
					}
					else
					{
						// perpendicular paths: steer behind threat
						// (only the slower of the two does this)
						if (threat.speed() <= speed())
						{
							sideDot=side().DotProduct(threat.velocity());
							steer=sideDot > 0?-1.0:1.0;
						}
					}
				}
				annotateAvoidNeighbor(threat,steer,xxxOurPositionAtNearestApproach,xxxThreatPositionAtNearestApproach);
			}
			return Vector3.ScalarMultiplication1(side() , steer);
		}

		// Given two vehicles, based on their current positions and velocities,
		// determine the time until nearest approach
		//
		// XXX should this return zero if they are already in contact?
		function predictNearestApproachTime(other:AbstractVehicle):Number
		{
			// imagine we are at the origin with no velocity,
			// compute the relative velocity of the other vehicle
			var myVelocity:Vector3=velocity();
			var otherVelocity:Vector3=other.velocity();
			var relVelocity:Vector3=Vector3.VectorSubtraction(otherVelocity , myVelocity);
			var relSpeed:Number=relVelocity.Length();

			// for parallel paths, the vehicles will always be at the same distance,
			// so return 0 (aka "now") since "there is no time like the present"
			if (relSpeed == 0)
			{
				return 0;
			}

			// Now consider the path of the other vehicle in this relative
			// space, a line defined by the relative position and velocity.
			// The distance from the origin (our vehicle) to that line is
			// the nearest approach.

			// Take the unit tangent along the other vehicle's path
			var relTangent:Vector3=Vector3.ScalarDivision(relVelocity , relSpeed);

			// find distance from its path to origin (compute offset from
			// other to us, find length of projection onto path)
			var relPosition:Vector3=Vector3.VectorSubtraction(Position() , other.Position());
			var projection:Number=relTangent.DotProduct(relPosition);

			return projection / relSpeed;
		}

		// Given the time until nearest approach (predictNearestApproachTime)
		// determine position of each vehicle at that time, and the distance
		// between them
		function computeNearestApproachPositions(other:AbstractVehicle,time:Number):Number
		{
			var myTravel:Vector3=Vector3.ScalarMultiplication1(forward() , (speed() * time));
			var otherTravel:Vector3=Vector3.ScalarMultiplication1(other.forward() , (other.speed() * time));

			var myFinal:Vector3=Vector3.VectorAddition(Position() , myTravel);
			var otherFinal:Vector3=Vector3.VectorAddition(other.Position() , otherTravel);

			// xxx for annotation
			ourPositionAtNearestApproach=myFinal;
			hisPositionAtNearestApproach=otherFinal;

			return Vector3.VectorSubtraction(myFinal , otherFinal).Length();//Vector3::distance (myFinal, otherFinal);
		}

		// ----------------------------------------------------------------------------
		// avoidance of "close neighbors" -- used only by steerToAvoidNeighbors
		//
		// XXX  Does a hard steer away from any other agent who comes withing a
		// XXX  critical distance.  Ideally this should be replaced with a call
		// XXX  to steerForSeparation.
		public function steerToAvoidCloseNeighbors(minSeparationDistance:Number,others:Array):Vector3
		{
			// for each of the other vehicles...
			for (var i:int=0; i < others.Count; i++)
			{
				var other:AbstractVehicle=AbstractVehicle(others[i]);
				if (other != this)
				{
					var sumOfRadii:Number=radius() + other.radius();
					var minCenterToCenter:Number=minSeparationDistance + sumOfRadii;
					var offset:Vector3=Vector3.VectorSubtraction(other.Position() , Position());
					var currentDistance:Number=offset.Length();

					if (currentDistance < minCenterToCenter)
					{
						annotateAvoidCloseNeighbor(other,minSeparationDistance);
						return Utility.perpendicularComponent(offset.Invert(),forward());
					}
				}
			}
			// otherwise return zero
			return Vector3.ZERO;
		}

		// ----------------------------------------------------------------------------
		// used by boid behaviors: is a given vehicle within this boid's neighborhood?
		function inBoidNeighborhood(other:AbstractVehicle,minDistance:Number,maxDistance:Number,cosMaxAngle:Number):Boolean
		{
			if (other == this)
			{
				return false;
			}
			else
			{
				var offset:Vector3=Vector3.VectorSubtraction(other.Position() , Position());
				var distanceSquared:Number=offset.SquaredLength();

				// definitely in neighborhood if inside minDistance sphere
				if (distanceSquared < minDistance * minDistance)
				{
					return true;
				}
				else
				{
					// definitely not in neighborhood if outside maxDistance sphere
					if (distanceSquared > maxDistance * maxDistance)
					{
						return false;
					}
					else
					{
						// otherwise, test angular offset from forward axis
						var unitOffset:Vector3=Vector3.ScalarDivision(offset , Number(Math.sqrt(distanceSquared)));
						var forwardness:Number = forward().DotProduct(unitOffset);
						return forwardness > cosMaxAngle;
					}
				}
			}
		}

		// ----------------------------------------------------------------------------
		// Separation behavior: steer away from neighbors
		public function steerForSeparation(maxDistance:Number,cosMaxAngle:Number,flock:Array):Vector3
		{
			// steering accumulator and count of neighbors, both initially zero
			var steering:Vector3=Vector3.ZERO;
			var neighbors:int=0;

			// for each of the other vehicles...
			for (var i:int=0; i < flock.length; i++)
			{
				var other:AbstractVehicle=AbstractVehicle(flock[i]);
				if (inBoidNeighborhood(other,radius() * 3,maxDistance,cosMaxAngle))
				{
					// add in steering contribution
					// (opposite of the offset direction, divided once by distance
					// to normalize, divided another time to get 1/d falloff)
					var offset:Vector3=Vector3.VectorSubtraction(other.Position() , Position());
					var distanceSquared:Number=offset.DotProduct(offset);
					steering = Vector3.VectorAddition(steering,Vector3.ScalarDivision(offset , - distanceSquared));

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, then normalize to pure direction
			if (neighbors > 0)
			{
				steering=Vector3.ScalarDivision(steering , Number(neighbors));
				steering.Normalise();
			}
			return steering;
		}

		// ----------------------------------------------------------------------------
		// Alignment behavior: steer to head in same direction as neighbors
		public function steerForAlignment(maxDistance:Number,cosMaxAngle:Number,flock:Array):Vector3
		{
			// steering accumulator and count of neighbors, both initially zero
			var steering:Vector3=Vector3.ZERO;
			var neighbors:int=0;

			// for each of the other vehicles...
			for (var i:int=0; i < flock.length; i++)
			{
				var other:AbstractVehicle=AbstractVehicle(flock[i]);

				if (inBoidNeighborhood(other,radius() * 3,maxDistance,cosMaxAngle))
				{
					// accumulate sum of neighbor's heading
					steering= Vector3.VectorAddition(steering,other.forward());

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, subtract off current heading to get error-
			// correcting direction, then normalize to pure direction
			if (neighbors > 0)
			{
				steering=Vector3.VectorSubtraction(Vector3.ScalarDivision(steering , Number(neighbors)) , forward());
				steering.Normalise();
			}
			return steering;
		}

		// ----------------------------------------------------------------------------
		// Cohesion behavior: to to move toward center of neighbors
		public function steerForCohesion(maxDistance:Number,cosMaxAngle:Number,flock:Array):Vector3
		{
			// steering accumulator and count of neighbors, both initially zero
			var steering:Vector3=Vector3.ZERO;
			var neighbors:int=0;

			// for each of the other vehicles...
			for (var i:int=0; i < flock.length; i++)
			{
				var other:AbstractVehicle=AbstractVehicle(flock[i]);

				if (inBoidNeighborhood(other,radius() * 3,maxDistance,cosMaxAngle))
				{
					// accumulate sum of neighbor's positions
					steering = Vector3.VectorAddition(steering,other.Position());

					// count neighbors
					neighbors++;
				}
			}

			// divide by neighbors, subtract off current position to get error-
			// correcting direction, then normalize to pure direction
			if (neighbors > 0)
			{
				steering=Vector3.VectorSubtraction(Vector3.ScalarDivision(steering , Number(neighbors)) , Position());
				steering.Normalise();
			}
			return steering;
		}

		// ----------------------------------------------------------------------------
		// pursuit of another vehicle (& version with ceiling on prediction time)
		public function steerForPursuit(...args):Vector3
		{
			if(args.length == 2)
			{
			// offset from this to quarry, that distance, unit vector toward quarry
			var offset:Vector3=Vector3.VectorSubtraction(args[0].Position() , Position());
			var distance:Number=offset.Length();
			var unitOffset:Vector3=Vector3.ScalarDivision(offset , distance);

			// how parallel are the paths of "this" and the quarry
			// (1 means parallel, 0 is pependicular, -1 is anti-parallel)
			var parallelness:Number=forward().DotProduct(args[0].forward());

			// how "forward" is the direction to the quarry
			// (1 means dead ahead, 0 is directly to the side, -1 is straight back)
			var forwardness:Number=forward().DotProduct(unitOffset);

			var directTravelTime:Number=distance / speed();
			var f:int=intervalComparison(forwardness,-0.707,0.707);
			var p:int=intervalComparison(parallelness,-0.707,0.707);

			var timeFactor:Number=0;// to be filled in below
			var color:Vector3=Colours.gBlack;// to be filled in below (xxx just for debugging)

			// Break the pursuit into nine cases, the cross product of the
			// quarry being [ahead, aside, or behind] us and heading
			// [parallel, perpendicular, or anti-parallel] to us.
			switch (f)
			{
				case +1 :
					switch (p)
					{
						case +1 :// ahead, parallel
							timeFactor=4;
							color=Colours.gBlack;
							break;
						case 0 :// ahead, perpendicular
							timeFactor = 1.8;
							f;
							color=Colours.gGray50;
							break;
						case -1 :// ahead, anti-parallel
							timeFactor = 0.85;
							f;
							color=Colours.gWhite;
							break;
					}
					break;
				case 0 :
					switch (p)
					{
						case +1 :// aside, parallel
							timeFactor=1;
							color=Colours.gRed;
							break;
						case 0 :// aside, perpendicular
							timeFactor = 0.8;
							f;
							color=Colours.gYellow;
							break;
						case -1 :// aside, anti-parallel
							timeFactor=4;
							color=Colours.gGreen;
							break;
					}
					break;
				case -1 :
					switch (p)
					{
						case +1 :// behind, parallel
							timeFactor = 0.5;
							f;
							color=Colours.gCyan;
							break;
						case 0 :// behind, perpendicular
							timeFactor=2;
							color=Colours.gBlue;
							break;
						case -1 :// behind, anti-parallel
							timeFactor=2;
							color=Colours.gMagenta;
							break;
					}
					break;
			}

			// estimated time until intercept of quarry
			var et:Number=directTravelTime * timeFactor;

			// xxx experiment, if kept, this limit should be an argument
			var etl:Number=et > args[1]?args[1]:et;

			// estimated position of quarry at intercept
			var target:Vector3=args[0].predictFuturePosition(etl);

			// annotation
			annotationLine(Position(),target,gaudyPursuitAnnotation?color:Colours.gGray40);

			return steerForSeek(target);
			}
			else
			{
				return steerForPursuit(args[0],Number.MAX_VALUE);
			}
		}

		// ----------------------------------------------------------------------------
		// evasion of another vehicle
		public function steerForEvasion(menace:AbstractVehicle,maxPredictionTime:Number):Vector3
		{
			// offset from this to menace, that distance, unit vector toward menace
			var offset:Vector3=Vector3.VectorSubtraction(menace.Position() , Position());
			var distance:Number=offset.Length();

			var roughTime:Number=distance / menace.speed();
			var predictionTime:Number=roughTime > maxPredictionTime?maxPredictionTime:roughTime;

			var target:Vector3=menace.predictFuturePosition(predictionTime);

			return steerForFlee(target);
		}

		// ----------------------------------------------------------------------------
		// tries to maintain a given speed, returns a maxForce-clipped steering
		// force along the forward/backward axis
		public function steerForTargetSpeed(targetSpeed:Number):Vector3
		{
			var mf:Number=maxForce();
			var speedError:Number=targetSpeed - speed();
			return Vector3.ScalarMultiplication1(forward() , Utility.clip(speedError,- mf,+ mf));
		}

		// ----------------------------------------------------------------------------
		// xxx experiment cwr 9-6-02
		public function findNextIntersectionWithSphere(obs:SphericalObstacle,intersection:PathIntersection):void
		{
			// xxx"SphericalObstacle& obs" should be "const SphericalObstacle&
			// obs" but then it won't let me store a pointer to in inside the
			// PathIntersection

			// This routine is based on the Paul Bourke's derivation in:
			//   Intersection of a Line and a Sphere (or circle)
			//   http://www.swin.edu.au/astronomy/pbourke/geometry/sphereline/

			var b:Number,c:Number,d:Number,p:Number,q:Number,s:Number;
			var lc:Vector3;

			// initialize pathIntersection object
			intersection.intersect=0;
			intersection.obstacle=obs;

			// find "local center" (lc) of sphere in boid's coordinate space
			lc=localizePosition(obs.center);

			// computer line-sphere intersection parameters
			b=-2 * lc.z;
			c=square(lc.x) + square(lc.y) + square(lc.z) - square(obs.radius + radius());
			d=(b * b) - (4 * c);

			// when the path does not intersect the sphere
			if (d < 0)
			{
				return;
			}

			// otherwise, the path intersects the sphere in two points with
			// parametric coordinates of "p" and "q".
			// (If "d" is zero the two points are coincident, the path is tangent)
			s=Number(Math.sqrt(d));
			p=(- b + s) / 2;
			q=(- b - s) / 2;

			// both intersections are behind us, so no potential collisions
			if (p < 0 && q < 0)
			{
				return;
			}

			// at least one intersection is in front of us
			intersection.intersect=0;
			intersection.distance=((p > 0) && (q > 0)) ?
                // both intersections are in front of us, find nearest one
                ((p < q) ? p : q) :
                // otherwise only one intersections is in front, select it
                ((p > 0) ? p : q);
			return;
		}

		public function scalarRandomWalk(initial:Number,walkspeed:Number,min:Number,max:Number):Number
		{
			var next:Number=initial + (((frandom01() * 2) - 1) * walkspeed);
			if (next < min)
			{
				return min;
			}
			if (next > max)
			{
				return max;
			}
			return next;
		}


		// From utility
		public function frandom01():Number
		{
			return Number(Math.random());//((float) rand ()) / ((float) RAND_MAX));
		}

		public function truncateLength(tVector:Vector3,maxLength:Number):Vector3
		{
			var tLength:Number=tVector.Length();
			var returnVector:Vector3=tVector;
			if (tLength > maxLength)
			{
				returnVector.Normalise();
				returnVector = Vector3.ScalarMultiplication1(returnVector,maxLength);
			}
			return returnVector;
		}

		public function intervalComparison(x:Number,lowerBound:Number,upperBound:Number):int
		{
			if (x < lowerBound)
			{
				return -1;
			}
			if (x > upperBound)
			{
				return +1;
			}
			return 0;
		}

		public function square(x:Number):Number
		{
			return x * x;
		}

		public function annotationLine(startPoint:Vector3,endPoint:Vector3,color:Vector3):void
		{
		}
	}
}