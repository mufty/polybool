package polybool.lib;

import polybool.lib.Types.Transition;
import polybool.lib.Types.Point;
import polybool.lib.Types.Segment;
import polybool.lib.Types.Node;
import uuid.Uuid;

class Intersecter {

    var eps:Epsilon;
    var selfIntersection:Bool;
    var event_root:LinkedList = LinkedList.create();

    public function new(selfIntersection:Bool, eps:Epsilon) {
        this.eps = eps;
        this.selfIntersection = selfIntersection;
    }

    public function segmentNew(start:Point, end:Point):Segment {
		return {
			id: Uuid.nanoId(),
			start: start,
			end: end,
			myFill: {
				above: null, // is there fill above us?
				below: null  // is there fill below us?
			},
			otherFill: null
		};
	}

    public function segmentCopy(start, end:Point, seg:Segment):Segment {
		return {
			id: Uuid.nanoId(),
			start: start,
			end: end,
			myFill: {
				above: seg.myFill.above,
				below: seg.myFill.below
			},
			otherFill: null
		};
	}

    public function eventCompare(p1_isStart:Bool, p1_1:Point, p1_2:Point, p2_isStart:Bool, p2_1:Point, p2_2:Point):Int{
		// compare the selected points first
		var comp = eps.pointsCompare(p1_1, p2_1);
		if (comp != 0)
			return comp;
		// the selected points are the same

		if (eps.pointsSame(p1_2, p2_2)) // if the non-selected points are the same too...
			return 0; // then the segments are equal

		if (p1_isStart != p2_isStart) // if one is a start and the other isn't...
			return p1_isStart ? 1 : -1; // favor the one that isn't the start

		// otherwise, we'll have to calculate which one is below the other manually
		return eps.pointAboveOrOnLine(p1_2,
			p2_isStart ? p2_1 : p2_2, // order matters
			p2_isStart ? p2_2 : p2_1
		) ? 1 : -1;
	}

    public function eventAdd(ev:Node, other_pt:Point){
        event_root.insertBefore(ev, function(here){
			// should ev be inserted before here?
			var comp = eventCompare(
				ev  .isStart, ev  .pt,      other_pt,
				here.isStart, here.pt, here.other.pt
			);
			return comp < 0;
		});
	}

    public function eventAddSegmentStart(seg:Segment, primary:Bool):Node {
        var ev_start = LinkedList.node({
			isStart: true,
			pt: seg.start,
			seg: seg,
			primary: primary,
			other: null,
			status: null
		});
		eventAdd(ev_start, seg.end);
		return ev_start;
	}

    public function eventAddSegmentEnd(ev_start:Node, seg:Segment, primary:Bool){
        var ev_end = LinkedList.node({
			isStart: false,
			pt: seg.end,
			seg: seg,
			primary: primary,
			other: ev_start,
			status: null
		});
        ev_start.other = ev_end;
		eventAdd(ev_end, ev_start.pt);
	}

    public function eventAddSegment(seg:Segment, primary:Bool):Node {
		var ev_start = eventAddSegmentStart(seg, primary);
		eventAddSegmentEnd(ev_start, seg, primary);
		return ev_start;
	}

    public function eventUpdateEnd(ev:Node, end:Point){
		// slides an end backwards
		//   (start)------------(end)    to:
		//   (start)---(end)
		ev.other.remove();
		ev.seg.end = end;
		ev.other.pt = end;
		eventAdd(ev.other, ev.pt);
	}

    public function eventDivide(ev:Node, pt:Point):Node{
		var ns = segmentCopy(pt, ev.seg.end, ev.seg);
		eventUpdateEnd(ev, pt);
		return eventAddSegment(ns, ev.primary);
	}

    public function calculate(primaryPolyInverted:Bool, secondaryPolyInverted:Bool=false):Array<Segment>{
		// if selfIntersection is true then there is no secondary polygon, so that isn't used

		//
		// status logic
		//

		var status_root:LinkedList = LinkedList.create();

		function statusCompare(ev1:Node, ev2:Node){
			var a1 = ev1.seg.start;
			var a2 = ev1.seg.end;
			var b1 = ev2.seg.start;
			var b2 = ev2.seg.end;

			if (eps.pointsCollinear(a1, b1, b2)){
				if (eps.pointsCollinear(a2, b1, b2))
					return 1;//eventCompare(true, a1, a2, true, b1, b2);
				return eps.pointAboveOrOnLine(a2, b1, b2) ? 1 : -1;
			}
			return eps.pointAboveOrOnLine(a1, b1, b2) ? 1 : -1;
		}

		function statusFindSurrounding(ev:Node):Transition{
			return status_root.findTransition(function(here){
            //return event_root.findTransition(function(here){
				var comp = statusCompare(ev, here);
				return comp > 0;
			});
		}

		function checkIntersection(ev1:Node, ev2:Node):Node{
			// returns the segment equal to ev1, or false if nothing equal

			var seg1 = ev1.seg;
			var seg2 = ev2.seg;
			var a1 = seg1.start;
			var a2 = seg1.end;
			var b1 = seg2.start;
			var b2 = seg2.end;

			var i = eps.linesIntersect(a1, a2, b1, b2);

			if (i == null){
				// segments are parallel or coincident

				// if points aren't collinear, then the segments are parallel, so no intersections
				if (!eps.pointsCollinear(a1, a2, b1))
					return null;
				// otherwise, segments are on top of each other somehow (aka coincident)

				if (eps.pointsSame(a1, b2) || eps.pointsSame(a2, b1))
					return null; // segments touch at endpoints... no intersection

				var a1_equ_b1 = eps.pointsSame(a1, b1);
				var a2_equ_b2 = eps.pointsSame(a2, b2);

				if (a1_equ_b1 && a2_equ_b2)
					return ev2; // segments are exactly equal

				var a1_between = !a1_equ_b1 && eps.pointBetween(a1, b1, b2);
				var a2_between = !a2_equ_b2 && eps.pointBetween(a2, b1, b2);

				// handy for debugging:
				// buildLog.log({
				//	a1_equ_b1: a1_equ_b1,
				//	a2_equ_b2: a2_equ_b2,
				//	a1_between: a1_between,
				//	a2_between: a2_between
				// });

				if (a1_equ_b1){
					if (a2_between){
						//  (a1)---(a2)
						//  (b1)----------(b2)
						eventDivide(ev2, a2);
					}
					else{
						//  (a1)----------(a2)
						//  (b1)---(b2)
						eventDivide(ev1, b2);
					}
					return ev2;
				}
				else if (a1_between){
					if (!a2_equ_b2){
						// make a2 equal to b2
						if (a2_between){
							//         (a1)---(a2)
							//  (b1)-----------------(b2)
							eventDivide(ev2, a2);
						}
						else{
							//         (a1)----------(a2)
							//  (b1)----------(b2)
							eventDivide(ev1, b2);
						}
					}

					//         (a1)---(a2)
					//  (b1)----------(b2)
					eventDivide(ev2, a1);
				}
			}
			else{
				// otherwise, lines intersect at i.pt, which may or may not be between the endpoints

				// is A divided between its endpoints? (exclusive)
				if (i.alongA == 0){
					if (i.alongB == -1) // yes, at exactly b1
						eventDivide(ev1, b1);
					else if (i.alongB == 0) // yes, somewhere between B's endpoints
						eventDivide(ev1, i.pt);
					else if (i.alongB == 1) // yes, at exactly b2
						eventDivide(ev1, b2);
				}

				// is B divided between its endpoints? (exclusive)
				if (i.alongB == 0){
					if (i.alongA == -1) // yes, at exactly a1
						eventDivide(ev2, a1);
					else if (i.alongA == 0) // yes, somewhere between A's endpoints (exclusive)
						eventDivide(ev2, i.pt);
					else if (i.alongA == 1) // yes, at exactly a2
						eventDivide(ev2, a2);
				}
			}
			return null;
		}

		//
		// main event loop
		//
		var segments = [];
		while (!event_root.isEmpty()){
			var ev = event_root.getHead();

			if (ev.isStart){
				var surrounding = statusFindSurrounding(ev);
				var above = surrounding.before != null ? surrounding.before : null;
				var below = surrounding.after != null ? surrounding.after : null;

				function checkBothIntersections():Node{
					if (above != null){
						var eve = checkIntersection(ev, above);
						if (eve != null)
							return eve;
					}
					if (below != null)
						return checkIntersection(ev, below);
					return null;
				}

				var eve = checkBothIntersections();
				if (eve != null){
					// ev and eve are equal
					// we'll keep eve and throw away ev

					// merge ev.seg's fill information into eve.seg

					if (selfIntersection){
						var toggle; // are we a toggling edge?
						if (ev.seg.myFill.below == null)
							toggle = true;
						else
							toggle = ev.seg.myFill.above != ev.seg.myFill.below;

						// merge two segments that belong to the same polygon
						// think of this as sandwiching two segments together, where `eve.seg` is
						// the bottom -- this will cause the above fill flag to toggle
						if (toggle)
							eve.seg.myFill.above = !eve.seg.myFill.above;
					}
					else{
						// merge two segments that belong to different polygons
						// each segment has distinct knowledge, so no special logic is needed
						// note that this can only happen once per segment in this phase, because we
						// are guaranteed that all self-intersections are gone
						eve.seg.otherFill = ev.seg.myFill;
					}

					ev.other.remove();
					ev.remove();
				}

				if (event_root.getHead() != ev){
					// something was inserted before us in the event queue, so loop back around and
					// process it before continuing
					continue;
				}

				//
				// calculate fill flags
				//
				if (selfIntersection){
					var toggle; // are we a toggling edge?
					if (ev.seg.myFill.below == null) // if we are a new segment...
						toggle = true; // then we toggle
					else // we are a segment that has previous knowledge from a division
						toggle = ev.seg.myFill.above != ev.seg.myFill.below; // calculate toggle

					// next, calculate whether we are filled below us
					if (below == null){ // if nothing is below us...
						// we are filled below us if the polygon is inverted
						ev.seg.myFill.below = primaryPolyInverted;
					}
					else{
						// otherwise, we know the answer -- it's the same if whatever is below
						// us is filled above it
						ev.seg.myFill.below = below.seg.myFill.above;
					}

					// since now we know if we're filled below us, we can calculate whether
					// we're filled above us by applying toggle to whatever is below us
					if (toggle)
						ev.seg.myFill.above = !ev.seg.myFill.below;
					else
						ev.seg.myFill.above = ev.seg.myFill.below;
				}
				else{
					// now we fill in any missing transition information, since we are all-knowing
					// at this point

					if (ev.seg.otherFill == null){
						// if we don't have other information, then we need to figure out if we're
						// inside the other polygon
						var inside;
						if (below == null){
							// if nothing is below us, then we're inside if the other polygon is
							// inverted
							inside =
								ev.primary ? secondaryPolyInverted : primaryPolyInverted;
						}
						else{ // otherwise, something is below us
							// so copy the below segment's other polygon's above
							if (ev.primary == below.primary)
								inside = below.seg.otherFill.above;
							else
								inside = below.seg.myFill.above;
						}
						ev.seg.otherFill = {
							above: inside,
							below: inside
						};
					}
				}

				// insert the status and remember it for later removal
				ev.other.status = surrounding.insert(LinkedList.node({
                    isStart: ev.isStart,
                    pt: ev.pt,
                    seg: ev.seg,
                    primary: ev.primary,
                    other: ev.other,
                    status: ev.status
                }));
			}
			else{
				var st = ev.status;

				if (st == null){
					/*throw new Error('PolyBool: Zero-length segment detected; your epsilon is ' +
						'probably too small or too large');*/
                    return null;
				}

				// removing the status will create two new adjacent edges, so we'll need to check
				// for those
				if (status_root.exists(st.prev) && status_root.exists(st.next))
                //if (event_root.exists(st.prev) && event_root.exists(st.next))
					checkIntersection(st.prev, st.next);

				// remove the status
				st.remove();

				// if we've reached this point, we've calculated everything there is to know, so
				// save the segment for reporting
				if (!ev.primary){
					// make sure `seg.myFill` actually points to the primary polygon though
					var s = ev.seg.myFill;
					ev.seg.myFill = ev.seg.otherFill;
					ev.seg.otherFill = s;
				}
				segments.push(ev.seg);
			}

			// remove the event and continue
			event_root.getHead().remove();
		}

		return segments;
	}

    public function addRegion(region:Array<Point>){
        // regions are a list of points:
        //  [ [0, 0], [100, 0], [50, 100] ]
        // you can add multiple regions before running calculate
        var pt1;
        var pt2 = region[region.length - 1];
        for (i in 0...region.length){
            pt1 = pt2;
            pt2 = region[i];

            var forward = eps.pointsCompare(pt1, pt2);
            if (forward == 0) // points are equal, so we have a zero-length segment
                continue; // just skip it

            eventAddSegment(
                segmentNew(
                    forward < 0 ? pt1 : pt2,
                    forward < 0 ? pt2 : pt1
                ),
                true
            );
        }
    }

    public function calculate2(segments1:Array<Segment>, inverted1:Bool, segments2:Array<Segment>, inverted2:Bool):Array<Segment>{
        // segmentsX come from the self-intersection API, or this API
        // invertedX is whether we treat that list of segments as an inverted polygon or not
        // returns segments that can be used for further operations
        for(seg in segments1){
            eventAddSegment(segmentCopy(seg.start, seg.end, seg), true);
        }
        
        for(seg in segments2){
            eventAddSegment(segmentCopy(seg.start, seg.end, seg), false);
        }
        
        return calculate(inverted1, inverted2);
    }
}