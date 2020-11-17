import { LightningElement, track, api, wire } from "lwc";
import { getFieldValue, getFieldDisplayValue } from "lightning/uiRecordApi";
import dependentPackages from "@salesforce/apex/CpmComponentInstallerController.getDependentPackages";
import INSTALLED_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installed__c";
import ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Id";
import SOURCE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Type_Flag__c";
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Type_Flag__c";
import GITHUB_REPOSITORY_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Github_Repository_URL__c";
import LATEST_SUBSCRIBER_VERSION_ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Latest_Subscriber_Package_Version_Id__c";
import SOURCE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Url__c";
import PACKAGE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Url__c";
import UPDATE_AVAILABLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Update_Available__c";
import INSTALLATION_TYPE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installation_Type__c";
import TITLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Title__c";

export default class CpmComponentInstallerDependencies extends LightningElement {
  @api demoComponent;
  @api demoComponentId;
  @track error;
  @track demoComponentDependencies = [];
  @track dependenciesMetFlag = true;

  @wire(dependentPackages, {demoComponentId: '$demoComponentId'})
  wiredPackageDependencies({ error, data }) {
    console.log(`Running wiredPackageDependencies. Demo Component ID: ${this.demoComponentId}`);
    if (data) {
      console.log('wiredPackageDependencies SUCCESS');
      console.log(`Data = ${console.log(JSON.stringify(data))}`);

      console.log('Checking for Dependencies');

      this.demoComponentDependencies = data;
      this.dependenciesMetFlag = true;

      for (let i = 0; i < this.demoComponentDependencies.length; i++) {
        if (this.demoComponentDependencies[i].Installed__c === false) {
          console.log(
            `demoComponentDependencies${[i]}.Installed_Flag__c is false. Setting dependenciesMetFlag as false`
          );
          this.dependenciesMetFlag = false;
        }
      }

      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log("wiredPackageDependencies ERROR: " + error);
      this.demoComponentDependencies = undefined;
    }
  }

  get componentPackageTitle() {
    return this._getDisplayValue(this.demoComponent.data, TITLE_FIELD);
  }

  get componentUpdateAvailableFlag() {
    return this._getDisplayValue(
      this.demoComponent.data,
      UPDATE_AVAILABLE_FIELD
    );
  }

  get componentGithubRepository() {
    return this._getDisplayValue(
      this.demoComponent.data,
      GITHUB_REPOSITORY_FIELD
    );
  }

  get componentInstallationType() {
    return this._getDisplayValue(
      this.demoComponent.data,
      INSTALLATION_TYPE_FIELD
    );
  }

  get componentLatestSubscriberVersionId() {
    return this._getDisplayValue(
      this.demoComponent.data,
      LATEST_SUBSCRIBER_VERSION_ID_FIELD
    );
  }

  get componentPackageInstallUrl() {
    return this._getDisplayValue(
      this.demoComponent.data,
      PACKAGE_INSTALL_URL_FIELD
    );
  }
  get componentSourceInstallUrl() {
    return this._getDisplayValue(
      this.demoComponent.data,
      SOURCE_INSTALL_URL_FIELD
    );
  }
  get componentSourceInstallTypeFlag() {
    return this._getDisplayValue(
      this.demoComponent.data,
      SOURCE_INSTALL_TYPE_FLAG_FIELD
    );
  }

  get componentPackageInstallTypeFlag() {
    return this._getDisplayValue(
      this.demoComponent.data,
      PACKAGE_INSTALL_TYPE_FLAG_FIELD
    );
  }

  get componentInstalledFlag() {
    return this._getDisplayValue(this.demoComponent.data, INSTALLED_FIELD);
  }

  get componentId() {
    return this._getDisplayValue(this.demoComponent.data, ID_FIELD);
  }

  _getDisplayValue(data, field) {
    return getFieldDisplayValue(data, field)
      ? getFieldDisplayValue(data, field)
      : getFieldValue(data, field);
  }
}