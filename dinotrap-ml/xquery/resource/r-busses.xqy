xquery version "1.0-ml";

(: Read Resource Handler - Busses  :)


import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lb = "/lib/bus" at "/lib/l-bus.xqy";

declare namespace wmata = "http://www.wmata.com";


declare function local:recall() {
    let $busses := lb:recall-busses()
    return (
        lb:busses-to-json($busses)
    )
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }