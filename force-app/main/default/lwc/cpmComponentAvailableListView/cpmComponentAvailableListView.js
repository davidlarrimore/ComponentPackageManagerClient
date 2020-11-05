import { LightningElement, api } from "lwc";

export default class CpmComponentAvailableListView extends LightningElement {
  @api demoComponents;
  
  get hasRows(){
    if(this.demoComponents && this.demoComponents.length > 0){
      return true;
    }
    return false;
  }
}