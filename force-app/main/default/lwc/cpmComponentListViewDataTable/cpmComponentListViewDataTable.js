import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class CpmComponentAvailableListView extends NavigationMixin(
  LightningElement
) {
  @api columnConfig;
  @api pkField;
  @track rows;
  _selectedRow;

  @api
  get rowData() {
    return this.rows;
  }

  get hasRows(){
    if(this.rowData && this.rowData.length > 0){
      return true;
    }
    return false;
  }


  set rowData(value) {
    if (typeof value !== "undefined") {
      this.rows = value;
    }
  }

  reformatRows = function (rowData) {
    let colItems = this.columnConfig;
    let reformattedRows = [];

    for (let i = 0; i < rowData.length; i++) {
      let rowDataItems = [];

      for (let j = 0; j < colItems.length; j++) {
        let colClass = "slds-truncate slds-is-resizable slds-is-sortable";
        if (colItems[j].hiddenOnMobile) {
          colClass = colClass + " hiddenOnMobile";
        }

        let fieldValue = "";

        if (
          undefined === rowData[i][colItems[j].fieldName] ||
          colItems[j].type !== "richText"
        ) {
          fieldValue = rowData[i][colItems[j].fieldName];
        } else {
          fieldValue = rowData[i][colItems[j].fieldName].replace(
            /(<([^>]+)>)/gi,
            ""
          );
        }

        rowDataItems.push({
          value: fieldValue,
          label: colItems[j].label,
          type: colItems[j].type,
          class: colClass,
          columnId: "col" + j + "-" + rowData[i][this.pkField],
          isPhone: colItems[j].type === "phone",
          isEmail: colItems[j].type === "email",
          isRichText: colItems[j].type === "richText",
          isBoolean: colItems[j].type === "boolean",
          isOther:
            colItems[j].type !== "phone" &&
            colItems[j].type !== "email" &&
            colItems[j].type !== "boolean" &&
            colItems[j].type !== "richText"
        });
      }
      reformattedRows.push({
        data: rowDataItems,
        pk: rowData[i][this.pkField]
      });
    }
    return reformattedRows;
  };

  navigateToRecordViewPage(recordId) {
    // View a custom object record.
    this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: 'Cpm_Component_Package__c', // objectApiName is optional
            actionName: 'view'
        }
    }).then(generatedUrl => {
            window.open(generatedUrl);
        });
}

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case "show_details":
        console.log("Showing Details: " + JSON.stringify(row));
        this.navigateToRecordViewPage(event.detail.row.Id);
        break;
      case "delete":
        console.log("Deleting Record: " + JSON.stringify(row));
        break;
      default:
        break;
    }
  }
}