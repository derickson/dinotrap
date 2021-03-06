xquery version "1.0-ml" ;

(:  config.xqy
    This library module holds configuration variables for the application
:)

module  namespace cfg = "http://framework/lib/config";

declare variable $NODE_JS_LOCATION := "http://dinotrap.jit.su"  ; (:  "http://dinotrap.jit.su" :)
declare variable $PRODUCTION_SETTINGS := fn:false();
declare variable $TEST_ENABLED := fn:not($PRODUCTION_SETTINGS);
declare variable $CORONA_ENABLED := fn:false();
declare variable $CENTRALIZED_LOG_ENABLED := fn:true();
declare variable $POLL_WMATA := fn:true();
declare variable $NEAR_ME_DIST := 1;

(:  The rewrite library route configuration 
    For documentation see: https://github.com/dscape/rewrite 
:)
declare variable $ROUTES :=
    <routes>
        
		<root>page#status</root>
		
		<get path="earth"><to>page#earth</to></get>
		<get path="status.kml"><to>page#kml</to></get>
		
		<get path="status"><to>page#status</to></get>
		
		
		<get path="dino"><to>r-dino#list</to></get>
		<get path="dino/page/:page"><to>r-dino#list</to></get>
		<get path="dino/purge"><to>w-dino#purge</to></get>
		<get path="dino/:id"><to>r-dino#get-by-id</to></get>
		<get path="dino/wmata/:id"><to>r-dino#get-by-wmata-id</to></get>
		<delete path="dino/:id"><to>w-dino#delete-by-id</to></delete>
		<put path="dino/:lat,:lon"><to>w-dino#new</to></put>
		<put path="dino/:id/:lat,:lon">
			<constraints>
				<lat type="double"/>
				<lon type="double"/>
			</constraints>
			<to>w-dino#move</to>
		</put>
		
		<get path="trap"><to>r-trap#list</to></get>
		<get path="trap/page/:page"><to>r-trap#list</to></get>
		<get path="trap/purge"><to>w-trap#purge</to></get>
		<get path="trap/:id"><to>r-trap#get-by-id</to></get>
		
		<get path="survivor"><to>r-survivor#list</to></get>
		<get path="survivor/page/:page"><to>r-survivor#list</to></get>
		<get path="survivor/purge"><to>w-survivor#purge</to></get>
		<get path="survivor/:id"><to>r-survivor#get-by-id</to></get>
		<delete path="survivor/:id"><to>w-survivor#delete-by-id</to></delete>
		<put path="survivor/:name"><to>w-survivor#new</to></put>
		<put path="survivor/:id/trap/:lat,:lon">
			<constraints>
				<lat type="double"/>
				<lon type="double"/>
			</constraints>
			<to>w-survivor#trap</to>
		</put>
		<get path="survivor/:id/nearMe/:lat,:lon">
			<constraints>
				<lat type="double"/>
				<lon type="double"/>
			</constraints>
			<to>r-survivor#near</to>
		</get>

		<get path="poll/dc"><to>w-busses#poll</to></get>


		{if($CORONA_ENABLED) then <ignore>^/corona</ignore> else () }
        {if($TEST_ENABLED) then <ignore>^/test</ignore> else ()}
    </routes>;

    

(: controlled collections :)
declare variable $SETS_OFF_TRAPS as xs:string := "sets-off-traps";
