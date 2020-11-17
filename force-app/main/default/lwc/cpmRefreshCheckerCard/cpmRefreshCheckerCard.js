import { LightningElement, api, track } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";
import {
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";

import ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Id";
import TITLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Title__c";
import LAST_FETCHED_DATE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Last_Fetched__c";

export default class CpmRefreshCheckerCard extends LightningElement {
  @api demoComponent;
  @track error;


  renderedCallback() {
    console.log("Running doRefreshComponent");
    this.doRefreshComponent(false);
  }

  handleButtonClick() {
    console.log(`Forcing Component Refresh`);
    this.doRefreshComponent(true);
  }

  doRefreshComponent(forcedRefreshFlag) {
    console.log(`demoComponent is: ${JSON.stringify(this.demoComponent)}`);
    console.log(`demoComponentId is: ${this.demoComponentId}`);
    console.log(`Forced Refresh Flag is: ${forcedRefreshFlag}`);
    refreshComponent({demoComponentId: this.demoComponentId, forcedRefresh: forcedRefreshFlag})
      .then((data) => {
        console.log(`CpmRefreshCheckerCard Response: ${data}`);
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
      });
    }

    get demoComponentTitle() {
      return this._getDisplayValue(
        this.demoComponent.data,
        TITLE_FIELD
      );
    }

    get demoComponentId() {
      return this._getDisplayValue(
        this.demoComponent.data,
        ID_FIELD
      );
    }

    get demoComponentlastFethedDate() {
      return this._getDisplayValue(
        this.demoComponent.data,
        LAST_FETCHED_DATE_FIELD
      );
    }

    get demoComponentlastFethedDateText() {
      const inputDate = new Date(this.demoComponentlastFethedDate);
      const today = new Date();
      if(this.demoComponentlastFethedDate){
        if(inputDate.getDate() === today.getDate() && inputDate.getMonth() === today.getMonth() && inputDate.getFullYear() === today.getFullYear()){
            return 'Today';
        }
      }      
      return this.demoComponentlastFethedDate;
    }    



  _getDisplayValue(data, field) {
  return getFieldDisplayValue(data, field)
      ? getFieldDisplayValue(data, field)
      : getFieldValue(data, field);
  }



}