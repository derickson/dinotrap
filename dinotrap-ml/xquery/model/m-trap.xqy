xquery version "1.0-ml";

module namespace mt = "http://dinotrap.com/model/trap";

import module namespace alert = "http://marklogic.com/xdmp/alert" 
		  at "/MarkLogic/alert.xqy";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

declare namespace fg = "http://framework/geo";

declare variable $OBJECT_TYPE as xs:string := "trap";
declare variable $STORAGE_PREFIX as xs:string := fn:concat("/storage/",$OBJECT_TYPE,"/");

declare function mt:guid-rule-name($trap as element(mt:trap)) as xs:string {
	fn:concat("rule-for-",$trap/mt:guid/fn:string())
};

declare function mt:gen-trap($point as cts:point, $distance as xs:double) as element(mt:trap) {
	mt:gen-survivor-trap((), $point, $distance)
};

declare function mt:gen-survivor-trap($surv-id as xs:string?, $point as cts:point, $distance as xs:double) as element(mt:trap) {
	let $guid := lu:guid($OBJECT_TYPE)
	let $circle := cts:circle($distance, $point)
	let $query := 
		cts:and-query((
			cts:collection-query($cfg:SETS_OFF_TRAPS),
			cts:element-geospatial-query( (xs:QName("fg:location"),xs:QName("fg:trail")), $circle , ("coordinate-system=wgs84"))
		))
	return
		element mt:trap{
			element mt:guid { $guid },
			if($surv-id) then element mt:survivor-guid { $surv-id } else (),
			element fg:location { fn:string($point) },
			element fg:distance { $distance },
			element fg:region { $circle },
			element fg:query { $query }
		}
};

declare function mt:get-by-id($id as xs:string) as element(mt:trap)? {
	/mt:trap[mt:guid eq $id]
};

declare function mt:store($item as element(mt:trap)) as empty-sequence() {
	let $uri := fn:concat($STORAGE_PREFIX, $item/mt:guid/fn:string(), ".xml")
	let $rule := alert:make-rule(
	    mt:guid-rule-name($item), 
	    "trap rule",
	    0, (: equivalent to xdmp:user(xdmp:get-current-user()) :)
	    cts:query($item//fg:query/node()),
	    "survivor-trap",
	    <alert:options>
		{
			$item/mt:guid,
			$item/mt:survivor-guid
		}
		</alert:options>
	 )
	return (
		xdmp:document-insert($uri, $item, (), ($OBJECT_TYPE)),
		alert:rule-insert("/alert/config/dino-trap.xml", $rule)
	)

		
};

declare function mt:delete($item as element(mt:trap)) as empty-sequence() {
	let $rule-name := mt:guid-rule-name($item)
	let $rule-id := xs:unsignedLong( (/alert:rule[alert:name eq $rule-name])[1]/@id )
	return
		alert:rule-remove("/alert/config/dino-trap.xml", $rule-id),
		
	xdmp:document-delete(xdmp:node-uri($item))
};

declare function mt:status() as element()* {
	element trap-status {
		element count { xdmp:estimate( fn:collection($OBJECT_TYPE) ) }
	}
};

declare function mt:purge() as empty-sequence() {
	for $i in fn:collection($OBJECT_TYPE)/mt:trap
	return
		mt:delete($i)
};