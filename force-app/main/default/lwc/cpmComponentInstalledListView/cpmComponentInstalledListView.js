import { LightningElement, api } from "lwc";

export default class CpmComponentAvailableListView extends LightningElement {
  @api demoComponents;

  cols = [
		{
			fieldName: "Name",
			label: "Name"
		},
		{
			fieldName: "Title__c",
			label: "Title"
		},
		{
			fieldName: "Update_Available__c",
			label: "Update Available",
		},
		{
			fieldName: "POC_Email__c",
			label: "POC E-Mail"
		}
	];

  onRowClick(event) {
    let target = event.currentTarget;
    const evt = new CustomEvent("rowclick", {
      detail: {
        pk: target.getAttribute("data-pk"),
        domEl: target
      }
    });
    this.dispatchEvent(evt);
    this.highlightSelectedRow(target);
  }

  onRowDblClick(event) {
    let target = event.currentTarget;
    const evt = new CustomEvent("rowdblclick", {
      detail: {
        pk: target.getAttribute("data-pk"),
        domEl: target
      }
    });
    this.dispatchEvent(evt);
  }

  highlightSelectedRow(target) {
    if (this._selectedRow) {
      this._selectedRow.classList.remove("slds-is-selected");
    }
    target.classList.add("slds-is-selected");
    this._selectedRow = target;
  }

  @api
  setSelectedRecord(recordId) {
    let mySelector = `tr[data-pk='${recordId}']`;
    let selectedRow = this.template.querySelector(mySelector);
    if (selectedRow) {
      this.highlightSelectedRow(selectedRow);
    }
  }
}
