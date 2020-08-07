echo "Exporting scratch orgs..."
sfdx force:data:soql:query -q "SELECT Id, Username FROM ScratchOrgInfo" -r csv -u MyComponents > ./ScratchOrgs.csv
cat ./ScratchOrgs.csv
echo "Deleting found scratch Orgs..."
sfdx force:data:bulk:delete -f ./ScratchOrgs.csv -s ScratchOrgInfo -w 10 -u MyComponents
echo "Cleaning up org list"
sfdx force:org:list --clean
rm -f ./ScratchOrgs.csv