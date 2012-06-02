xquery version "1.0-ml" ;

(:  
	rewrite.xqy
    This application uses the rewrite Open Source project for RESTful URL rewriting in MarkLogic
    https://github.com/dscape/rewrite
:)

import module namespace r = "routes.xqy" at "/lib/rewrite/routes.xqy";
import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";

import module namespace c-rest="http://marklogic.com/appservices/rest" at "/lib/corona/corona/lib/rest/rest.xqy";
import module namespace c-endpoints="http://marklogic.com/corona/endpoints" at "/lib/corona/config/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";

declare variable $LOG-LEVEL as xs:string := "fine";

    (: let rewrite library determine destination URL, use routes configuration in config lib :)
    let $selected-url    := r:selectedRoute( $cfg:ROUTES )
    let $_ := xdmp:log(text{"Rewrite target:",$selected-url},$LOG-LEVEL)
    return

		(: BEGIN TEST Library Rewrite :)
        let $url := $selected-url
        let $path :=   xdmp:get-request-path() (:fn:substring-before($selected-url,"?"):)
        let $params := fn:substring-after($selected-url, "?")[. ne ""]
        return
          if ($cfg:TEST_ENABLED and fn:matches($url, "^/test$")) then
          (
            $url
          )
          else if ($cfg:TEST_ENABLED and fn:matches($url, "^/test/")) then
            if (fn:matches($url, "(_js|_img|_css)")) then $url
            else
              let $func := (fn:tokenize($path, "/")[3][. ne ""], "main")[1]
              return
                fn:concat("/test/default.xqy?func=", $func, if ($params) then concat("&amp;", $params) else ())
		(: END TEST Library Rewrite :)

      	else if($cfg:CORONA_ENABLED and fn:matches(xdmp:get-request-url(), "^/corona")) then (

			let $url := xdmp:get-request-url()
			let $result := c-rest:rewrite(c-endpoints:options())
			let $_ := xdmp:log(text{"Corono: ",$result})
			
			return
			    if(exists($result))
			    then $result
			    else if(starts-with($url, "/test") or starts-with($url, "/corona/htools/"))
			    then $url
			    else concat("/corona/misc/404.xqy?", substring-after(xdmp:get-request-url(), "?"))
		    
			)

		else
        
            $selected-url
        