xquery version "1.0-ml";

(: Page Resource  :)

import module namespace cfg = "http://framework/lib/config" at "/lib/config.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace md = "http://dinotrap.com/model/dino" at "/model/m-dino.xqy";
import module namespace mt = "http://dinotrap.com/model/trap" at "/model/m-trap.xqy";
import module namespace ms = "http://dinotrap.com/model/survivor" at "/model/m-survivor.xqy";

declare namespace kml = "http://www.opengis.net/kml/2.2";
declare namespace fg = "http://framework/geo";

declare option xdmp:output "indent=no";

declare function local:status() {
    element status {
		md:status(),
		mt:status(),
		ms:status()
	}
};

declare function local:earth() {
	xdmp:set-response-content-type("text/html; charset=UTF-8"),
	'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
	<html xmlns="http://www.w3.org/1999/xhtml">
	    <head>
	        <title>DinoTrap Dashboard</title>
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
			<script type="text/javascript" src="https://www.google.com/jsapi"></script>
			<script type="text/javascript" src="/js/earth.js"></script>
            <link type="text/css" rel="stylesheet" href="/css/earth.css"></link>
	    </head>
	    <body>
	    	<div id="map3d" style="height: 100%; width: 100%;"></div>
	    </body>
	</html>
};

declare function local:kml() {
xdmp:set-response-content-type("application/vnd.google-earth.kml+xml"),	
<kml xmlns="http://www.opengis.net/kml/2.2">
	<Document>
		<name>DinoTrap Status</name>
		<open>1</open>
		<Style id="dino">
	      <IconStyle>
	        <Icon>
	          <href>http://dinotrap.jit.su/images/trex-highcontrast.png</href>
	        </Icon>
	      </IconStyle>
	    </Style>
			<Style id="circle">
		      <LineStyle>
		        <width>1.5</width>aabbggrr
			        <color>ffffff00</color>
		      </LineStyle>
		      <PolyStyle>
		        <color>88ff0000</color>
		      </PolyStyle>
		    </Style>
		
			
			<Style id="trail">
		      <LineStyle>
		        <width>2</width>
			        <color>ff0000ff</color>
		      </LineStyle>
		    </Style>
			
		
			<ScreenOverlay id="ID">
				<Icon>
					<href>https://localhost:9056/images/DinoTrapOverlay.jpg</href>
				</Icon>
				<overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
			  	<screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
			    <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
			    <size x="0" y="0" xunits="fraction" yunits="fraction"/>
			</ScreenOverlay>
	
		
		{ 
			for $dino in /md:dino
			let $location := $dino//fg:location/fn:string()
			let $parts := fn:tokenize($location,",")
			let $history := ($dino//fg:history/fn:string())[1 to 2]
			return (
				<Placemark>
			      	<styleUrl>#dino</styleUrl>
					<Point>
						<coordinates>{$parts[2]},{$parts[1]},0</coordinates>
					</Point>
				</Placemark>,
				
				if($history) then
					<Placemark>
				      	<styleUrl>#trail</styleUrl>
						<visibility>1</visibility>
				        <altitudeMode>clampToGround</altitudeMode>
						<LineString>
							<coordinates>
							{
								fn:string-join((
									for $point in ($location, $history)
									let $coord :=  fn:tokenize( $point , "," )
									return
										fn:string-join(($coord[2], $coord[1], "0"), ",")
								), " ")
							}
							</coordinates>
						</LineString>
					</Placemark>
				else
					()
			)
			
		}
		
		{
			let $pi := 3.1415926535897932384626433
			let $twopi := 6.283185307179586
			let $x := 18
			for $trap in /mt:trap
			let $location := $trap//fg:location/fn:string()
			let $center := cts:point($location)
			let $radius := xs:double( $trap//fg:distance)
			
			return
			
			<Placemark>
				<visibility>1</visibility>
				<styleUrl>#circle</styleUrl>
				
		      <Polygon>
		        <!--extrude>1</extrude-->
		        <altitudeMode>clampToGround</altitudeMode>
		        <outerBoundaryIs>
		
				<LinearRing>
				            <coordinates>
							{
								fn:string-join((
									for $i in (0 to 180)
									let $bearing := $twopi div 180 * xs:double($i)
									let $point := cts:destination($center, $bearing, $radius)
									return
										fn:string-join((fn:string(cts:point-longitude($point)), fn:string(cts:point-latitude($point)), "0"), ",")
								)," ")
							}
				            </coordinates>
				          </LinearRing>
				        </outerBoundaryIs>
				      </Polygon>
				
			</Placemark>
			
		}
		
	</Document>
</kml>
	
};


try          { xdmp:apply( h:function() ) }
catch ( $e ) {  h:error( $e ) }