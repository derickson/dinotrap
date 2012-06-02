(:
Copyright 2011 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

xquery version "1.0-ml";

import module namespace template="http://marklogic.com/corona/template" at "../corona/htools/template.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $devPermisssions := <perms>
    <perm><role>corona-dev</role><type>read</type></perm>
    <perm><role>corona-dev</role><type>insert</type></perm>
    <perm><role>corona-dev</role><type>update</type></perm>
</perms>;

declare variable $devPrivileges := <privs>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-add-response-header</priv>
    <priv>http://marklogic.com/xdmp/privileges/xslt-eval</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-eval</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-eval-in</priv>
    <priv>http://marklogic.com/xdmp/privileges/get-role-names</priv>
    <priv>http://marklogic.com/xdmp/privileges/any-uri</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-value</priv>
    <priv>http://marklogic.com/xdmp/privileges/any-collection</priv>
    <priv>http://marklogic.com/xdmp/privileges/admin-module-read</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-transaction-create</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-set-transaction-name-any</priv>
    <priv>http://marklogic.com/xdmp/privileges/status</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-invoke</priv>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-invoke-transaction</priv>
    <priv>http://marklogic.com/xdmp/privileges/complete-my-transactions</priv>
</privs>;

declare variable $adminPermisssions := <perms>
    <perm><role>corona-admin</role><type>read</type></perm>
    <perm><role>corona-admin</role><type>insert</type></perm>
    <perm><role>corona-admin</role><type>update</type></perm>
</perms>;

declare variable $adminPrivileges := <privs>
    <priv>http://marklogic.com/xdmp/privileges/xdmp-add-response-header</priv>
    <priv>http://marklogic.com/xdmp/privileges/admin-module-read</priv>
    <priv>http://marklogic.com/xdmp/privileges/admin-module-write</priv>
    <priv>http://marklogic.com/xdmp/privileges/any-collection</priv>
    <priv type="uri" name="corona-transformers-uri">_/transformers/</priv>
</privs>;

declare function local:setupRole(
    $role as xs:string,
    $description as xs:string
) as empty-sequence()
{
    let $intendedPermissions := 
        if($role = "corona-dev")
        then $devPermisssions
        else if($role = "corona-admin")
        then $adminPermisssions
        else ()

    let $privileges :=
        if($role = "corona-dev")
        then $devPrivileges
        else if($role = "corona-admin")
        then $adminPrivileges
        else ()

    let $roleID := xdmp:eval('
            import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
            declare variable $role as xs:string external;
            declare variable $description as xs:string external;

            try {
                sec:get-role-ids($role)
            }
            catch ($e) {
                sec:create-role($role, $description, (), (), ())
            }

        ', (xs:QName("role"), $role, xs:QName("description"), $description))

    let $setPermissions :=
        xdmp:eval('
            import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
            declare variable $role as xs:string external;
            declare variable $intendedPermissions as element(perms) external;

            sec:role-set-default-permissions($role, 
                for $i in $intendedPermissions/*
                return xdmp:permission(string($i/role), string($i/type))
            )
        ', (xs:QName("role"), $role, xs:QName("intendedPermissions"), $intendedPermissions))

    let $createPrivs :=
        xdmp:eval('
            import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
            declare variable $privileges as element(privs) external;

            for $priv in $privileges/*
            let $privExists := try {
                    exists(sec:get-privilege(string($priv), "uri"))
                }
                catch ($e) {
                    false()
                }
            where $priv/@type = "uri" and not($privExists)
            return sec:create-privilege(string($priv/@name), string($priv), "uri", ())
        ', (xs:QName("privileges"), $privileges))
    return
        xdmp:eval('
            import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
            declare variable $role as xs:string external;
            declare variable $privileges as element(privs) external;

            let $newPrivileges := for $i in $privileges/* return string($i)
            let $existingPrivileges := for $i in sec:role-privileges($role) return string($i/sec:action)
            let $privilegesToRemove := $existingPrivileges[not(. = $newPrivileges)]

            return (
                for $priv in $privileges/*
                let $type := ($priv/@type, "execute")[1]
                return try { sec:privilege-add-roles(string($priv), $type, $role) } catch($e) {}
                ,
                for $priv in $privilegesToRemove
                return sec:privilege-remove-roles($priv, "execute", $role)
            )

        ', (xs:QName("role"), $role, xs:QName("privileges"), $privileges))
};


if(xdmp:database() != xdmp:database("Security"))
then xdmp:invoke("/config/setup.xqy", (), <options xmlns="xdmp:eval"><database>{ xdmp:database("Security") }</database></options>)
else

let $createUsers := xs:boolean((xdmp:get-request-field("createUsers", "false"))[1])
let $adminName := xdmp:get-request-field("adminName")
let $adminPass := xdmp:get-request-field("adminPass")
let $devName := xdmp:get-request-field("devName")
let $devPass := xdmp:get-request-field("devPass")

let $hasUsers :=
    try {
        exists(/sec:user[sec:role-ids/sec:role-id = xdmp:role("corona-admin")]) and
        exists(/sec:user[sec:role-ids/sec:role-id = xdmp:role("corona-dev")])
    }
    catch ($e) {
        false()
    }

return
    if(exists($adminName) and exists($adminPass) and exists($devName) and exists($devPass))
    then
        let $set := sec:create-user($adminName, "Corona Administrator", $adminPass, "corona-admin", (), ())
        let $set := sec:create-user($devName, "Corona Developer", $devPass, "corona-dev", (), ())
        return template:apply(<div><p>Corona has been fully setup and both a developer and administrative account exist.</p></div>, "Corona Setup", (), 0, ())
    else if($createUsers)
    then template:apply(
        <div>
            <p>Before you can use Corona, you must create a couple of users. An
            administrative account (configures search behavior, output
            transformations, etc) and a developer account (inserts documents,
            performs searches, etc).</p>
            <form class="createUsers" action="/config/setup" method="GET">
                <div>
                    <h2>Corona Administrator</h2>
                    <table>
                        <tr><td>Name</td><td><input type="text" class="an" name="adminName"/></td></tr>
                        <tr><td>Password</td><td><input type="password" class="ap1" name="adminPass"/></td></tr>
                        <tr><td>Confirm Password</td><td><input type="password" class="ap2"/></td></tr>
                    </table>
                </div>
                <hr/>
                <div>
                    <h2>Corona Developer</h2>
                    <table>
                        <tr><td>Name</td><td><input type="text" class="dn" name="devName"/></td></tr>
                        <tr><td>Password</td><td><input type="password" class="dp1" name="devPass"/></td></tr>
                        <tr><td>Confirm Password</td><td><input type="password" class="dp2"/></td></tr>
                    </table>
                </div>
                <input type="submit" value="Submit"/>
            </form>
        </div>,
        "Create Users", (), 0, <script src="/corona/htools/js/setup.js"><!-- --></script>)
    else
        let $setup := local:setupRole("corona-dev", "Corona Developer")
        let $setup := local:setupRole("corona-admin", "Corona Administrator")
        return
            if($hasUsers)
            then template:apply(<div><p>Corona has been fully setup and both a developer and administrative account exist.</p></div>, "Corona Setup", (), 0, ())
            else xdmp:redirect-response("/config/setup?createUsers=true")
