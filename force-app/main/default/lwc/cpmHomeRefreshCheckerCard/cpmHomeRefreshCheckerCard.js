import { LightningElement, api, track } from "lwc";

import {
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";

import componentInstallChecker from "@salesforce/apex/CpmComponentInstallCheckerController.runApex";
import appSettings from "@salesforce/apex/CpmComponentInstallCheckerController.getAppSettings";


export default class CpmHomeRefreshCheckerCard extends LightningElement {
  @api demoComponent;
  @track error;
  @track demoComponentManagerSettings;

  connectedCallback() {
    console.log("Running doRefreshComponent");
    this.doGetAppSettings();
    this.doComponentInstallChecker(false);
  }

  handleButtonClick() {
    console.log(`Forcing Component Refresh`);
    //this.doRefreshComponent(true);
    this.doComponentInstallChecker(true);
    this.doGetAppSettings();
  }

  doGetAppSettings() {
    appSettings()
    .then((data) => {
      console.log(`wiredcomponentInstallChecker Response: ${data}`);
      this.demoComponentManagerSettings = data;
      this.error = undefined;
    })
    .catch((error) => {
      this.error = error;
    });
  }


  doComponentInstallChecker(forcedRefreshFlag) {
    componentInstallChecker({forcedRefresh: forcedRefreshFlag})
    .then((data) => {
      console.log(`wiredcomponentInstallChecker Response: ${data}`);
      this.error = undefined;
    })
    .catch((error) => {
      this.error = error;
    });
  }

  /*
    get demoComponentTitle() {
      return this._getDisplayValue(
        this.demoComponent.data,
        TITLE_FIELD
      );
    }
*/


  get lastLibraryRefreshDate() {
    if(undefined !== this.demoComponentManagerSettings){ 
      const inputDate = new Date(this.demoComponentManagerSettings.Last_Library_Refresh_Date__c);
      const today = new Date();
      if(inputDate.getDate() === today.getDate() && inputDate.getMonth() === today.getMonth() && inputDate.getFullYear() === today.getFullYear()){
          return 'Today';
      }
      return this.demoComponentManagerSettings.Last_Library_Refresh_Date__c;
    }
    return '';
  }    



  _getDisplayValue(data, field) {
  return getFieldDisplayValue(data, field)
      ? getFieldDisplayValue(data, field)
      : getFieldValue(data, field);
  }



}