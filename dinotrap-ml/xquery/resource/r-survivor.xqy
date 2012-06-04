xquery version "1.0-ml";

(: Read Resource Handler - survivor  :)

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";

import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";
import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";
import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";

declare namespace fg = "http://framework/geo";


declare function local:near() {
	let $_ := xdmp:log("NEAR ME REQEST RECEIVED!","debug")
	let $lat := lu:get-request-field-double("lat", ())
	let $lon := lu:get-request-field-double("lon", ())
	let $survivor := ms:get-by-id(h:id())
	
	return
		if($lat and $lon and $survivor) then
			let $_ := lu:log( text{"NearMe ", $lat," ",$lon} ,"debug")
			let $point := cts:point($lat, $lon)
			let $circle := cts:circle( $cfg:NEAR_ME_DIST , $point)
			let $query := 
				cts:element-geospatial-query( 
					(xs:QName("fg:location")), 
					$circle , 
					("coordinate-system=wgs84")
				)
			let $dinos := (cts:search( /md:dino , $query ))[1 to 50]
			let $traps := (cts:search( /mt:trap , $query ))[1 to 50]
			return
				if(xdmp:get-request-field("format") eq "json") then (
					xdmp:set-response-content-type("application/json"),
					json:serialize( 
						json:object((
							"dinos", json:array(( 
								md:to-json($dinos) 
							)),
							"traps", json:array(( 
								mt:to-json($traps) 
							))
						))	
					)
				) else
					element ms:nearMe {
						element md:dinos { $dinos },
						element mt:traps { $traps }
					}
			
		else
			fn:error(xs:QName("ER-BAD-INPUT"),"r-survivor nearMe") 
};

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