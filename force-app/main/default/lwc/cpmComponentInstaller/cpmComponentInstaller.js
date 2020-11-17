import { LightningElement, api, track } from "lwc";
import {
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";
import PACKAGE_NAME_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Name__c";
import DEMO_COMPONENT_ID_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Id";
import INSTALLED_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installed__c";
import SOURCE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Type_Flag__c";
import PACKAGE_INSTALL_TYPE_FLAG_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Type_Flag__c";
import SOURCE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Source_Install_Url__c";
import PACKAGE_INSTALL_URL_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Package_Install_Url__c";
import UPDATE_AVAILABLE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Update_Available__c";
import INSTALLATION_TYPE_FIELD from "@salesforce/schema/Cpm_Component_Package__c.Installation_Type__c";

export default class CpmComponentInstaller extends LightningElement {
  @api demoComponent;
  @track error;
  @track selectedItemValue = "closed";
  @track installedDependenciesFlag = false;

  get componentPackageName() {
    return this._getDisplayValue(
      this.demoComponent.data,
      PACKAGE_NAME_FIELD
    );
  }

  get componentPackageId() {
    return this._getDisplayValue(
      this.demoComponent.data,
      DEMO_COMPONENT_ID_FIELD
    );
  }

  get componentUpdateAvailableFlag() {
    return this._getDisplayValue(
      this.demoComponent.data,
      UPDATE_AVAILABLE_FIELD
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
    return this._getDisplayValue(
      this.demoComponent.data,
      INSTALLED_FIELD
    );
  }

  get componentInstallationType() {
    return this._getDisplayValue(
      this.demoComponent.data,
      INSTALLATION_TYPE_FIELD
    );
  }  

 get isPackageInstallType(){
   if (this.componentInstallationType === 'Package'){
     return true;
   }
   return false;
 }

 get isSourceInstallType(){
  if (this.componentInstallationType === 'Source'){
    return true;
  }
  return false;
}


  get canUpdatePackageFlag() {
    if (this.componentInstalledFlag && this.componentUpdateAvailableFlag) {
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