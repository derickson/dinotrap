xquery version "1.0-ml";

(: Write Resource Handler - Dino  :)


import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";

(: Need this so that transaction is an update query across the xdmp:apply :)
declare option xdmp:update "true" ;

declare function local:new() {
	let $lat := lu:get-request-field-double("lat", ())
	let $lon := lu:get-request-field-double("lon", ())
	let $point := if($lat and $lon) then
		cts:point($lat, $lon)
	else
		fn:error(xs:QName("ER-BAD-INPUT"), "dino new lat/lon was invalid")
	
	return
		let $dino := md:gen-dino($point)
		return (
			md:store($dino),
			$dino
		)
};

declare function local:move() {
	let $id := h:id()
	let $dino := md:get-by-id($id)
	return
		if($dino) then
			let $lat := lu:get-request-field-double("lat", ())
			let $lon := lu:get-request-field-double("lon", ())
			let $point := if($lat and $lon) then
				cts:point($lat, $lon)
			else
				fn:error(xs:QName("ER-BAD-INPUT"), "dino move lat/lon was invalid")
			return
				md:move($dino, $point)
		else
			fn:error(xs:QName("ER-BAD-INPUT"), "dino move id invalid")
};

declare function local:delete-by-id() {
	md:delete( md:get-by-id(h:id()))
};
 
declare function local:purge() {
	md:purge()
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }