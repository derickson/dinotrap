xquery version "1.0-ml";

module namespace cts = "http://dinotrap.com/controller/trap-spring";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

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
		ms:award-points($surv, 10)
	)
		

	
	
	
	
};