import { LightningElement, api } from "lwc";

const actions = [
  { label: "Show details", name: "show_details" },
  { label: "Install", name: "install" }
];

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
      fieldName: "Description__c",
      label: "Description",
      type: "richText"
    },
    {
      type: "action",
      typeAttributes: { rowActions: actions, menuAlignment: "right" }
    }    
  ];
}
