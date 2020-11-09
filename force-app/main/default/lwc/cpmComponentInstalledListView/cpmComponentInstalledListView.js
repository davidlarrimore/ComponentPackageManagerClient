import { LightningElement, api } from "lwc";

export default class CpmComponentAvailableListView extends LightningElement {
  @api demoComponents;

  get hasRows(){
    if(this.demoComponents && this.demoComponents.length > 0){
      return true;
    }
    return false;
  }
   
  updateSearch(event) {
    this.progressValue = event.target.value;
    // Creates the event with the data.
    const selectedEvent = new CustomEvent("cinstsearchstring", {
      detail: this.progressValue
    });

    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }


}