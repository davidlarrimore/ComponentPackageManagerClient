import { LightningElement, api, wire } from "lwc";
import {
  getRecord,
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";

import ID_FIELD from "@salesforce/schema/Demo_Component__c.Id";
import TITLE_FIELD from "@salesforce/schema/Demo_Component__c.Title__c";
import PACKAGE_NAME_FIELD from "@salesforce/schema/Demo_Component__c.Package_Name__c";
import INSTALLED_FIELD from "@salesforce/schema/Demo_Component__c.Installed__c";
import SOURCE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Demo_Component__c.Source_Install_Type_Flag__c";
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Demo_Component__c.Package_Install_Type_Flag__c";
import GITHUB_REPOSITORY_FIELD from "@salesforce/schema/Demo_Component__c.Github_Repository_URL__c";
import LATEST_SUBSCRIBER_VERSION_ID_FIELD from "@salesforce/schema/Demo_Component__c.Latest_Subscriber_Package_Version_Id__c";
import INSTALL_KEY_FIELD from "@salesforce/schema/Demo_Component__c.Install_Key__c";
import SOURCE_INSTALL_URL_FIELD from "@salesforce/schema/Demo_Component__c.Source_Install_Url__c";
import PACKAGE_INSTALL_URL_FIELD from "@salesforce/schema/Demo_Component__c.Package_Install_Url__c";
import UPDATE_AVAILABLE_FIELD from "@salesforce/schema/Demo_Component__c.Update_Available__c";
import INSTALLATION_TYPE_FIELD from "@salesforce/schema/Demo_Component__c.Installation_Type__c";
import LAST_FETCHED_DATE_FIELD from "@salesforce/schema/Demo_Component__c.Last_Fetched__c";

const fields = [
    ID_FIELD,
    TITLE_FIELD,
    PACKAGE_NAME_FIELD,
    INSTALLED_FIELD,
    SOURCE_INSTALL_TYPE_FLAG_FIELD,
    PACKAGE_INSTALL_TYPE_FLAG_FIELD,
    GITHUB_REPOSITORY_FIELD,
    LATEST_SUBSCRIBER_VERSION_ID_FIELD,
    INSTALL_KEY_FIELD,
    SOURCE_INSTALL_URL_FIELD,
    PACKAGE_INSTALL_URL_FIELD,
    UPDATE_AVAILABLE_FIELD,
    INSTALLATION_TYPE_FIELD,
    LAST_FETCHED_DATE_FIELD
  ];

export default class CpmDemoComponentLayoutManager extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: "$recordId",
        fields
      })
      demoComponent;


      get demoComponentTitle() {
        return this._getDisplayValue(
          this.demoComponent.data,
          TITLE_FIELD
        );
      }




    _getDisplayValue(data, field) {
    return getFieldDisplayValue(data, field)
        ? getFieldDisplayValue(data, field)
        : getFieldValue(data, field);
    }


}
