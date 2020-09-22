echo "*** Creating scratch org ..."
sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias ComponentManagerScratch -d 30

echo "*** Opening scratch org ..."
#sfdx force:org:open

echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push

echo "*** Assigning permission set to your user ..."
sfdx force:user:permset:assign --permsetname Demo_Component_Manager

echo "*** Generating password for your user ..."
sfdx force:user:password:generate --targetusername ComponentManagerScratch

echo "*** Creating data"
sfdx force:data:tree:import -f ./data/export-demo-Demo_Component__c.json -u ComponentManagerScratch

echo "*** Setting up debug mode..."
sfdx force:apex:execute -f scripts/apex/DebugMode.apex

echo "*** Opening Org"
sfdx force:org:open