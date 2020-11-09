
echo "*** Deleting Demo Components ..."
sfdx force:apex:execute -f scripts/apex/deleteAllDemoComponents.apex

echo "*** Insert Data ..."
sfdx force:data:tree:import -f ./data/export-demo-Demo_Component__c.json -u ComponentManagerScratch