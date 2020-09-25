public class QueueUpdateComponentFromPackageVersion implements Queueable, Database.AllowsCallouts {
  /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
  public final String JOBNAME = 'Update Component from GithubUser';
  Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentFromPackageVersion.class.getName()};

  public String getJobName() {
  return this.JOBNAME;
  }

  public String getJobInfo(String key) {
  return this.jobInfo.get(key);
  }

  public Map<String,String> getJobInfo() {
  return this.jobInfo;
  }    

  /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
  Id demoComponentId = null;
  List<String> subscriberPackageVersionIds = new List<String>();
  Map<String,String> options = new Map<String,String>();     

  /*************CONSTRUCTORS*************/      
  public QueueUpdateComponentFromPackageVersion(ID parentJobId,List<String> subscriberPackageVersionIds,Map<String, String> options) {
    this.subscriberPackageVersionIds = subscriberPackageVersionIds;
    this.options = options;
    this.jobInfo.put('parentJobId', parentJobId);
  }

  public QueueUpdateComponentFromPackageVersion(List<String> subscriberPackageVersionIds,Map<String, String> options) {
    this.subscriberPackageVersionIds = subscriberPackageVersionIds;
    this.options = options;
  }

  public QueueUpdateComponentFromPackageVersion(List<String> subscriberPackageVersionIds) {
    this.subscriberPackageVersionIds = subscriberPackageVersionIds;
  }

  /*************EXECUTE METHOD*************/   
  public void execute(QueueableContext context) {
  /*************STANDARD JOB ID SETTER*************/
  this.jobInfo.put('jobId', context.getJobId());

    EventBus.publish(
      new CPM_Async_Event__e(
        ApexClass_Name__c = QueueUpdateComponentFromPackageVersion.class
          .getName(),
        AsyncApexJob_Id__c = context.getJobId(),
        AsyncApexJob_Name__c = this.getJobName(),
        AsyncApexJob_Status__c = 'Processing',
        Send_Toast__c = false
      )
    );

    doLater(jobInfo, subscriberPackageVersionIds, options);
  }

  @future(callout=true)
  public static void doLater(
    Map<String, String> jobInfo,
    List<String> subscriberPackageVersionIds,
    Map<String, String> options
  ) {
    List<MetadataInstalledPackageResponseRecord> recordsToProcess = new List<MetadataInstalledPackageResponseRecord>();
    System.debug('Start QueueUpdateComponentFromPackageVersion.execute');
    for (String subscriberPackageVersionId : subscriberPackageVersionIds) {
      MetadataSubscriberPackageVersion subscriberPackageVersion = MetadataAPIHelper.getSubscriberPackageVersion(
        subscriberPackageVersionId
      );
      if (subscriberPackageVersion != null) {
        System.debug(
          'Successfully found Subscriber Package Version Info from Tooling API'
        );
        MetadataSubscriberPackage subscriberPackage = MetadataAPIHelper.getSubscriberPackage(
          subscriberPackageVersion.subscriberPackageId
        );
        if (subscriberPackage != null) {
          MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
          metadataInstalledPackageResponseRecord.subscriberpackage = subscriberPackage;
          metadataInstalledPackageResponseRecord.subscriberPackageVersion = subscriberPackageVersion;
          recordsToProcess.add(metadataInstalledPackageResponseRecord);
          System.debug(
            'Successfully found Subscriber Package Info from Tooling API'
          );
        } else {
          System.debug(
            'ERROR: Could not find Subscriber Package Version Info from Tooling API'
          );
        }
      }
    }

    /*
     * Uses Subscriber_Package_Version_Id to find Component and updates. If none is found, it creates a new component. This one includes an ID method that allows you to create a dependency on the spot....
     * Options:
     *  - parentDemoComponentId = '<Id of parent/depender component>' (If set, We need to create a package dependency as well)
     *  - installedFlag = 'true' or 'false' (This package is installed, we should update fields appropriatley)
     *
     * QueueUpdateComponentFromPackageVersion.updateComponentFromPackageVersion(record.subscriberPackage, record.subscriberPackageVersion, options);
     */
    for (MetadataInstalledPackageResponseRecord record : recordsToProcess) {
      Boolean newComponentFlag = false;
      Boolean createDependencyFlag = false;

      Demo_Component__c demoComponent = new Demo_Component__c();
      System.debug(
        'attempting to find Demo Component via Subscriber Package Id or Subscriber Package Version Id'
      );
      List<Demo_Component__c> demoComponentLookup = [
        SELECT
          Id,
          Latest_Subscriber_Package_Version_Id__c,
          Title__c,
          Package_Installed_Subscriber_Version_Id__c,
          Subscriber_Package_Id__c,
          Github_Repository_URL__c,
          Package_Install_Type_Flag__c
        FROM Demo_Component__c
        WHERE
          Subscriber_Package_Id__c = :record.subscriberPackage.id
          OR Latest_Subscriber_Package_Version_Id__c = :record.subscriberPackageVersion.id
        LIMIT 1
      ];

      if (demoComponentLookup.size() > 0) {
        demoComponent = demoComponentLookup[0];
        System.debug(
          'This package already exists as part of component, ' +
          demoComponent.Title__c +
          ', checking Latest_Subscriber_Package_Version_Id__c.'
        );
        if (
          demoComponentLookup[0].Latest_Subscriber_Package_Version_Id__c ==
          record.subscriberPackageVersion.id
        ) {
          System.debug(
            'Component Latest_Subscriber_Package_Version_Id__c is the same as provided Subscriber Package Version ID'
          );
        } else {
          System.debug(
            'Found a different (And we can assume updated) Latest_Subscriber_Package_Version_Id__c. We will update existing: Provided ' +
            record.subscriberPackageVersion.id +
            ' vs Latest ' +
            demoComponent.Latest_Subscriber_Package_Version_Id__c
          );
        }
        demoComponent = demoComponentLookup[0];
      } else {
        newComponentFlag = true;
      }

      if (newComponentFlag) {
        CPM_Async_Event__e asyncApexJobEvent = new CPM_Async_Event__e(
          Toast_Message__c = 'Checking for Installed Packages',
          Toast_Title__c = 'Checking for Installed Packages',
          Toast_Variant__c = 'success'
        );

        EventBus.publish(asyncApexJobEvent);

        System.debug('No component found. Creating.');
        System.debug(
          'Since this is a new component, we are going to set basic info'
        );
        demoComponent.Source_Install_Type_Flag__c = false;
        demoComponent.SFDX_Package_Enabled_Flag__c = false;
        demoComponent.Package_Install_Type_Flag__c = true;
        demoComponent.Title__c = record.subscriberPackage.name;
        demoComponent.Description__c = record.subscriberPackage.description;
      }

      demoComponent.Subscriber_Package_Id__c = record.subscriberPackage.id;
      demoComponent.Package_Name__c = record.subscriberPackage.name;
      demoComponent.Latest_Subscriber_Package_Version_Id__c = record.subscriberPackageVersion.id;
      demoComponent.Latest_Package_Version__c = record.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
      demoComponent.Latest_Package_Version_Name__c = record.subscriberPackageVersion.name;
      demoComponent.Last_Fetched__c = Datetime.Now();

      //We only process this if installedFlag is true, which means it came from a getInstalledPackages call
      if (
        options.containsKey('installedFlag') &&
        options.get('installedFlag') == 'true'
      ) {
        system.debug('Found Installed Flag, processing');

        demoComponent.Installed__c = true;
        demoComponent.Installation_Type__c = 'Package';

        if (demoComponent.Package_Install_Type_Flag__c) {
          system.debug('Found Installed Flag, processing');
          demoComponent.Installed_Version_Tracking_Method__c = 'SFDX Project';
        } else {
          demoComponent.Installed_Version_Tracking_Method__c = 'None';
        }

        demoComponent.Package_Installed_Subscriber_Version_Id__c = record.subscriberPackageVersion.id;
        demoComponent.Package_Installed_Version_Name__c = record.subscriberPackageVersion.name;
        demoComponent.Package_Installed_Version_Number__c = record.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
      }

      upsert demoComponent;

      if (options.containsKey('parentDemoComponentId')) {
        System.debug('parentDemoComponentId found, creating dependency');

        List<Demo_Component__c> parentDemoComponent = [
          SELECT Id
          FROM Demo_Component__c
          WHERE Id = :options.get('parentDemoComponentId')
          LIMIT 1
        ];
        if (parentDemoComponent.size() > 0) {
          System.debug('Found Parent Demo Component');
          if (!newComponentFlag) {
            List<Component_Dependency__c> packageDependencyLookup = [
              SELECT Id, Demo_Component__c, Dependent_Component__c
              FROM Component_Dependency__c
              WHERE
                Demo_Component__c = :parentDemoComponent[0].Id
                AND Dependent_Component__c = :demoComponentLookup[0].Id
              LIMIT 1
            ];
            if (packageDependencyLookup.size() > 0) {
              System.debug('Package Dependency Already Exists, skipping');
              createDependencyFlag = false;
            }
          } else {
            createDependencyFlag = true;
          }

          if (
            options.containsKey('parentDemoComponentId') && createDependencyFlag
          ) {
            System.debug('Creating new Package Dependency');
            Component_Dependency__c packageDependency = new Component_Dependency__c();

            packageDependency.Demo_Component__c = parentDemoComponent[0].Id;
            packageDependency.Dependent_Component__c = demoComponent.Id;
            insert packageDependency;
          }
        } else {
          System.debug('Could not find parent demo component');
        }
      }
    }

    EventBus.publish(
      new CPM_Async_Event__e(
        ApexClass_Name__c = jobInfo.get('ApexClassName'),
        AsyncApexJob_Id__c = jobInfo.get('jobId'),
        AsyncApexJob_Name__c = jobInfo.get('jobName'),
        AsyncApexJob_Status__c = 'Completed',
        Send_Toast__c = false
      )
    );
  }
}
