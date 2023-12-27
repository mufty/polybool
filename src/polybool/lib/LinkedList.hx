package polybool.lib;

import polybool.lib.Types.NodeData;
import polybool.lib.Types.Transition;
import polybool.lib.Types.Node;

class LinkedList {
    var root:Node;

    public function new(){

    }

    public function exists(node){
        if (node == null || node == this.root)
            return false;
        return true;
    }

    public function isEmpty(){
        return root.next == null;
    }

    public function getHead(){
        return root.next;
    }

    public function insertBefore(node:Node, check){
        var last = root;
        var here = root.next;
        while (here != null){
            if (check(here)){
                node.prev = here.prev;
                node.next = here;
                here.prev.next = node;
                here.prev = node;
                return;
            }
            last = here;
            here = here.next;
        }
        last.next = node;
        node.prev = last;
        node.next = null;
    }

    public function findTransition(check):Transition{
        var prev = root;
        var here = root.next;
        while (here != null){
            if (check(here))
                break;
            prev = here;
            here = here.next;
        }
        return {
            before: prev == root ? null : prev,
            after: here,
            insert: function(node){
                node.prev = prev;
                node.next = here;
                prev.next = node;
                if (here != null)
                    here.prev = node;
                return node;
            }
        };
    }

    public static function create():LinkedList {
        var ret = new LinkedList();
        ret.root = new Node(true);
        return ret;
    }

    public static function node(data:NodeData):Node {
		/*data.prev = null;
		data.next = null;
		data.remove = function(){
			data.prev.next = data.next;
			if (data.next != null)
				data.next.prev = data.prev;
			data.prev = null;
			data.next = null;
		};*/

        var node = new Node(false);
        node.isStart = data.isStart;
        node.next = null;
        node.other = data.other;
        node.prev = null;
        node.primary = data.primary;
        node.pt = data.pt;
        node.remove = function(){
			node.prev.next = node.next;
			if (node.next != null)
				node.next.prev = node.prev;
			node.prev = null;
			node.next = null;
		};
        node.seg = data.seg;
        node.status = data.status;
		return node;
	}
}