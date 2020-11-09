import { LightningElement, track, wire } from "lwc";
import { subscribe, onError } from "lightning/empApi";

import APXAvailableDemoComponents from "@salesforce/apex/CpmComponentController.getAvailableComponents";
import APXInstalledDemoComponents from "@salesforce/apex/CpmComponentController.getInstalledComponents";

export default class CmpHomeLayoutManager extends LightningElement {
  availableDemoComponents;
  installedDemoComponents;

  channelName = "/event/CPM_Component_Update__e";
  subscription = {};
  
  @track calvSearchstring = '';
  @track cinstSearchstring = '';

  @track error;

  connectedCallback() {
    this.handleSubscribe();
    this.registerErrorListener();
  }

  @wire(APXAvailableDemoComponents, {searchString: '$calvSearchstring'})
  wiredAPXAvailableDemoComponents({ error, data }) {
      if (data) {
        console.log("CmpHomeLayoutManager.wiredAPXAvailableDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);
        let dataloop = [];
        for (let i = 0; i < data.length; i++) {
          let tempRecord = Object.assign({}, data[i]);
          tempRecord.Record_Url = '/'+data[i].Id;
          if(undefined !== data[i].Description__c){ 
            let newDescription = data[i].Description__c;
              if(newDescription.length > 60){ 
                tempRecord.Description_Short = newDescription.substring(0, 60) + '...';
              }else{
                tempRecord.Description_Short = newDescription;
              }
        
          }
          dataloop.push(tempRecord);
        }

        this.availableDemoComponents = dataloop;
        this.error = undefined;
      } else if (error) {
          this.error = error;
          console.log(`CmpHomeLayoutManager.wiredAPXAvailableDemoComponents ERROR: ${JSON.stringify(error)}`);
          this.serviceItems = undefined;
      }
  }


  @wire(APXInstalledDemoComponents, {searchString: '$cinstSearchstring'})
  wiredAPXInstalledDemoComponents({ error, data }) {
      if (data) {
        console.log("CmpHomeLayoutManager.wiredAPXAvailableDemoComponents SUCCESS");
        console.log(`Found ${data.length} installedDemoComponents`);
        let dataloop = [];
        for (let i = 0; i < data.length; i++) {
          let tempRecord = Object.assign({}, data[i]);
          tempRecord.Record_Url = '/'+data[i].Id;

          if(tempRecord.Installed__c && tempRecord.Installation_Type__c === 'Package'){
            tempRecord.Is_Package_Installed_Type = true;
          }else{
            tempRecord.Is_Package_Installed_Type = false;
          }

          if(tempRecord.Installed__c && tempRecord.Installation_Type__c === 'Source'){
            tempRecord.Is_Source_Installed_Type = true;
          }else{
            tempRecord.Is_Source_Installed_Type = false;
          }

          if(undefined !== data[i].Description__c){ 
            let newDescription = data[i].Description__c;
              if(newDescription.length > 60){ 
                tempRecord.Description_Short = newDescription.substring(0, 60) + '...';
              }else{
                tempRecord.Description_Short = newDescription;
              }
        
          }
          dataloop.push(tempRecord);
        }

        this.installedDemoComponents = dataloop;
        this.error = undefined;
      } else if (error) {
          this.error = error;
          console.log(`CmpHomeLayoutManager.APXInstalledDemoComponents ERROR: ${JSON.stringify(error)}`);
          this.serviceItems = undefined;
      }
  }




  
  doDemoComponentRefresh() {
    APXAvailableDemoComponents()
      .then((data) => {
        console.log("CmpHomeLayoutManager.APXAvailableDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);
        let dataloop = data;

        for (let i = 0; i < dataloop.length; i++) {
          dataloop[i].Record_Url = '/'+dataloop[i].Id;
          if(undefined !== dataloop[i].Description__c){ 
            let newDescription = dataloop[i].Description__c;
              if(newDescription.length > 60){ 
                dataloop[i].Description_Short = newDescription.substring(0, 60) + '...';
              }else{
                dataloop[i].Description_Short = newDescription;
              }
        
          }
        }

        this.availableDemoComponents = dataloop;
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.log(
          `CmpHomeLayoutManager APXAvailableDemoComponents ERROR: ${JSON.stringify(
            error
          )}`
        );
      });

    APXInstalledDemoComponents({ searchString: null })
      .then((data) => {
        console.log("CmpHomeLayoutManager.APXInstalledDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);

        let dataloop = data;

        for (let i = 0; i < dataloop.length; i++) {
          dataloop[i].Record_Url = '/'+dataloop[i].Id;

          if(dataloop[i].Installed__c && dataloop[i].Installation_Type__c === 'Package'){
            dataloop[i].Is_Package_Installed_Type = true;
          }else{
            dataloop[i].Is_Package_Installed_Type = false;
          }

          if(dataloop[i].Installed__c && dataloop[i].Installation_Type__c === 'Source'){
            dataloop[i].Is_Source_Installed_Type = true;
          }else{
            dataloop[i].Is_Source_Installed_Type = false;
          }

        }

        this.installedDemoComponents = dataloop;
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.log(
          `CmpHomeLayoutManager APXInstalledDemoComponents ERROR: ${JSON.stringify(
            error
          )}`
        );
      });
  }


  get getIDs() {
    return this.record;
  }

  // Handles subscribe button click
  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = function (response) {
      console.log("New Component Update message received: ", JSON.stringify(response));
      this.doDemoComponentRefresh();

      // Response contains the payload of the new message received
    }.bind(this);

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log("Subscription request sent to: ",JSON.stringify(response.channel));
      this.subscription = response;
      this.toggleSubscribeButton(true);
    });
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }


  hanldeCalvSearchstring(event) {
    this.calvSearchstring = event.detail;
    console.log(`hanldeCalvSearchstring: ${this.calvSearchstring}`);
  }


  hanldeCinstSearchstring(event) {
    this.cinstSearchstring = event.detail;
    console.log(`hanldeCinstSearchstring: ${this.cinstSearchstring}`);
  }




}