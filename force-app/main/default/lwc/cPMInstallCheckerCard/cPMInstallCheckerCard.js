import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import installedComponents from '@salesforce/apex/CPMInstallCheckerController.runApex';
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

console.log('Running CPMInstallCheckerCard');

export default class CPMInstallCheckerCard extends LightningElement {
    
    @track error;
    @track record;

    @wire(installedComponents) 
    wiredInstalledComponents({ error, data }) {
        console.log('wiredInstalledComponents');
        if (data) {
            this.record = data;
            console.log(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }
  
    get getIDs() {
        return this.record;
    } 
  
    get apexRanFlag(){
        if(this.record){
            return true;
        }else{
            return false;
        }
    }

  }