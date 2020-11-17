import { LightningElement, api, wire, track } from "lwc";
import {getRecord,getFieldValue,getFieldDisplayValue} from "lightning/uiRecordApi";
import { subscribe, unsubscribe, onError } from "lightning/empApi";

import appSettings from "@salesforce/apex/CpmComponentInstallCheckerController.getAppSettings";

import ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Id";
import TITLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Title__c";
import PACKAGE_NAME_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Name__c";
import INSTALLED_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installed__c";
import SOURCE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Type_Flag__c";
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Type_Flag__c";
import GITHUB_REPOSITORY_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Github_Repository_URL__c";
import LATEST_SUBSCRIBER_VERSION_ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Latest_Subscriber_Package_Version_Id__c";
import INSTALL_KEY_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Install_Key__c";
import SOURCE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Url__c";
import PACKAGE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Url__c";
import UPDATE_AVAILABLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Update_Available__c";
import INSTALLATION_TYPE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installation_Type__c";
import LAST_FETCHED_DATE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Last_Fetched__c";

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
    channelName = "/event/Cpm_Component_Package_Update__e";

    @track demoComponentManagerSettings;

    connectedCallback() {
      this.registerErrorListener();
      this.handleSubscribe();
      this.doGetAppSettings();
    }
  

    @wire(getRecord, {
        recordId: "$recordId",
        fields
      })
      demoComponent;

      doGetAppSettings() {
        appSettings()
        .then((data) => {
          console.log(`CpmHomeRefreshCheckerCard.doGetAppSettings Completed Successfully`);
          this.demoComponentManagerSettings = data;
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

    _getDisplayValue(data, field) {
    return getFieldDisplayValue(data, field)
        ? getFieldDisplayValue(data, field)
        : getFieldValue(data, field);
    }


    doProcessPlatformEvent(payload) {
      console.log(`Processing Cpm_Component_Package_Update__e Event Payload: ${JSON.stringify(payload)}`);
    }

  // Handles subscribe button click
  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = function (response) {
      console.log("New message received: ", JSON.stringify(response));
      this.doProcessPlatformEvent(response.data.payload);

      // Response contains the payload of the new message received
    }.bind(this);

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      this.subscription = response;
      this.toggleSubscribeButton(true);
    });
  }

  // Handles unsubscribe button click
  handleUnsubscribe() {
    this.toggleSubscribeButton(false);

    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, (response) => {
      console.log("unsubscribe() response: ", JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  toggleSubscribeButton(enableSubscribe) {
    this.isSubscribeDisabled = enableSubscribe;
    this.isUnsubscribeDisabled = !enableSubscribe;
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }




}