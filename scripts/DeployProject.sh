
#No Longer Needed
#echo "*** Creating Managed Package ..."
sfdx force:package:create --name "Demo Component Package Manager" --packagetype Unlocked --path "force-app"
#sfdx force:package1:version:create --packageid 033xx00000007oi --name ”Spring 17” --description ”Spring 17 Release” --version 3.2 --managedreleased

echo "*** Export Data..."
#sfdx force:data:tree:export -q ./scripts/soql/demo.soql -x export-demo -d ./data/

echo "*** Creating Managed Package Version..."
sfdx force:package:version:create --package "Demo Component Package Manager" -x --wait 10 --codecoverage

#echo "*** Promoting Latest Managed Package ..."
sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'Demo Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}')

#echo "*** Pushing Package to Package Manager Org ..."
#sfdx force:package:install --package "Demo Reset Tools@0.1.0-6" --targetusername PackageManager --installationkey test1234
