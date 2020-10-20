
echo "*** Deploying Source to Org ..."
sfdx force:source:deploy --targetusername MyComponents --sourcepath force-app

echo "*** Run Test Cases W\Coverage ..."
sfdx force:apex:test:run -c -u MyComponents -r human