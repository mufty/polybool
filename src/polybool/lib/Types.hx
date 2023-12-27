package polybool.lib;

import uuid.Uuid;

typedef Point = {
    x:Float,
    y:Float
};

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

typedef Fill = {
    above:Null<Bool>,
    below:Null<Bool>
};

typedef Segment = {
    var id:String;
    var start:Point;
    var end:Point;
    var myFill:Fill;
    var otherFill:Fill;
}

typedef NodeData = {
    isStart:Bool,
    pt:Point,
	seg:Segment,
    primary:Bool,
    other:Node,
    status:Node
};

typedef Transition = {
    before:Node,
    after:Node,
    insert:Node->Node
}

@:struct class Node {
    public static final DEFAULT_SEGMENT:Segment ={
        id: null,
        start: null,
        end: null,
        myFill: {
            above: false, // is there fill above us?
            below: false  // is there fill below us?
        },
        otherFill: null
    };
    public var next:Node;
    public var prev:Node;
    public var root:Bool;
    public var remove:Void->Void;
    // nothing to implement, a macro automatically creates the necessary fields
    public var isStart:Bool;
    public var pt:Point;
	public var seg:Segment;
    public var primary:Bool;
    public var other:Node;
    public var status:Node;
    public var id:String;

    public inline function new(root:Bool, ?isStart:Bool, ?pt:Point, ?seg:Segment, ?primary:Bool, ?other:Node, ?status:Node){
        this.id = Uuid.nanoId();
        this.root = root;
        this.isStart = isStart;
        this.pt = pt;
        this.seg = seg;
        this.primary = primary;
        this.other = other;
        this.status = status;
    }
}