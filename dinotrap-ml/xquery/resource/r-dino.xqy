xquery version "1.0-ml";

(: Read Resource Handler - Dino  :)

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";


declare function local:get-by-id() as element(md:dino) {
	let $dino := md:get-by-id(h:id())
	return
		if($dino) then
			$dino
		else
			fn:error(xs:QName("ER-NO-SUCH-OBJ"),"Database did not contain a Dino with that Id")
};

declare function local:get-by-wmata-id() as element(md:dino) {
	let $dino := md:get-by-wmata-id(h:id())
	return
		if($dino) then
			$dino
		else
			fn:error(xs:QName("ER-NO-SUCH-OBJ"),"Database did not contain a Dino with that Id")
};

declare function local:list() as element(list) {
	let $page-size := 10
	let $est := xdmp:estimate( /md:dino )
	let $page := lu:get-request-field-int("page", ())
	return
		if($page) then
			let $from := ($page - 1) * $page-size + 1
			let $to := $page * $page-size
			return
				element list {
					attribute estimated-pages { fn:string(xs:int(fn:ceiling( $est div $page-size))) },
					attribute estimated-items { $est },
					attribute page { $page },
					attribute items-per-page { $page-size },
					(/md:dino)[$from to $to]
				}
		else
			element list {
				attribute estimated-pages { fn:string(xs:int(fn:ceiling( $est div $page-size))) },
				attribute estimated-items { $est },
				attribute page { "1" },
				attribute items-per-page { $page-size },
				(/md:dino)[1 to 10]
			}
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }