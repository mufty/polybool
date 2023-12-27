package polybool;

import tools.polybool.lib.SegmentChainer;
import tools.polybool.lib.SegmentSelector;
import h2d.col.Point;
import tools.polybool.lib.Intersecter;
import tools.polybool.lib.Epsilon;

typedef Poly = {
    regions: Array<Array<Point>>,
    inverted: Bool
};

typedef Segments = {
    segments: Array<Segment>,
    inverted: Bool
};

typedef CombinedSegments = {
    combined: Array<Segment>,
    inverted1: Bool,
    inverted2: Bool
};

//https://github.com/velipso/polybooljs
class PolyBool {
    static var epsilon = new Epsilon();

    static function epsilonFn(v:Float){
		return epsilon.epsilon(v);
	}

    static function segments(poly:Poly):Segments {
		var i = new Intersecter(true, epsilon);
        for(r in poly.regions){
            i.addRegion(r);
        }
		return {
			segments: i.calculate(poly.inverted),
			inverted: poly.inverted
		};
	}

    static function combine(segments1:Segments, segments2:Segments):CombinedSegments {
		var i3 = new Intersecter(false, epsilon);
		return {
			combined: i3.calculate2(
				segments1.segments, segments1.inverted,
				segments2.segments, segments2.inverted
			),
			inverted1: segments1.inverted,
			inverted2: segments2.inverted
		};
	}

    static function selectUnion(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.union(combined.combined),
			inverted: combined.inverted1 || combined.inverted2
		}
	}

    static function selectIntersect(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.intersect(combined.combined),
			inverted: combined.inverted1 && combined.inverted2
		}
	}

    static function selectDifference(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.difference(combined.combined),
			inverted: combined.inverted1 && !combined.inverted2
		}
	}

    static function selectDifferenceRev(combined:CombinedSegments):Segments{
		return {
			segments: SegmentSelector.differenceRev(combined.combined),
			inverted: !combined.inverted1 && combined.inverted2
		}
	}

    static function selectXor(combined:CombinedSegments):Segments{
		return {
			segments: SegmentSelector.xor(combined.combined),
			inverted: combined.inverted1 != combined.inverted2
		}
	}

    static function polygon(segments:Segments):Poly{
		return {
			regions: SegmentChainer.chain(segments.segments, epsilon),
			inverted: segments.inverted
		};
	}

    static function operate(poly1:Poly, poly2:Poly, selector:CombinedSegments->Segments):Poly {
        var seg1 = PolyBool.segments(poly1);
        var seg2 = PolyBool.segments(poly2);
        var comb = PolyBool.combine(seg1, seg2);
        var seg3 = selector(comb);
        return PolyBool.polygon(seg3);
    }

    public static function union(poly1:Poly, poly2:Poly):Poly{
		return operate(poly1, poly2, PolyBool.selectUnion);
	}

    public static function intersect(poly1:Poly, poly2:Poly):Poly{
		return operate(poly1, poly2, PolyBool.selectIntersect);
	}

    public static function difference(poly1:Poly, poly2:Poly):Poly{
		return operate(poly1, poly2, PolyBool.selectDifference);
	}

    public static function differenceRev(poly1:Poly, poly2:Poly):Poly{
		return operate(poly1, poly2, PolyBool.selectDifferenceRev);
	}

    public static function xor(poly1:Poly, poly2:Poly):Poly{
		return operate(poly1, poly2, PolyBool.selectXor);
	}

}