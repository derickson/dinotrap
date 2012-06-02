xquery version "1.0-ml";

declare namespace alert = "http://marklogic.com/xdmp/alert";

declare variable $alert:config-uri as xs:string external;
declare variable $alert:doc as node() external;
declare variable $alert:rule as element(alert:rule) external;
declare variable $alert:action as element(alert:action) external;

xdmp:log(text{"Logging Alert action!"}),
xdmp:log(text{"user:", xdmp:get-current-user()}),
xdmp:log(text{"config-uri:", $alert:config-uri}),
xdmp:log(text{"doc:", xdmp:quote($alert:doc)}),
xdmp:log(text{"rule:", xdmp:quote($alert:rule)}),
xdmp:log(text{"action:", xdmp:quote($alert:action)})
