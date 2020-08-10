import { LightningElement, api } from 'lwc';
export default class PackageInstaller extends LightningElement {
  @api recordId;
  greeting = 'World';
  changeHandler(event) {
    this.greeting = event.target.value;
  }
}