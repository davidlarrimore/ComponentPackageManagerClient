import { LightningElement, api } from "lwc";

const actions = [
  { label: "Show details", name: "show_details" },
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
      fieldName: "Installed_Version__c",
      label: "Installed Version"
    },
    {
      fieldName: "Update_Available__c",
      label: "Update Available",
      type: "boolean"
    }
  ];
}
