xquery version "1.0-ml";

(: Write Resource Handler - Dino  :)


import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";
import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";

(: Need this so that transaction is an update query across the xdmp:apply :)
declare option xdmp:update "true" ;

declare function local:new() {
	let $name := xdmp:get-request-field("name",())
	return
		if($name) then
			let $survivor := ms:gen-survivor($name)
			return (
				ms:store($survivor),
				$survivor
			)
		else
			fn:error(xs:QName("ER-BAD-INPUT"),"driver spawn-survivor I need a name")
};

declare function local:trap() {
	let $lat := lu:get-request-field-double("lat", ())
	let $lon := lu:get-request-field-double("lon", ())
	let $survivor := ms:get-by-id(h:id())
	return
		if($lat and $lon and $survivor) then
			
			let $point := cts:point($lat, $lon)
			(: 0.0284090909 mile = 50 yards :)
			let $trap := mt:gen-survivor-trap($survivor/ms:guid/fn:string(), $point, 0.0284090909)
			return(
				mt:store($trap),
				$trap
			)	
			
		else
			fn:error(xs:QName("ER-BAD-INPUT"),"driver survivor-placetrap")
};

declare function local:delete-by-id() {
	ms:delete( ms:get-by-id(h:id()))
};

declare function local:purge() {
	ms:purge()
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }