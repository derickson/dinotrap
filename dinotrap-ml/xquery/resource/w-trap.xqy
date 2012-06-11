xquery version "1.0-ml";

(: Write Resource Handler - Trap  :)


import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lu = "http://framework/lib/util" at "/lib/l-util.xqy";

import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";

(: Need this so that transaction is an update query across the xdmp:apply :)
declare option xdmp:update "true" ;


declare function local:purge() {
	
	if(lu:confirm-purge()) then
		mt:purge()
	else
		<mt:confirm-purge>You need to put in a special command to purge.  This will delete data.</mt:confirm-purge>
	
	
};

try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }