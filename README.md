# Default Objects:
Required on all objects
Record Type Name
External Id (Primary Key)
External Lookup Id (Foreign Key)



# Converting Org scenarios to Packages general flow
 - Add required custom fields / Custom Settings (See above)
 - Create Change Set
 - Authorize org in sfdx (User standard Name)
 - Create Scratch Org
 - Run ConvertScript
 - Review errors and make changes
 - Rinse repeat till errors are gone.
 - commit checkpoint

 - Create data SOQL queries
 - Config SDFMU export.json
 - get successful SFDMU run
 - push data to scratch org
 - TODO: Create script to convert files to JSON and add data to static resources
 - commit checkpoint

 - Configure as necessary
 - update SFDMU as necessary
 - Test Test Test
 - Commit checkpoint

 - Package
 - commit checkpoint
 - tag/release