public with sharing class CpmComponentPackageUpdateEventHelper {
    public static final String FLAG_TRUE = 'true';
    public static final String FLAG_FALSE = 'false';

    public static final String FIELD_DELETE_FLAG = 'Delete_Flag__c'; 
    public static final String FIELD_DEMO_COMPONENT_ID = 'Cpm_Component_Package_Id__c'; 
    public static final String FIELD_DEMO_COMPONENT_JSON = 'Cpm_Component_Package_JSON__c';
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

        EventBus.publish(new Cpm_Component_Package_Update__e(
            Cpm_Component_Package_Id__c = eventInfo.get(FIELD_DEMO_COMPONENT_ID), 
            Delete_Flag__c = deleteFlag, 
            Insert_Flag__c = insertFlag,
            Update_Flag__c = updateFlag,
            Cpm_Component_Package_JSON__c = eventInfo.containsKey(FIELD_DEMO_COMPONENT_JSON) ? eventInfo.get(FIELD_DEMO_COMPONENT_JSON) : ''));
    } 
}