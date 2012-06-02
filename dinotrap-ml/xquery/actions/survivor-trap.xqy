xquery version "1.0-ml";

import module namespace cts = "http://dinotrap.com/controller/trap-spring" 
	at "/controller/c-trap-spring.xqy";

declare namespace mt = "http://dinotrap.com/model/trap";
declare namespace alert = "http://marklogic.com/xdmp/alert";

(: declare variable $alert:config-uri as xs:string external; :)
declare variable $alert:doc as node() external;
declare variable $alert:rule as element(alert:rule) external;
(: declare variable $alert:action as element(alert:action) external; :)

cts:spring-trap(
	$alert:rule//alert:options/mt:guid/fn:string(),
	$alert:rule//alert:options/mt:survivor-guid/fn:string(),
	$alert:doc
)

