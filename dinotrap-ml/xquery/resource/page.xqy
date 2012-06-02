xquery version "1.0-ml";

(: Page Resource  :)

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";
import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";
import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";


declare function local:status() {
    element status {
		md:status(),
		mt:status(),
		ms:status()
	}
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }