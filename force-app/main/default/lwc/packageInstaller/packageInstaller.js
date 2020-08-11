import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/GPBU_Package__c.Name';
import INSTALLED_FIELD from '@salesforce/schema/GPBU_Package__c.Installed__c';
import SOURCE_INSTALL_TYPE_FLAG_FIELD from '@salesforce/schema/GPBU_Package__c.Source_Install_Type_Flag__c';
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from '@salesforce/schema/GPBU_Package__c.Package_Install_Type_Flag__c';
import GITHUB_REPOSITORY_FIELD from '@salesforce/schema/GPBU_Package__c.Github_Repository__c';
import LATEST_SUBSCRIBER_VERSION_ID_FIELD from '@salesforce/schema/GPBU_Package__c.Latest_Subscriber_Package_Version_Id__c';
import INSTALL_KEY_FIELD from '@salesforce/schema/GPBU_Package__c.Install_Key__c';


const FIELDS = [
  'GPBU_Package__c.Name',
  'GPBU_Package__c.Installed__c',
  'GPBU_Package__c.Source_Install_Type_Flag__c',
  'GPBU_Package__c.Package_Install_Type_Flag__c',
  'GPBU_Package__c.Github_Repository__c',
  'GPBU_Package__c.Latest_Subscriber_Package_Version_Id__c',
  'GPBU_Package__c.Install_Key__c'
]


export default class PackageInstaller extends LightningElement {
  @api recordId;
  @track record;
  @track error;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
  wiredGPBU_Package__c({ error, data }) {
    if (data) {
      this.record = data;
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.record = undefined;
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

  get getPackageInstallUrl() {
    return '/packagingSetupUI/ipLanding.app?apvId=' + this.record.fields.Latest_Subscriber_Package_Version_Id__c.value;
  }

  get getSourceInstallUrl() {
    return 'https://hosted-scratch.herokuapp.com/byoo?template=' + this.record.fields.Github_Repository__c.value;
  }

  greeting = 'World';
  changeHandler(event) {
    this.greeting = event.target.value;
    
  }
}