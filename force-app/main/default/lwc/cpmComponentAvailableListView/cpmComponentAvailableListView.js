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
			fieldName: "Description__c",
      label: "Description",
      type: "richText"
		},   
		{
			fieldName: "POC_Email__c",
			label: "POC E-Mail"
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
