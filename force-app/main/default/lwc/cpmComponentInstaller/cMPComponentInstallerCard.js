import { LightningElement, api, track, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Demo_Component__c.Name";
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

export default class ComponentInstallerCard extends LightningElement {
  @api recordId;
  @track demoComponent;
  @track error;
  @track demoComponentDependencies;
  @track selectedItemValue = "closed";

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      NAME_FIELD,
      INSTALLED_FIELD,
      SOURCE_INSTALL_TYPE_FLAG_FIELD,
      PACKAGE_INSTALL_TYPE_FLAG_FIELD,
      GITHUB_REPOSITORY_FIELD,
      LATEST_SUBSCRIBER_VERSION_ID_FIELD,
      INSTALL_KEY_FIELD,
      SOURCE_INSTALL_URL_FIELD,
      PACKAGE_INSTALL_URL_FIELD,
      UPDATE_AVAILABLE_FIELD,
      INSTALLATION_TYPE_FIELD
    ]
  })
  wiredDemo_Component__c({ error, data }) {
    if (data) {
      this.demoComponent = data;
      console.log("wiredDemo_Component__c SUCCESS");
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log("wiredDemo_Component__c ERROR: " + error);
      this.demoComponent = undefined;
    }
  }

  get packageName() {
    return this.demoComponent.fields.Name.value;
  }

  get getUpdateAvailableFlag() {
    return this.demoComponent.fields.Update_Available__c.value;
  }

  get getSourceInstallTypeFlag() {
    return this.demoComponent.fields.Source_Install_Type_Flag__c.value;
  }

  get getPackageInstallTypeFlag() {
    return this.demoComponent.fields.Package_Install_Type_Flag__c.value;
  }

  get getComponentInstalledFlag() {
    return this.demoComponent.fields.Installed__c.value;
  }

  get getUpdateFlag() {
    return this.demoComponent.fields.Update_Available__c.value;
  }

  get canInstallPackageFlag() {
    return false;
  }

  get needDependenciesInstalledFlag() {
    return true;
  }

  get canUpdatePackageFlag() {
    if (
      this.demoComponent.fields.Installed__c.value &&
      this.demoComponent.fields.Update_Available__c.value
    ) {
      return true;
    }
    return false;
  }

  greeting = "World";
  changeHandler(event) {
    this.greeting = event.target.value;
  }
}
