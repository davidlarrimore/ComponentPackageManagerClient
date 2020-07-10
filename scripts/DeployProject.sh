#No Longer Needed
#echo "*** Get Source Change Set ..."
#sfdx force:mdapi:retrieve -r ./mdapipkg -u IDO -p gpbu_demo_tools
#unzip ./mdapipkg/unpackaged.zip
#sfdx force mdapi:convert -r mdapipkg/

#No Longer Needed
#echo "*** import change set ..."
#sfdx force:mdapi:retrieve -r ./mdapipkg -u IDO -p gpbu_demo_tools


#No Longer Needed
#echo "*** Creating Managed Package ..."
#sfdx force:package:create --name "Demo Reset Tools" --packagetype Managed --path "force-app"
#sfdx force:package1:version:create --packageid 033xx00000007oi --name ”Spring 17” --description ”Spring 17 Release” --version 3.2 --managedreleased

#echo "*** Creating Unlocked Package ..."
#sfdx force:package:create --name "gPBU Component Package Manager Unlocked" --packagetype Unlocked --path "force-app"

#echo "*** Creating Package Version..."
#sfdx force:package:version:create --package "Demo Reset Tools" -x --wait 10 --codecoverage

echo "*** Creating Unlocked Package Version..."
sfdx force:package:version:create --package "gPBU Component Package Manager" -x --wait 10 --codecoverage 

#echo "*** Promoting Latest Managed Package ..."
#sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'Demo Reset Tools' -o CreatedDate --concise | tail -1 | awk '{print $3}')

echo "*** Promoting Latest Unlocked Package ..."
sfdx force:package:version:promote -p $(sfdx force:package:version:list -p 'gPBU Component Package Manager' -o CreatedDate --concise | tail -1 | awk '{print $3}')

#echo "*** Pushing Package to Package Manager Org ..."
#sfdx force:package:install --package "Demo Reset Tools@0.1.0-6" --targetusername PackageManager --installationkey test1234
