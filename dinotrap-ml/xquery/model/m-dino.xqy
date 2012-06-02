xquery version "1.0-ml";

module namespace md = "http://dinotrap.com/model/dino";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

declare namespace fg = "http://framework/geo";

declare variable $OBJECT_TYPE as xs:string := "dino";
declare variable $STORAGE_PREFIX as xs:string := fn:concat("/storage/",$OBJECT_TYPE,"/");

declare function md:gen-dino($point as cts:point) as element(md:dino) {
	let $guid := lu:guid($OBJECT_TYPE)
	return
		element md:dino{
			element md:guid { $guid },
			element md:position {
				element fg:location { fn:string($point) }
			}
		}
};

declare function md:move($item as element(md:dino), $point as cts:point) as empty-sequence() {
	let $old-point := cts:point($item/md:position/fg:location/fn:string())
	let $new-history := ( element fg:history { fn:string($old-point)}, ($item/md:position/fg:history)[1 to 4] )
	return
		xdmp:node-replace($item/md:position, 
			element md:position { 
				element fg:location { fn:string($point) },
				
				(: 0.00568181818 miles = 10 yards, traps will have radius 50 yards :)
				for $trail-point in lu:interpolation($old-point, $point, 0.00568181818) 
				return
					element fg:trail { fn:string($trail-point) },
				
				$new-history
			}
		)
};

declare function md:get-by-id($id as xs:string) as element(md:dino)? {
	/md:dino[md:guid eq $id]
};

declare function md:store($item as element(md:dino)) as empty-sequence() {
	let $uri := fn:concat($STORAGE_PREFIX, $item/md:guid/fn:string(), ".xml")
	return
		xdmp:document-insert($uri, $item, (), ($OBJECT_TYPE, $cfg:SETS_OFF_TRAPS))
};

declare function md:status() as element()* {
	element dino-status {
		element count { xdmp:estimate( fn:collection($OBJECT_TYPE) ) }
	}
};

declare function md:delete($item as element(md:dino)?) as empty-sequence() {
	if($item) then
		xdmp:document-delete(xdmp:node-uri($item))
	else
		()
};

declare function md:purge() as empty-sequence() {
	xdmp:collection-delete($OBJECT_TYPE)
};