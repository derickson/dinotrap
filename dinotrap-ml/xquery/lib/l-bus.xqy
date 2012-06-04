xquery version "1.0-ml" ;

module namespace lb = "/lib/bus";

import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";

declare namespace wmata = "http://www.wmata.com";

declare variable $api-key := "4pu4tjvxxaf88vsbf8vcze5w"; 

declare function lb:get-bus-positions() as element(wmata:BusPosition)* {

    let $url := fn:concat(
        "http://api.wmata.com/Bus.svc/BusPositions?includingVariations=true&amp;api_key=",$api-key
    )
    
    let $get := xdmp:http-get($url)
    return
        if($get[1]//*:code eq 200) then
            $get[2]//wmata:BusPosition
        else (
            xdmp:log(xdmp:quote($get[1]), "error"),
			fn:error(xs:QName("ER-PUBLIC-API"),"something went wrong calling a public api")
        )

};

declare function lb:busses-to-json($busses as element(wmata:BusPosition)* ) {

    json:serialize(
        json:array(
            for $bus in $busses
            return json:object((
                "id", lb:wmata-id-from-bus($bus),
                "lat", xs:decimal( $bus/wmata:Lat/text() ),
                "lon", xs:decimal( $bus/wmata:Lon/text() )
            ))
        )
    )

};

declare function lb:wmata-id-from-bus($bus as element(wmata:BusPosition)) as xs:string {
	fn:concat("wmata-",  $bus/wmata:VehicleID/text() )
};

declare function lb:point-from-bus($bus as element(wmata:BusPosition)) as cts:point {
	cts:point( xs:double($bus/wmata:Lat), xs:double($bus/wmata:Lon) )
};

declare function lb:store-busses($busses as element(wmata:BusPosition)* ) as empty-sequence() {
	()
	(:
    for $bus in $busses
    let $id := fn:concat("wmata-", $bus/wmata:VehicleID/text() )
    return
        xdmp:document-insert( fn:concat("/busses/",$id,".xml"),$bus, (), "busposition")
	:)
};

declare function lb:recall-busses() as element(wmata:BusPosition)* {
	()
    (: fn:collection("busposition")/wmata:BusPosition :)
};
