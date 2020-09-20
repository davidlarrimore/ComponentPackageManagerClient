import { LightningElement, wire, track } from "lwc";
import demoComponents from "@salesforce/apex/CpmComponentController.getDemoComponents";

export default class CmpHomeLayoutManager extends LightningElement {
  @track demoComponents;

  @wire(demoComponents)
  wiredDemoComponents({ error, data }) {
    if (data) {
      console.log("CmpHomeLayoutManager wiredDemoComponents SUCCESS");
      //console.log(`Data = ${console.log(JSON.stringify(data))}`);
      this.demoComponents = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log(
        "CmpHomeLayoutManager wiredDemoComponents ERROR: " + error
      );
      this.demoComponentDependencies = undefined;
    }
  }
}
