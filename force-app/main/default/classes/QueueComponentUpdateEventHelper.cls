public with sharing class QueueComponentUpdateEventHelper {
    public static final String FLAG_TRUE = 'true';
    public static final String FLAG_FALSE = 'false';

    public static final String FIELD_DELETE_FLAG = 'Delete_Flag__c'; 
    public static final String FIELD_DEMO_COMPONENT_ID = 'Demo_Component_Id__c'; 
    public static final String FIELD_DEMO_COMPONENT_JSON = 'Demo_Component_JSON__c';
    public static final String FIELD_INSERT_FLAG = 'Insert_Flag__c';
    public static final String FIELD_UPDATE_FLAG = 'Update_Flag__c';

    @future (callout = true )
    public static void publishAsyncPlatformEvent(Map<String,String> eventInfo)
    {
        publish(eventInfo);
    }
    
    public static void publishPlatformEvent(Map<String,String> eventInfo)
    {
        publish(eventInfo);
    }

    private static void publish(Map<String, String> eventInfo){
        
        Boolean deleteFlag = False;
        Boolean insertFlag = False;
        Boolean updateFlag = False;

        if(eventInfo.containsKey(FIELD_DELETE_FLAG)){
            deleteFlag = eventInfo.get(FIELD_DELETE_FLAG) == FLAG_TRUE ? True : False;
        }

        if(eventInfo.containsKey(FIELD_INSERT_FLAG)){
            insertFlag = eventInfo.get(FIELD_INSERT_FLAG) == FLAG_TRUE ? True : False;
        }

        if(eventInfo.containsKey(FIELD_UPDATE_FLAG)){
            updateFlag = eventInfo.get(FIELD_UPDATE_FLAG) == FLAG_TRUE ? True : False;
        }

        EventBus.publish(new CPM_Component_Update__e(
            Demo_Component_Id__c = eventInfo.get(FIELD_DEMO_COMPONENT_ID), 
            Delete_Flag__c = deleteFlag, 
            Insert_Flag__c = insertFlag,
            Update_Flag__c = updateFlag,
            Demo_Component_JSON__c = eventInfo.containsKey(FIELD_DEMO_COMPONENT_JSON) ? eventInfo.get(FIELD_DEMO_COMPONENT_JSON) : ''));
    }

    public static String generateId() {

        Integer len = 16;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        return key.substring(0,len);

        /*
        Integer s_num = 1;
            String result = String.valueOf(s_num++);
            return CPM_Async_Event__e.SObjectType.getDescribe().getKeyPrefix() + 
                '0'.repeat(12-result.length()) + result;
        */
    }
    
}