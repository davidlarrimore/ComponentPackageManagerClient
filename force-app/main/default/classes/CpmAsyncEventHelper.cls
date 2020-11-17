public with sharing class CpmAsyncEventHelper
{
    public static final String STAGE_QUEUED = 'Queued';
    public static final String STAGE_PROCESSING = 'Processing';
    public static final String STAGE_COMPLETED = 'Completed';
    public static final String STAGE_COMPLETED_WITH_WARNINGS = 'Completed with Warnings';        
    public static final String STAGE_COMPLETED_WITH_ERRORS = 'Completed with Errors';   
    public static final String STAGE_FAILED = 'Failed'; 

    public static final String EVENT_LEVEL_SUCCESS = 'success'; 
    public static final String EVENT_LEVEL_INFO = 'info'; 
    public static final String EVENT_LEVEL_WARNING = 'warning'; 
    public static final String EVENT_LEVEL_ERROR = 'error'; 

    public static final String FIELD_APEX_CLASS_NAME = 'Apex_Class_Name__c'; 
    public static final String FIELD_APEX_METHOD_NAME = 'Apex_Method_Name__c'; 
    public static final String FIELD_CURRENT_JOB_STAGE = 'Current_Job_Stage__c';
    public static final String FIELD_EVENT_LEVEL = 'Event_Level__c';
    public static final String FIELD_EVENT_STATUS_MESSAGE = 'Event_Status_Message__c';
    public static final String FIELD_EVENT_STATUS_TITLE = 'Event_Status_Title__c';
    public static final String FIELD_JOB_ID = 'Job_Id__c';
    public static final String FIELD_JOB_NAME = 'Job_Name__c';
    public static final String FIELD_JOB_PARENT_ID = 'Job_Parent_id__c';
    public static final String FIELD_SEND_TOAST_FLAG = 'Send_Toast_Flag__c';

	@future (callout = true )
	public static void publishAsyncPlatformEvent(Map<String,String> jobInfo)
	{
        publish(jobInfo, null);
    }
    
	@future (callout = true )
	public static void publishAsyncPlatformEvent(Map<String,String> jobInfo, Map<String,String> eventInfo)
	{
        publish(jobInfo, eventInfo);
    }
    
	public static void publishPlatformEvent(Map<String,String> jobInfo)
	{
        publish(jobInfo, null);
    }
    
	public static void publishPlatformEvent(Map<String, String> jobInfo, Map<String,String> eventInfo)
	{
        publish(jobInfo, eventInfo);
    }

    private static void publish(Map<String, String> jobInfo, Map<String,String> eventInfo){
        
        Boolean sendToastFlag = true;
        
        if(null == eventInfo){
            sendToastFlag = false;
            eventInfo = new Map<String,String>();
        }

		EventBus.publish(new Cpm_Async_Event__e(
            Apex_Class_Name__c = jobInfo.get(FIELD_APEX_CLASS_NAME), 
            Job_Id__c = jobInfo.get(FIELD_JOB_ID), 
            Job_Parent_id__c = jobInfo.containsKey(FIELD_JOB_PARENT_ID) ? jobInfo.get(FIELD_JOB_PARENT_ID) : '', 
            Job_Name__c = jobInfo.get(FIELD_JOB_NAME), 
            Current_Job_Stage__c = jobInfo.get(FIELD_CURRENT_JOB_STAGE), 
            Send_Toast_Flag__c = sendToastFlag, 
            Event_Status_Title__c = eventInfo.containsKey(FIELD_EVENT_STATUS_TITLE) ? eventInfo.get(FIELD_EVENT_STATUS_TITLE) : '', 
            Event_Status_Message__c = eventInfo.containsKey(FIELD_EVENT_STATUS_MESSAGE) ? eventInfo.get(FIELD_EVENT_STATUS_MESSAGE) : '', 
            Event_Level__c = eventInfo.containsKey(FIELD_EVENT_LEVEL) ? eventInfo.get(FIELD_EVENT_LEVEL) : EVENT_LEVEL_INFO));
            
    }

    public static String generateId() {

        Integer len = 16;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        return key.substring(0,len);

        /*
        Integer s_num = 1;
           String result = String.valueOf(s_num++);
           return Cpm_Async_Event__e.SObjectType.getDescribe().getKeyPrefix() + 
              '0'.repeat(12-result.length()) + result;
        */
    }
    
}