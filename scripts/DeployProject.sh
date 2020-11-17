
echo "*** Deploying Source to Org ..."
sfdx force:source:deploy --targetusername PackageManagerHub --sourcepath force-app

echo "*** Run Test Cases W\Coverage ..."
sfdx force:apex:test:run -c -u PackageManagerHub -r human

echo "*** Export Data..."
#sfdx force:data:tree:import -f ./data/export-demo-Cpm_Component_Package__c.json -u PackageManagerHub

#No Longer Needed
#echo "*** Creating Managed Package ..."
#sfdx force:package:create -n "SF Component Package Manager" -t Unlocked --nonamespace -r force-app --targetdevhubusername PackageManagerHub

echo "*** Creating Managed Package Version..."
sfdx force:package:version:create --package "Component Package Manager Client" -x --wait 10 --codecoverage  --definitionfile config/project-scratch-def.json

echo "*** Promoting Latest Managed Package ..."
sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'Component Package Manager Client' -o CreatedDate --concise | tail -1 | awk '{print $3}')

#echo "*** Pushing Package to Package Manager Org ..."
sfdx force:package:install --package $(sfdx force:package:version:list -p 'Component Package Manager Client' -o CreatedDate --concise | tail -1 | awk '{print $3}') --targetusername PackageManagerTesting --apexcompile package --noprompt

echo "*** Post Install Tasks ..."
sfdx force:apex:execute -f scripts/apex/resetAppSettings.apex -u PackageManagerTesting
sfdx force:apex:execute -f scripts/apex/deleteAllDemoComponents.apex -u PackageManagerTesting
sfdx force:data:tree:import -f ./data/export-demo-Cpm_Component_Package__c.json -u PackageManagerTesting
