import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class CpmComponentAvailableListView extends NavigationMixin(LightningElement) {
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
			fieldName: "Installed_Version__c",
			label: "Installed Version"
		},    
		{
			fieldName: "Update_Available__c",
      label: "Update Available",
      type: "boolean"
		}
	];

	handleRowDblClick(event) {
		const demoComponentId = event.detail.pk;
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: demoComponentId,
				objectApiName: "Demo_Component__c",
				actionName: "view"
			}
		});
	}
}
