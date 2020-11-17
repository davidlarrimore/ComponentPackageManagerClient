echo "*** Creating scratch org ..."
sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias ComponentPackageManagerClientScratch -d 30

echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push

echo "*** Assigning permission set to your user ..."
sfdx force:user:permset:assign --permsetname ComponentPackageManagerClient

echo "*** Generating password for your user ..."
sfdx force:user:password:generate --targetusername ComponentPackageManagerClientScratch

echo "*** Upserting data"
sfdx sfdmu:run --sourceusername csvfile --targetusername ComponentPackageManagerClientScratch -p data

echo "*** Setting up debug mode..."
sfdx force:apex:execute -f scripts/apex/setDebugMode.apex
sfdx force:apex:execute -f scripts/apex/resetAppSettings.apex

echo "*** Setting up debug mode..."
sfdx force:org:open