import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import dependentPackages from '@salesforce/apex/PackageInstallerController.getDependentPackages';
import NAME_FIELD from '@salesforce/schema/Demo_Component__c.Name';
import INSTALLED_FIELD from '@salesforce/schema/Demo_Component__c.Installed__c';
import SOURCE_INSTALL_TYPE_FLAG_FIELD from '@salesforce/schema/Demo_Component__c.Source_Install_Type_Flag__c';
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from '@salesforce/schema/Demo_Component__c.Package_Install_Type_Flag__c';
import GITHUB_REPOSITORY_FIELD from '@salesforce/schema/Demo_Component__c.Github_Repository_URL__c';
import LATEST_SUBSCRIBER_VERSION_ID_FIELD from '@salesforce/schema/Demo_Component__c.Latest_Subscriber_Package_Version_Id__c';
import INSTALL_KEY_FIELD from '@salesforce/schema/Demo_Component__c.Install_Key__c';
import SOURCE_INSTALL_URL_FIELD from '@salesforce/schema/Demo_Component__c.Source_Install_Url__c';
import PACKAGE_INSTALL_URL_FIELD from '@salesforce/schema/Demo_Component__c.Package_Install_Url__c';

const FIELDS = [
  'Demo_Component__c.Name',
  'Demo_Component__c.Installed__c',
  'Demo_Component__c.Source_Install_Type_Flag__c',
  'Demo_Component__c.Package_Install_Type_Flag__c',
  'Demo_Component__c.Github_Repository_URL__c',
  'Demo_Component__c.Latest_Subscriber_Package_Version_Id__c',
  'Demo_Component__c.Install_Key__c',
  'Demo_Component__c.Source_Install_Url__c',
  'Demo_Component__c.Package_Install_Url__c'
]

export default class ComponentInstallerCard extends LightningElement {
  @api recordId;
  @track record;
  @track error;
  @track record2;
  @track selectedItemValue = "closed";

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
  wiredDemo_Component__c({ error, data }) {
    if (data) {
      this.record = data;
      console.log('wiredDemo_Component__c');
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.record = undefined;
    }
  }


  @wire(dependentPackages, {searchKey:'$recordId'}) 
  wiredPackageDependencies({ error, data }) {
    if (data) {
      this.record2 = data;
      console.log('wiredPackageDependencies');
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.record2 = undefined;
    }
  }




  get packageName() {
    return this.record.fields.Name.value;
  }

  get getSourceInstallTypeFlag() {
    return this.record.fields.Source_Install_Type_Flag__c.value;
  }

  get getPackageInstallTypeFlag() {
    return this.record.fields.Package_Install_Type_Flag__c.value;
  }

  get packageInstalledFlag() {
    return this.record.fields.Installed__c.value;
  } 


  
  get canInstallPackageFlag() {

    for(var i = 0; i < this.record2.length; i++) {
      var obj = this.record2[i];
      console.log('Dependency Number ' + i + ', Id: ' + obj.Id);
      if(obj.Installed__c == false){
        return false;
      }
    }
      return true;
  } 

  greeting = 'World';
  changeHandler(event) {
    this.greeting = event.target.value;
    
  }
}