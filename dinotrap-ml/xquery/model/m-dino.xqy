xquery version "1.0-ml";

module namespace md = "http://dinotrap.com/model/dino";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";
import module namespace lb = "/lib/bus" at "/lib/l-bus.xqy";


declare namespace fg = "http://framework/geo";
declare namespace wmata = "http://www.wmata.com";

declare variable $OBJECT_TYPE as xs:string := "dino";
declare variable $STORAGE_PREFIX as xs:string := fn:concat("/storage/",$OBJECT_TYPE,"/");

declare function md:gen-or-move-wmata-dino($busses as element(wmata:BusPosition)*) as element(md:dino)* {
	for $bus in $busses 
	let $wmata-id := lb:wmata-id-from-bus($bus)
	let $wmata-point := lb:point-from-bus($bus)
	let $existing := md:get-by-wmata-id($wmata-id)
	return
		if($existing) then
			md:move($existing, $wmata-point)
		else
			
			let $guid := lu:guid($OBJECT_TYPE)
			let $new-dino :=
				element md:dino {
					element md:guid { $guid },
					element md:wmata-id { $wmata-id } ,
					element md:position {
						element fg:location { fn:string($wmata-point) }
					}
				}
			return (
				md:store($new-dino),
				$new-dino
			)
};

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

declare function md:move($item as element(md:dino), $point as cts:point) as element(md:dino) {
	let $old-point := cts:point($item/md:position/fg:location/fn:string())
	let $new-history := ( element fg:history { fn:string($old-point)}, ($item/md:position/fg:history)[1 to 4] )
	
	let $moved-dino :=
		element md:dino {
			$item/md:guid,
			$item/md:wmata-id,
			element md:position { 
				element fg:location { fn:string($point) },
				
				(: 0.00568181818 miles = 10 yards, traps will have radius 50 yards :)
				for $trail-point in lu:interpolation($old-point, $point, 0.00568181818) 
				return
					element fg:trail { fn:string($trail-point) },
				
				$new-history
			}
		}
	
	return (
		md:store($moved-dino),
		$moved-dino
	)
		
	(:
		xdmp:node-replace($item/md:position, 
			element md:position { 
				element fg:location { fn:string($point) },
				
				for $trail-point in lu:interpolation($old-point, $point, 0.00568181818) 
				return
					element fg:trail { fn:string($trail-point) },
				
				$new-history
			}
		)
	:)
};

declare function md:get-by-id($id as xs:string) as element(md:dino)? {
	/md:dino[md:guid eq $id]
};

declare function md:get-by-wmata-id($id as xs:string) as element(md:dino)? {
	/md:dino[md:wmata-id eq $id]
};

declare function md:store($item as element(md:dino)) as empty-sequence() {
	let $uri := fn:concat($STORAGE_PREFIX, $item/md:guid/fn:string(), ".xml")
	return
		xdmp:document-insert($uri, $item, (), ($OBJECT_TYPE, $cfg:SETS_OFF_TRAPS))
};


declare function md:output-format($items as element(md:dino)*) as item()* {
	if(xdmp:get-request-field("format") eq "json") then (
		xdmp:set-response-content-type("application/json"),
		json:serialize( 
			json:object((
				"dinos", json:array(( 
					md:to-json($items) 
				))
			))	
		)
	) else
		element md:dinos { $items }
};

declare function md:to-json($items as element(md:dino)*) as item()* {
	
		
				for $item in $items
				let $parts := fn:tokenize($item/md:position/fg:location/fn:string(),",")
				return
					json:object((
						"id", $item/md:guid/fn:string(),
						"lat", $parts[1],
						"lon", $parts[2]
					))
			
	
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