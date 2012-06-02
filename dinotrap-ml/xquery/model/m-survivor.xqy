xquery version "1.0-ml";

module namespace ms = "http://dinotrap.com/model/survivor";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";

declare namespace fg = "http://framework/geo";

declare variable $OBJECT_TYPE as xs:string := "survivor";
declare variable $STORAGE_PREFIX as xs:string := fn:concat("/storage/",$OBJECT_TYPE,"/");

declare variable $LOG-LEVEL as xs:string := "debug";

declare function ms:gen-survivor($name) as element(ms:survivor) {
	let $guid := lu:guid($OBJECT_TYPE)
	let $proc-name :=
		if(fn:matches($name, "^[\w\s\d]+$")) then
			fn:subsequence($name,1,20)
		else
			fn:error(xs:QName("ER-INVALID-NAME"),"ms:gen-survivor the name was invalid")
	return
		element ms:survivor{
			element ms:guid { $guid },
			element ms:name { $proc-name },
			element ms:points { 0 }
		}
};

declare function ms:get-by-id($id as xs:string) as element(ms:survivor)? {
	/ms:survivor[ms:guid eq $id]
};

declare function ms:get-by-name($name as xs:string) as element(ms:survivor)? {
	/ms:survivor[ms:name eq $name]
};

declare function ms:name-taken($name as xs:string) as xs:boolean {
	fn:exists( /ms:survivor[ms:name eq $name] )
};

declare function ms:award-points($item as element(ms:survivor), $points as xs:int) as empty-sequence() {
	let $new-points := xs:int($item/ms:points) + $points
	let $_ := lu:log(text{
				"Awardning points survivor:",$item/ms:name/fn:string(), 
				"old:",fn:string($item/ms:points),
				"new:",fn:string($new-points)
			},$LOG-LEVEL)
	return
		xdmp:node-replace($item/ms:points, element ms:points { $new-points } )
};

declare function ms:store($item as element(ms:survivor)) as empty-sequence() {
	let $_ := if(ms:name-taken($item/ms:name/fn:string())) then 
			fn:error(xs:QName("ER-NAME-TAKEN"),"ms:store then requested name was already taken")
		else
			()
	let $uri := fn:concat($STORAGE_PREFIX, $item/ms:guid/fn:string(), ".xml")
	return
		xdmp:document-insert($uri, $item, (), ($OBJECT_TYPE))
};

declare function ms:status() as element()* {
	element survivor-status {
		element count { xdmp:estimate( fn:collection($OBJECT_TYPE) ) }
	}
};

declare function ms:delete($item as element(ms:survivor)?) as empty-sequence() {
	if($item) then (
		for $t in /mt:trap[mt:survivor-guid eq $item/ms:guid]
		return
			mt:delete($t),
			
		xdmp:document-delete(xdmp:node-uri($item))
	)
	else
		()
};

declare function ms:purge() as empty-sequence() {
	for $i in fn:collection($OBJECT_TYPE)/ms:survivor
	return (
		for $t in /mt:trap[mt:survivor-guid eq $i/ms:guid]
		return
			mt:delete($t),
		xdmp:document-delete(xdmp:node-uri($i))
	)
		
};