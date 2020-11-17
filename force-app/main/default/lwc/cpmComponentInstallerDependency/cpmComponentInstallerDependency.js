import { LightningElement, api } from "lwc";

export default class CpmComponentInstallerDependency extends LightningElement {
  @api demoComponent;

  get componentLightningURL(){
    return `/lightning/r/Cpm_Component_Package__c/${this.demoComponent.Id}/view`;
  }
}