import { LightningElement, track, api, wire } from "lwc";
import dependentPackages from "@salesforce/apex/CpmComponentInstallerController.getDependentPackages";

export default class CpmComponentInstallerDependencies extends LightningElement {
  @api demoComponentId;
  @track error;
  @track demoComponentDependencies;

  @wire(dependentPackages, { searchKey: "$demoComponentId" })
  wiredPackageDependencies({ error, data }) {
    if (data) {
      console.log("wiredPackageDependencies SUCCESS");
      this.demoComponentDependencies = data;
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log("wiredPackageDependencies ERROR: " + error);
      this.demoComponentDependencies = undefined;
    }
  }

  get thedemoComponentId(){
    return this.demoComponentId;  
  }


  
}
