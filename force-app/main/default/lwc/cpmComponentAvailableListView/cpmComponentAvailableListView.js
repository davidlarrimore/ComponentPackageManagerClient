import { LightningElement, api } from "lwc";

const actions = [
  { label: "Show details", name: "show_details" },
  { label: "Install", name: "install" }
];

export default class CpmComponentAvailableListView extends LightningElement {
  @api demoComponents;

  cols = [
    {
      type: "action",
      typeAttributes: { rowActions: actions, menuAlignment: "left" }
    },
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
}
