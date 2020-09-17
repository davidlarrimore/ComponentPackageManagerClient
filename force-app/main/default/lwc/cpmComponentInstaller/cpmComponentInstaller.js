import { LightningElement, api, track, wire } from "lwc";
import {
  getRecord,
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";
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

const fields = [
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
  INSTALLATION_TYPE_FIELD
];

export default class CpmComponentInstaller extends LightningElement {
  @api recordId;
  @track demoComponent;
  @track error;
  @track demoComponentDependencies;
  @track selectedItemValue = "closed";

  @wire(getRecord, {
    recordId: "$recordId",
    fields
  })
  wired_demoComponent;

  get componentPackageName() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      PACKAGE_NAME_FIELD
    );
  }

  get componentUpdateAvailableFlag() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      UPDATE_AVAILABLE_FIELD
    );
  }

  get componentPackageInstallUrl() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      PACKAGE_INSTALL_URL_FIELD
    );
  }
  get componentSourceInstallUrl() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      SOURCE_INSTALL_URL_FIELD
    );
  }
  get componentSourceInstallTypeFlag() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      SOURCE_INSTALL_TYPE_FLAG_FIELD
    );
  }

  get componentPackageInstallTypeFlag() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      PACKAGE_INSTALL_TYPE_FLAG_FIELD
    );
  }

  get componentInstalledFlag() {
    return this._getDisplayValue(
      this.wired_demoComponent.data,
      INSTALLED_FIELD
    );
  }

  get canInstallPackageFlag() {
    return false;
  }

  get needDependenciesInstalledFlag() {
    return true;
  }

  get canUpdatePackageFlag() {
    if (this.getComponentInstalledFlag() && this.getUpdateAvailableFlag()) {
      return true;
    }
    return false;
  }

  _getDisplayValue(data, field) {
    return getFieldDisplayValue(data, field)
      ? getFieldDisplayValue(data, field)
      : getFieldValue(data, field);
  }
}
