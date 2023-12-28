package polybool;

import polybool.lib.Types.CombinedSegments;
import polybool.lib.Types.Poly;
import polybool.lib.Types.Segments;
import polybool.lib.SegmentChainer;
import polybool.lib.SegmentSelector;
import polybool.lib.Intersecter;
import polybool.lib.Epsilon;

//https://github.com/velipso/polybooljs
class PolyBool {
    static var epsilon = new Epsilon();

    public static function epsilonFn(v:Float){
		return epsilon.epsilon(v);
	}

    public static function segments(poly:Poly):Segments {
		var i = new Intersecter(true, epsilon);
        for(r in poly.regions){
            i.addRegion(r);
        }
		return {
			segments: i.calculate(poly.inverted),
			inverted: poly.inverted
		};
	}

    public static function combine(segments1:Segments, segments2:Segments):CombinedSegments {
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

    public static function selectUnion(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.union(combined.combined),
			inverted: combined.inverted1 || combined.inverted2
		}
	}

    public static function selectIntersect(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.intersect(combined.combined),
			inverted: combined.inverted1 && combined.inverted2
		}
	}

    public static function selectDifference(combined:CombinedSegments):Segments {
		return {
			segments: SegmentSelector.difference(combined.combined),
			inverted: combined.inverted1 && !combined.inverted2
		}
	}

    public static function selectDifferenceRev(combined:CombinedSegments):Segments{
		return {
			segments: SegmentSelector.differenceRev(combined.combined),
			inverted: !combined.inverted1 && combined.inverted2
		}
	}

    public static function selectXor(combined:CombinedSegments):Segments{
		return {
			segments: SegmentSelector.xor(combined.combined),
			inverted: combined.inverted1 != combined.inverted2
		}
	}

    public static function polygon(segments:Segments):Poly{
		return {
			regions: SegmentChainer.chain(segments.segments, epsilon),
			inverted: segments.inverted
		};
	}

    public static function operate(poly1:Poly, poly2:Poly, selector:CombinedSegments->Segments):Poly {
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