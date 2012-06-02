xquery version "1.0-ml";

(: Read Resource Handler - survivor  :)

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";


declare function local:get-by-id() as element(ms:survivor) {
	let $survivor := ms:get-by-id(h:id())
	return
		if($survivor) then
			$survivor
		else
			fn:error(xs:QName("ER-NO-SUCH-OBJ"),"Database did not contain a survivor with that Id")
};

declare function local:list() as element(list) {
	let $page-size := 10
	let $est := xdmp:estimate( /ms:survivor )
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
					(/ms:survivor)[$from to $to]
				}
		else
			element list {
				attribute estimated-pages { fn:string(xs:int(fn:ceiling( $est div $page-size))) },
				attribute estimated-items { $est },
				attribute page { "1" },
				attribute items-per-page { $page-size },
				(/ms:survivor)[1 to 10]
			}
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }