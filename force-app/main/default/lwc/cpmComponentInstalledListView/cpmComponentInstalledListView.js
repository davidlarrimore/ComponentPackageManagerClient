import { LightningElement, api } from "lwc";

const actions = [
  { label: "Show details", name: "show_details" },
];

export default class CpmComponentAvailableListView extends LightningElement {
  @api demoComponents;

  cols = [
    {
      fieldName: "Install_Date__c",
      label: "Install Date",
      type: "date-local"
    }, 
    {
      fieldName: "Title__c",
      label: "Title"
    },
    {
      fieldName: "Installation_Type__c",
      label: "Installed Type"
    },   
    {
      fieldName: "Update_Available__c",
      label: "Update Available",
      type: "boolean"
    },
    {
      type: "action",
      typeAttributes: { rowActions: actions, menuAlignment: "right" }
    }
  ];
}
