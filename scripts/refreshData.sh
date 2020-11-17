
echo "*** Deleting Demo Components ..."
sfdx force:apex:execute -f scripts/apex/deleteAllDemoComponents.apex

echo "*** Insert Data ..."
sfdx sfdmu:run --sourceusername csvfile --targetusername ComponentPackageManagerClientScratch -p data
