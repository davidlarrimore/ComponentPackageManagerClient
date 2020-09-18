import { LightningElement, api } from "lwc";

export default class CpmComponentInstallerDependency extends LightningElement {
  @api demoComponent;

  get componentLightningURL(){
    return `/lightning/r/Demo_Component__c/${this.demoComponent.Id}/view`;
  }
}
