import { LightningElement, track } from "lwc";
import addGithubComponent from "@salesforce/apex/CpmAddGithubComponentController.runApex";
import Utils from "c/utils";

export default class CmpAddGithubComponent extends LightningElement {
  @track demoComponent;
  githubURL;

  onSubmit() {
    console.log(`githubURL is ${this.githubURL}`);
    addGithubComponent({ githubUrl: this.githubURL })
      .then((result) => {
        console.log("Running addGithubComponent");
        if (result) {
          this.demoComponent = result;
          console.log(
            `Added github component from URL: ${JSON.stringify(
              this.demoComponent
            )}`
          );

          Utils.showToast(
            this,
            "Add was successful",
            `Created new Demo Component: ${this.demoComponent.Title__c}`,
            "success"
          );
          this.error = undefined;
          this.githubURL = "";
        }
      })
      .catch((error) => {
        console.log(
          `addGithubComponent had an error: ${JSON.stringify(error)}`
        );
        this.error = error;
        this.demoComponent = undefined;

        Utils.showToast(
          this,
          "addGithubComponent Failed",
          `Error Message: ${this.error}`,
          "error"
        );
      });
  }

  onGithubURLChange(event) {
    this.githubURL = event.target.value;
  }
  onBlur() {
    this.saveButtonDisabled = !this.validateFields();
  }

  validateFields() {
    let field = null;
    let fields = this.template.querySelectorAll(".validateMe");
    let result = true;
    for (let i = 0; i < fields.length; i++) {
      field = fields[i];
      result = field.checkValidity();
      if (!result) break;
    }
    return result;
  }
}
