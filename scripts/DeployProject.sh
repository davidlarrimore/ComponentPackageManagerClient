
echo "*** Deploying Source to Org ..."
sfdx force:source:deploy --targetusername MyComponents --sourcepath force-app

echo "*** Run Test Cases W\Coverage ..."
sfdx force:apex:test:run -c -u MyComponents -r human

echo "*** Export Data..."
#sfdx force:data:tree:export -q ./scripts/soql/demo.soql -x export-demo -d ./data/

#No Longer Needed
#echo "*** Creating Managed Package ..."
#sfdx force:package:create - "Component Package Manager" -t Unlocked -r force-app --targetdevhubusername MyComponents

echo "*** Creating Managed Package Version..."
sfdx force:package:version:create --package "Component Package Manager" -x --wait 10 --codecoverage  --definitionfile config/project-scratch-def.json

echo "*** Promoting Latest Managed Package ..."
sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}')

#echo "*** Pushing Package to Package Manager Org ..."
sfdx force:package:install --package $(sfdx force:package:version:list -p 'Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}') --targetusername PackageManagerTesting --apexcompile package