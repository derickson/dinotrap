xquery version "1.0-ml";

(: Write Resource Handler - Busses  :)


import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace lb = "/lib/bus" at "/lib/l-bus.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";

declare namespace wmata = "http://www.wmata.com";

(: Need this so that transaction is an update query across the xdmp:apply :)
declare option xdmp:update "true" ;

declare variable $bus-position-static := (
  <BusPosition xmlns="http://www.wmata.com">
    <DateTime>2011-12-24T13:22:37</DateTime>
    <Deviation>-11.78</Deviation>
    <DirectionNum>1</DirectionNum>
    <DirectionText>EAST</DirectionText>
    <Lat>38.858879</Lat>
    <Lon>-77.051109</Lon>
    <RouteID>23A</RouteID>
    <TripEndTime>1753-01-01T13:11:00</TripEndTime>
    <TripHeadsign>CRYSTAL CITY</TripHeadsign>
    <TripID>5647_12</TripID>
    <TripStartTime>1753-01-01T11:50:00</TripStartTime>
    <VehicleID>2585</VehicleID>
  </BusPosition>,
<BusPosition xmlns="http://www.wmata.com">
    <DateTime>2011-12-24T13:18:18</DateTime>
    <Deviation>-20.18</Deviation>
    <DirectionNum>0</DirectionNum>
    <DirectionText>WEST</DirectionText>
    <Lat>38.958069</Lat>
    <Lon>-77.085167</Lon>
    <RouteID>32</RouteID>
    <TripEndTime>1753-01-01T13:03:00</TripEndTime>
    <TripHeadsign>FRIENDSHIP HEIGHTS STATION</TripHeadsign>
    <TripID>9765_12</TripID>
    <TripStartTime>1753-01-01T11:30:00</TripStartTime>
    <VehicleID>2210</VehicleID>
  </BusPosition>,

  <BusPosition xmlns="http://www.wmata.com">
    <DateTime>2011-12-24T13:18:18</DateTime>
    <Deviation>-20.18</Deviation>
    <DirectionNum>0</DirectionNum>
    <DirectionText>WEST</DirectionText>
    <Lat>38.979587</Lat>
    <Lon>-77.092959</Lon>
    <RouteID>32</RouteID>
    <TripEndTime>1753-01-01T13:03:00</TripEndTime>
    <TripHeadsign>TOTALLY FAKE</TripHeadsign>
    <TripID>9765_12</TripID>
    <TripStartTime>1753-01-01T11:30:00</TripStartTime>
    <VehicleID>99999999</VehicleID>
  </BusPosition>
  );



declare function local:clear-busses() {
    xdmp:collection-delete("busposition"),
    'Busses Cleared'
};

declare function local:poll() {
	let $busses := 
		if($cfg:POLL_WMATA) then
    		lb:get-bus-positions() 
		else
			$bus-position-static
			
    let $dinos := md:gen-or-move-wmata-dino($busses)
    return (
        md:output-format($dinos)
    )

};



try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }