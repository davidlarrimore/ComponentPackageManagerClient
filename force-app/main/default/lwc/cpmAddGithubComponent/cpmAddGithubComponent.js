import { LightningElement } from "lwc";
import addGithubComponent from "@salesforce/apex/CpmAddGithubComponentController.runApex";
import cpmUtils from "c/cpmUtils";

export default class CmpAddGithubComponent extends LightningElement {
  githubURL;


  onSubmit() {
    console.log(`githubURL is ${this.githubURL}`);
    addGithubComponent({ githubUrl: this.githubURL })
      .then((result) => {
        console.log("Running addGithubComponent");
        if (result) {
          const evt = new CustomEvent("addeddemocomponent", {
            detail: {
              jobList: result
            }
          });
          this.dispatchEvent(evt);

          this.error = undefined;
        }
      })
      .catch((error) => {
        console.log(
          `addGithubComponent had an error: ${JSON.stringify(error)}`
        );
        this.error = error;

        cpmUtils.showToast(
          this,
          "addGithubComponent Failed",
          `Error Message: ${this.error}`,
          "error"
        );
      });
      console.log(`Resetting form`);
      this.template.querySelector("lightning-input[data-target-id=githubURL]").value = '';
      this.githubURL = '';
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