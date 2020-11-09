
echo "*** Deploying Source to Org ..."
sfdx force:source:deploy --targetusername MyComponents --sourcepath force-app

echo "*** Run Test Cases W\Coverage ..."
sfdx force:apex:test:run -c -u MyComponents -r human

echo "*** Export Data..."
#sfdx force:data:tree:import -f ./data/export-demo-Demo_Component__c.json -u MyComponents

#No Longer Needed
#echo "*** Creating Managed Package ..."
#sfdx force:package:create -n "SF Component Package Manager" -t Unlocked --nonamespace -r force-app --targetdevhubusername MyComponents

echo "*** Creating Managed Package Version..."
sfdx force:package:version:create --package "SF Component Package Manager" -x --wait 10 --codecoverage  --definitionfile config/project-scratch-def.json

echo "*** Promoting Latest Managed Package ..."
sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'SF Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}')

#echo "*** Pushing Package to Package Manager Org ..."
sfdx force:package:install --package $(sfdx force:package:version:list -p 'SF Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}') --targetusername PackageManagerTesting --apexcompile package --noprompt

echo "*** Post Install Tasks ..."
sfdx force:apex:execute -f scripts/apex/resetAppSettings.apex -u PackageManagerTesting
sfdx force:apex:execute -f scripts/apex/deleteAllDemoComponents.apex -u PackageManagerTesting
sfdx force:data:tree:import -f ./data/export-demo-Demo_Component__c.json -u PackageManagerTesting
