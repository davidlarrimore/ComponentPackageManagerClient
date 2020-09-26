public with sharing class QueuePlatformEventHelper
{
	@future (callout = true )
	public static void publishAsyncPlatformEvent(Map<String,String> jobInfo, String status)
	{
        publish(jobInfo, status, null);
    }
    
	@future (callout = true )
	public static void publishAsyncPlatformEvent(Map<String,String> jobInfo, String status, Map<String,String> toastInfo)
	{
        publish(jobInfo, status, toastInfo);
    }
    
	public static void publishPlatformEvent(Map<String,String> jobInfo, String status)
	{
        publish(jobInfo, status, null);
    }
    
	public static void publishPlatformEvent(Map<String, String> jobInfo, String status, Map<String,String> toastInfo)
	{
        publish(jobInfo, status, toastInfo);
    }

    private static void publish(Map<String, String> jobInfo, String status, Map<String,String> toastInfo){

        if(null == toastInfo){
            toastInfo = new Map<String,String>{'Send_Toast__c' => 'false'};
        }

		EventBus.publish(new CPM_Async_Event__e(
            ApexClass_Name__c = jobInfo.get('ApexClassName'), 
            AsyncApexJob_Id__c = jobInfo.get('jobId'), 
            AsyncApexJob_Parent_Id__c = jobInfo.containsKey('parentJobId') ? jobInfo.get('parentJobId') : null, 
            AsyncApexJob_Name__c = jobInfo.get('jobName'), 
            AsyncApexJob_Status__c = status, 
            Send_Toast__c = true, 
            Toast_Title__c = toastInfo.containsKey('Toast_Title__c') ? toastInfo.get('Toast_Title__c') : null, 
            Toast_Message__c = toastInfo.containsKey('Toast_Message__c') ? toastInfo.get('Toast_Message__c') : null, 
            Toast_Variant__c = toastInfo.containsKey('Toast_Variant__c') ? toastInfo.get('Toast_Variant__c') : null, 
            Toast_Mode__c = toastInfo.containsKey('Toast_Mode__c') ? toastInfo.get('Toast_Mode__c') : null));
    }
    
}