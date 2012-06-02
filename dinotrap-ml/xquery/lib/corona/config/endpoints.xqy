xquery version "1.0-ml";

module namespace endpoints="http://marklogic.com/corona/endpoints";

import module namespace rest="http://marklogic.com/appservices/rest" at "../corona/lib/rest/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $CORONA-REST-ROOT as xs:string := "/lib/corona";

declare variable $endpoints:ENDPOINTS as element(rest:options) :=
<options xmlns="http://marklogic.com/appservices/rest">
    <!-- Manage documents in the database -->
    <request uri="^/corona/store/?$" endpoint="{$CORONA-REST-ROOT}/corona/store-get.xqy">
        <param name="uri" required="false"/>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="outputFormat" required="false" values="json|xml"/>
    </request>

    <request uri="^/corona/store/?$" endpoint="{$CORONA-REST-ROOT}/corona/store.xqy">
        <param name="uri" required="false"/>
        <param name="txid" required="false"/>

        <http method="GET">
            <param name="stringQuery" required="false"/>
            <param name="structuredQuery" required="false"/>
            <param name="extractPath" required="false"/>
            <param name="applyTransform" required="false"/>
            <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
            <param name="outputFormat" required="false" values="json|xml"/>
        </http>
        <http method="POST">
            <param name="contentType" required="false" values="json|xml|text|binary"/>
            <param name="collection" alias="collection[]" repeatable="true" required="false"/>
            <param name="addCollection" alias="addCollection[]" repeatable="true" required="false"/>
            <param name="removeCollection" alias="removeCollection[]" repeatable="true" required="false"/>
            <param name="property" alias="property[]" repeatable="true" required="false"/>
            <param name="addProperty" alias="addProperty[]" repeatable="true" required="false"/>
            <param name="removeProperty" alias="removeProperty[]" repeatable="true" required="false"/>
            <param name="permission" alias="permission[]" repeatable="true" required="false"/>
            <param name="addPermission" alias="addPermission[]" repeatable="true" required="false"/>
            <param name="removePermission" alias="removePermission[]" repeatable="true" required="false"/>
            <param name="quality" required="false"/>
            <param name="contentForBinary" required="false"/>
            <param name="moveTo" required="false"/>
        </http>
        <http method="PUT">
            <param name="contentType" required="false" values="json|xml|text|binary"/>
            <param name="collection" alias="collection[]" repeatable="true" required="false"/>
            <param name="property" alias="property[]" repeatable="true" required="false"/>
            <param name="permission" alias="permission[]" repeatable="true" required="false"/>
            <param name="quality" required="false"/>
            <param name="contentForBinary" required="false"/>
        </http>
        <http method="DELETE">
            <param name="stringQuery" required="false"/>
            <param name="structuredQuery" required="false"/>
            <param name="bulkDelete" required="false" as="boolean" default="false"/>
            <param name="include" alias="include[]" repeatable="true" required="false"/>
            <param name="limit" required="false" as="integer"/>
            <param name="outputFormat" required="false" values="json|xml"/>
        </http>
    </request>

    <!-- Search endpoint -->
    <request uri="^/corona/search(/)?$" endpoint="{$CORONA-REST-ROOT}/corona/search.xqy">
        <param name="txid" required="false"/>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="length" required="false" as="positiveInteger" default="10"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="filtered" required="false" default="false" as="boolean"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false" values="json|xml"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Key value queryies -->
    <request uri="^/corona/kvquery$" endpoint="{$CORONA-REST-ROOT}/corona/kvquery.xqy">
        <param name="txid" required="false"/>
        <param name="key" required="false"/>
        <param name="element" required="false"/>
        <param name="attribute" required="false"/>
        <param name="property" required="false"/>
        <param name="value" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="length" required="false" as="positiveInteger" default="1"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false" values="json|xml"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Facets -->
    <request uri="^/corona/facet/([A-Za-z0-9_\-,]+)/?$" endpoint="{$CORONA-REST-ROOT}/corona/facet.xqy">
        <param name="txid" required="false"/>
        <uri-param name="facets">$1</uri-param>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="limit" as="integer" default="25" required="false"/>
        <param name="order" required="false" default="frequency" values="descending|ascending|frequency"/>
        <param name="frequency" required="false" default="document" values="document|key"/>
        <param name="includeAllValues" required="false" default="no" values="no|yes"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false"  values="xml|json"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Transaction management -->
    <request uri="^/corona/transaction/(status|create|commit|rollback)/?$" endpoint="{$CORONA-REST-ROOT}/corona/transaction.xqy">
        <uri-param name="action">$1</uri-param>
        <param name="txid" required="false"/>
        <param name="outputFormat" required="false" values="xml|json"/>
        <param name="timeLimit" required="false" as="decimal"/>
        <http method="GET"/>
        <http method="POST"/>
    </request>

    <!-- Index management -->

    <request uri="^/corona/manage(/)?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/summary.xqy" user-params="ignore">
        <http method="GET"/>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage(/)?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/state.xqy">
        <http method="POST">
            <param name="isManaged" as="boolean" required="false"/>
        </http>
    </request>

    <request uri="^/corona/manage/(ranges|range/([A-Za-z0-9_-]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/range.xqy">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="type" required="true"/>
            <param name="collation" required="false"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage/(bucketedranges|bucketedrange/([A-Za-z0-9_-]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/bucketedrange.xqy">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="type" required="true"/>
            <param name="buckets" required="false"/>
            <param name="bucketInterval" required="false"/>
            <param name="startingAt" required="false"/>
            <param name="stoppingAt" required="false"/>
            <param name="format" required="false"/>
            <param name="firstFormat" required="false"/>
            <param name="lastFormat" required="false"/>
            <param name="collation" required="false"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage/(geospatials|geospatial/([A-Za-z0-9_-]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/geo.xqy">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="parentKey" required="false"/>
            <param name="parentElement" required="false"/>
            <param name="latKey" required="false"/>
            <param name="longKey" required="false"/>
            <param name="latElement" required="false"/>
            <param name="longElement" required="false"/>
            <param name="latAttribute" required="false"/>
            <param name="longAttribute" required="false"/>
            <param name="coordinateSystem" required="false" default="wgs84"/>
            <param name="comesFirst" required="false" default="latitude"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage/(namespaces|namespace/([^/]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/namespace.xqy">
        <uri-param name="prefix" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="uri" required="true"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage/(transformers|transformer/([^/]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/transformer.xqy">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="PUT"/>
        <http method="DELETE"/>
    </request>

    <request uri="^/corona/manage/(place|places|place/([^/]+))/?$" endpoint="{$CORONA-REST-ROOT}/corona/manage/places.xqy">
        <uri-param name="scope" as="string">$1</uri-param>
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="PUT">
            <param name="mode" required="false" default="textContains"/>
        </http>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="place" required="false"/>
            <param name="type" required="false" default="include"/>
            <param name="weight" required="false" default="1.0" as="decimal"/>
        </http>
        <http method="DELETE">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="place" required="false"/>
            <param name="type" required="false" default="include"/>
        </http>
    </request>

    <request uri="^/corona/config/setup" endpoint="{$CORONA-REST-ROOT}/config/setup.xqy" user-params="allow">
        <http method="GET"/>
        <http method="POST"/>
    </request>

</options>;

declare function endpoints:options(
) as element(rest:options)
{
    $ENDPOINTS
};

declare function endpoints:request(
    $module as xs:string
) as element(rest:request)?
{
    ($ENDPOINTS/rest:request[@endpoint = $module])[1]
};
