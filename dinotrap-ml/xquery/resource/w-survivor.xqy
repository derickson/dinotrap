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
				ms:output-format($survivor)
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
			(: 0.142045455 mile = 250 yards :)
			let $trap := mt:gen-survivor-trap($survivor/ms:guid/fn:string(), $point, 0.142045455)
			return(
				mt:store($trap),
				mt:output-format($trap)
			)	
			
		else
			fn:error(xs:QName("ER-BAD-INPUT"),"driver survivor-placetrap")
};

declare function local:delete-by-id() {
	ms:delete( ms:get-by-id(h:id()))
};

declare function local:purge() {
	if(lu:confirm-purge()) then
		ms:purge()
	else
		<ms:confirm-purge>You need to put in a special command to purge.  This will delete data.</ms:confirm-purge>
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }