xquery version "1.0-ml";

module namespace lu = "http://framework/lib/util";

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";

declare function lu:guid($objectType as xs:string) as xs:string {
	if($objectType) then
		let $rand := xdmp:random()
		let $time := fn:current-dateTime()
		let $text := fn:string-join((fn:string($rand), $objectType, fn:string($time))," ")
		return
			fn:concat($objectType,"-",xdmp:hash64($text))
	else
		fn:error(xs:QName("ER-BAD-INPUT"),"lu:guid $objectType requires non blank string")
};


declare function lu:get-request-field-double($name as xs:string, $default as xs:double?) as xs:double? {
	let $str := xdmp:get-request-field($name, ())
	return
		if($str castable as xs:double) then
			xs:double($str)
		else
			$default
};

declare function lu:get-request-field-int($name as xs:string, $default as xs:int?) as xs:int? {
	let $str := xdmp:get-request-field($name, ())
	return
		if($str castable as xs:int) then
			xs:int($str)
		else
			$default
};

declare function lu:log($text as xs:string, $log-level as xs:string) {
	if($cfg:CENTRALIZED_LOG_ENABLED) then
		xdmp:log($text, $log-level)
	else
		()
};

declare function lu:interpolation($a as cts:point, $b as cts:point, $step-distance as xs:double) as cts:point* {
	if($a eq $b or $step-distance le 0.0) then
		()
	else
		let $distance := cts:distance($a, $b)
		let $bearing := cts:bearing($a, $b)
		let $steps := xs:int(fn:floor( $distance div $step-distance ))
		return
		   for $i in (1 to $steps)
		   return
		   cts:destination($a, $bearing, $step-distance * $i)
};