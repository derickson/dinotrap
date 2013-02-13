xquery version "1.0-ml";
import module namespace alert = "http://marklogic.com/xdmp/alert" 
		  at "/MarkLogic/alert.xqy";
		
let $config := alert:make-config(
      "/alert/config/dino-trap.xml",
      "Dino Trap App",
      "Alerting config for Dino Trap",
        <alert:options/> )
return
	alert:config-insert($config);
	
xquery version "1.0-ml";
import module namespace alert = "http://marklogic.com/xdmp/alert" 
		  at "/MarkLogic/alert.xqy";

let $action := alert:make-action(
    "survivor-trap", 
    "Fire off the survivor trap",
    xdmp:modules-database(),
    xdmp:modules-root(), 
    "/actions/survivor-trap.xqy",
    <alert:options/> )
return
alert:action-insert("/alert/config/dino-trap.xml", $action);

xquery version "1.0-ml";
import module namespace alert = "http://marklogic.com/xdmp/alert" 
	at "/MarkLogic/alert.xqy";
import module namespace trgr="http://marklogic.com/xdmp/triggers"
	at "/MarkLogic/triggers.xqy";

 let $uri := "/alert/config/dino-trap.xml"
 let $trigger-ids :=
   alert:create-triggers (
       $uri,
       trgr:trigger-data-event(
           trgr:directory-scope("/storage/dino/", "infinity"),
           trgr:document-content(("create", "modify")),
           trgr:post-commit()))
 let $config := alert:config-get($uri)
 let $new-config := alert:config-set-trigger-ids($config, $trigger-ids)
 return alert:config-insert($new-config)