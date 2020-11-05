import { LightningElement, track } from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";

import APXAvailableDemoComponents from "@salesforce/apex/CpmComponentController.getAvailableComponents";
import APXInstalledDemoComponents from "@salesforce/apex/CpmComponentController.getInstalledComponents";

export default class CmpHomeLayoutManager extends LightningElement {
  availableDemoComponents;
  installedDemoComponents;
  channelName = "/event/CPM_Component_Update__e";

  @track error;

  connectedCallback() {
    this.doDemoComponentRefresh();
    this.handleSubscribe();
    this.registerErrorListener();
  }

  doDemoComponentRefresh() {
    APXAvailableDemoComponents({ recordIds: this.jobIds })
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

    APXInstalledDemoComponents({ recordIds: this.jobIds })
      .then((data) => {
        console.log("CmpHomeLayoutManager.APXInstalledDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);

        let dataloop = data;

        for (let i = 0; i < dataloop.length; i++) {
          dataloop[i].Record_Url = '/'+dataloop[i].Id;
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
      console.log("New message received: ", JSON.stringify(response));
      this.doDemoComponentRefresh();

      // Response contains the payload of the new message received
    }.bind(this);

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      this.subscription = response;
      this.toggleSubscribeButton(true);
    });
  }

  // Handles unsubscribe button click
  handleUnsubscribe() {
    this.toggleSubscribeButton(false);

    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, (response) => {
      console.log("unsubscribe() response: ", JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  toggleSubscribeButton(enableSubscribe) {
    this.isSubscribeDisabled = enableSubscribe;
    this.isUnsubscribeDisabled = !enableSubscribe;
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }







}