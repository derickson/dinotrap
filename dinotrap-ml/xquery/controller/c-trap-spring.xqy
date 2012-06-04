xquery version "1.0-ml";

module namespace cts = "http://dinotrap.com/controller/trap-spring";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";
import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";
import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";

declare variable $LOG-LEVEL := "debug";

declare function cts:spring-trap(
	$trap-id as xs:string, 
	$survivor-id as xs:string, 
	$triggering-doc as node()) as empty-sequence() {
	
	lu:log(text{
		"Springing Trap for trap:",$trap-id,
		"survivor:",$survivor-id,
		"on object:",$triggering-doc//*:guid/fn:string()
	}, $LOG-LEVEL),
	
	let $surv := ms:get-by-id($survivor-id)
	let $trap := mt:get-by-id($trap-id)
	let $dino := md:get-by-id($triggering-doc//*:guid/fn:string())
	
	return (
		
		mt:delete($trap),
		ms:award-points($surv, 10),
		
		let $_ := xdmp:http-post(
			fn:concat($cfg:NODE_JS_LOCATION,"/receiveAlert"),
			<options xmlns="xdmp:http">
				<headers>
					<Content-type>application/json</Content-type>
				</headers>
		     </options>,
			text{
				json:serialize(
					json:object((
						"survivorId", $surv/ms:guid/fn:string(),
						"trapId", $trap/mt:guid/fn:string(),
						"dinoId", $dino/md:guid/fn:string(),
						"points", xs:int($surv/ms:points) + 10
					))
				)
			}
		)
		return
			()
		
	)
		

	
	
	
	
};