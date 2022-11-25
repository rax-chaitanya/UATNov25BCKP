// Helper class containing common variables and methods across platform event handlers

public with sharing class PlatformEventHandlerHelper {

    @TestVisible private static Boolean allEventsInstanceActive = false;    // Allows test to simulate the absence of the Custom Setting controlling Platform Event generation activity
    @TestVisible private static Boolean objectEventsInstanceActive = false;    // Allows test to simulate the absence of the Custom setting controlling Platform Event generation activity
    @TestVisible private static String invalidProfilesTestData;    // A list of profiles separated by commas which are used to control which profiles may generate platform events
    @TestVisible private static String skipUserIdTestData;    // If a test is running override the custom label allowing for easier testing
    @TestVisible private static String fmwApiUserIdTestData;    // If a test is running override the custom label allowing for easier testing

    // Metadata record containing common information about all platform events
    public static final Platform_Event_Manager__mdt PLATFORM_EVENT_ALL_EVENTS_METADATA = [SELECT Id, Active__c, Batch_Mode_Enabled__c, cLog_Name__c, cLog_Action_Name__c, Restricted_Profiles__c
                                                                                          FROM Platform_Event_Manager__mdt 
                                                                                          WHERE DeveloperName = 'All_Events' LIMIT 1];

    public static final String SOURCE_APP = 'App';    // If the platform event was not created from a batch job then set the source as 'App'
    public static final String SOURCE_BATCH = 'Batch';    // If the platform event was created from a batch job then set the source as 'Batch'
    public static final String CMS_DESTINATION_CODE = 'CMS';    // The destination code for CMS
    public static final String OIC_DESTINATION_CODE = 'OIC';    // The destination code for OIC
    public static final String STASH_DESTINATION_CODE = 'Stash';    // The destination code for Stash
    public static final String NONE_DESTINATION_CODE = 'None';    // The destination code for None
    public static final String INSERT_OPERATION_CODE = 'insert';    // The operation code for inserts
    public static final String UPDATE_OPERATION_CODE = 'update';    // The operation code for updates
    public static final String DELETE_OPERATION_CODE = 'delete';    // The operation code for deletions
    public static final String UNDELETE_OPERATION_CODE = 'undelete';    // The operation code for undeleteions
    public static final String PROCESSED_PUBLISHER_STATUS_CODE = 'Processed';    // The platform event publisher status code for Processed records
    public static final String PUBLISHED_PUBLISHER_STATUS_CODE = 'Published';    // The platform event publisher status code for Published records
    public static final String PLATFORM_EVENT_DELIMITER = ',';    // The delimiter to separate platform event values
    public static final String PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER = ';';    // The delimiter to separate platform event destination system values
    public static final String PLATFORM_EVENT_PAYLOAD_START_CHARACTER = '[';    // The character used at the beginning of a platform event payload field
    public static final String PLATFORM_EVENT_PAYLOAD_END_CHARACTER = ']';    // The character used at the end of a platform event payload field
    public static final Integer PLATFORM_EVENT_FIELD_SIZE = 130000;    // The number of characters allowed in one of the fields on the platform event

    private static List<Profile> userProfileList = null;    // Contains the user's profile - static in order to avoid multiple soql queries if more than one helper is used during a transaction
    private static Set<Id> skipUserIdSet = null;    // Set containing all of the ids in the SkipUserId custom label
    private static Set<Id> fmwApiUserIdSet = null;    // Set containing all of the ids in the FMW_API_User custom label
    private static Set<Id> governmentRecordTypeSet = null;    // Set containing all of the government record type ids
    private static Set<String> restrictedUserProfileSet = null;    // Set containing all of the profiles which may not generate platform events

    private Platform_Event_Manager__mdt platformEventMetadata;    // The custom metadata record for the handler linked to this helper
    private Platform_Event_Publisher__c platformEventPublisher;    // Contains the platform event publisher which is related to the staging records being stored on the platform event being iterated over in the batch job
    private sObject platformEvent;    // Contains the platform event representing the handler being iterated over in the batch job
    private Integer numRecordsInPlatformEvent = 0;    // Contains the number of records currently in the platform event

    // Always use this constructor when creating a new instance of this helper from a platform event controller class outside of the PlatformEventPublishBatch class - initialize all non-static non-constants
    public PlatformEventHandlerHelper(String platformEventMetadataRecord) {
        platformEventMetadata = [SELECT Id, Active__c, cLog_Action_Name__c, cLog_Name__c, Num_Records_Allowed_Per_Platform_Event__c, sObject_Name__c
                                 FROM Platform_Event_Manager__mdt
                                 WHERE DeveloperName = :platformEventMetadataRecord LIMIT 1];
    }

    // Publish platform events for an individual object. This is not used for batches of records because it would not be bulkified.
    public void publishPlatformEvents(List<sObject> platformEventList) {
        List<Database.SaveResult> results = EventBus.publish(platformEventList);    // Publish events
        
        List<cLog__c> cLogList = new List<cLog__c>();    // Create list to hold error logs
                
        // Inspect publishing result for each event
        for(Integer i = 0; i < results.size(); i++) {
            if(results[i].isSuccess()) {
                System.debug('Successfully published event');
            } else {
                String errorString = '';
        
                // Generate the error string
                for(Integer j = 0; j < results[i].getErrors().size(); j++) {    
                    String errorAppend = 'Error returned: ' + results[i].getErrors()[j].getStatusCode() + ' - ' + results[i].getErrors()[j].getMessage() + '\n';
                    errorString = errorString + errorAppend;
                }
                        
                cLog__c errorLog = new cLog__c(Name = platformEventMetadata.cLog_Name__c,
                                               Action_Name__c = platformEventMetadata.cLog_Action_Name__c,
                                               Error_Description__c = errorString);
        
                cLogList.add(errorLog);
            }
        }
        
        // If any errors need to be logged insert the records here TODO: add try catch block to create cLog records
        if(!cLogList.isEmpty()) {
            try {
                insert cLogList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }

    // Builds the Platform Event Publisher buffer
    public List<Platform_Event_Publisher__c> buildPlatformEventPublisherBuffer(Integer newListSize) {
        List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();    // List containing the Platform Event Publisher records to create for the buffer
        List<Platform_Event_Publisher__c> platformEventPublisherBuffer = new List<Platform_Event_Publisher__c>();    // List containing the already existing Platform Event Publisher buffer records (if any)
        Integer numPublishers;    // The number of publishers required for the group of records being iterated over

        // If there is going to be a remainder then add 1
        if(newListSize > (Integer)platformEventMetadata.Num_Records_Allowed_Per_Platform_Event__c && math.mod(newListSize, (Integer)platformEventMetadata.Num_Records_Allowed_Per_Platform_Event__c) > 0) {
            numPublishers = newListSize / (Integer)platformEventMetadata.Num_Records_Allowed_Per_Platform_Event__c + 1;
        }
        // If there is no remainder then add nothing
        else if(newListSize > (Integer)platformEventMetadata.Num_Records_Allowed_Per_Platform_Event__c) {
            numPublishers = newListSize / (Integer)platformEventMetadata.Num_Records_Allowed_Per_Platform_Event__c;
        }
        // If newListSize is less than or equal to the number of records allowed for the platform event then set numPublishers to 1
        else {
            numPublishers = 1;
        }

        // Try to get platform event publisher records
        platformEventPublisherBuffer = [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Publisher_Status__c = null ORDER BY CreatedDate DESC LIMIT :numPublishers];

        // Create and insert the necessary publisher records if we didn't have enough available already in the database
        for(Integer i = 0; i < numPublishers - platformEventPublisherBuffer.size(); i++) {
            platformEventPublisherList.add(new Platform_Event_Publisher__c());
        }

        // Insert staged platform events
        if(!platformEventPublisherList.isEmpty()) {
            try {
                insert platformEventPublisherList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        // If there needs to be more platform event publisher records inserted for this run then get the remaining ones
        if(platformEventPublisherList.size() > 0) {
            platformEventPublisherBuffer.addAll(platformEventPublisherList);
        }

        return platformEventPublisherBuffer;
    }

    // Determines if any record has been changed in any way
    public List<sObject> getChangedRecordList(String triggerOperation, List<sObject> newList, Map<Id, sObject> oldMap) {

        List<sObject> changedsObjectList = new List<sObject>();

        if(triggerOperation != UPDATE_OPERATION_CODE) {
            return changedsObjectList;
        }

        // Make a deepclone of the newList record and oldMap record without the ids, standard date fields, and autonumber fields
        for(sObject theRecord : newList) {
            if(theRecord.clone(true, true, false, false) == oldMap.get(theRecord.Id).clone(true, true, false, false)) {
                System.debug('!!!!!!!!!!!!!!!!!!!!!The records are equivalent');
            } else {
                System.debug('!!!!!!!!!!!!!!!!!!!!!The records are not equivalent');
            }
        }



        return changedsObjectList;

    }

    // Determine if the platform event is active
    public Boolean platformEventActive() {
        // If a test is running use the testing variables so we don't have to get the Custom Setting
        if(Test.isRunningTest()) {
            if(allEventsInstanceActive && objectEventsInstanceActive) {
                return true;
            }
        }
        // If a test is not running use the Custom Setting configured in the org
        else if(PLATFORM_EVENT_ALL_EVENTS_METADATA.Active__c && platformEventMetadata.Active__c) {
            return true;
        }

        return false;
    }

    // Builds skipUserIdSet, if the Set is null, and determines if the user's id is in the SkipUserIDs custom label
    public Boolean userInSkipUserIdSet() {
        // If skipUserIdSet is null then populate it before returning it
        if(skipUserIdSet == null) {
            skipUserIdSet = new Set<Id>();

            if(Test.isRunningTest()) {
                skipUserIdSet.addAll((List<Id>)skipUserIdTestData.split(','));
            } else {
                skipUserIdSet.addAll((List<Id>)Label.SkipUserIDs.split(','));
            }
        }

        return skipUserIdSet.contains(UserInfo.getUserId());
    }

    // Builds fmwApiUserIdSet, if the Set is null, and determines if the user's id is in the FMW_API_User custom label
    public Boolean userInFmwApiUserIdSet() {
        // If fmwApiUserIdSet is null then populate it before returning it
        if(fmwApiUserIdSet == null) {
            fmwApiUserIdSet = new Set<Id>();

            if(Test.isRunningTest()) {
                fmwApiUserIdSet.addAll((List<Id>)fmwApiUserIdTestData.split(','));
            } else {
                fmwApiUserIdSet.addAll((List<Id>)Label.FMW_API_User.split(','));
            }
        }

        return fmwApiUserIdSet.contains(UserInfo.getUserId());
    }

    // Builds restrictedUserProfileSet, if the List is null, and determines if the user's profile is able to generate platform ids
    public Boolean userProfileIsRestricted() {
        // If restrictedUserProfileSet is null then populate it
        if(restrictedUserProfileSet == null) {
            restrictedUserProfileSet = new Set<String>();

            if(Test.isRunningTest()) {
                restrictedUserProfileSet.addAll(invalidProfilesTestData.split(','));
            } else {
                restrictedUserProfileSet.addAll(PLATFORM_EVENT_ALL_EVENTS_METADATA.Restricted_Profiles__c.split(','));
            }
        }

        return restrictedUserProfileSet.contains(getUserProfile()[0].Name);
    }

    // Builds governmentRecordTypeSet, if the Set is null, and determines if the given record type id is present within it
    public Boolean recordTypeIdIsGovtRecordType(Id recordTypeId) {
        // If governmentRecordTypeSet is null the populate it
        if(governmentRecordTypeSet == null) {
            governmentRecordTypeSet = new Set<Id>();

            governmentRecordTypeSet.addAll((List<Id>)Label.GovernmentRecordTypes.split(','));
        }

        return governmentRecordTypeSet.contains(recordTypeId);
    }

    // Gets the platform event's metadata which is located on the platform event linked with this helper
    public Platform_Event_Manager__mdt getPlatformEventMetadata() {
        return platformEventMetadata;
    }

    // Gets the platform event which is being iterated over in the batch job
    public sObject getPlatformEvent() {
        return platformEvent;
    }

    // Sets the platform event which is being iterated over in the batch job
    public void setPlatformEvent(sObject platformEvent) {
        this.platformEvent = platformEvent;
    }

    // Gets the platform event publisher which is being iterated over in the batch job
    public Platform_Event_Publisher__c getPlatformEventPublisher() {
        return platformEventPublisher;
    }

    // Sets the platform event publisher which is being iterated over in the batch job
    public void setPlatformEventPublisher(Platform_Event_Publisher__c platformEventPublisher) {
        this.platformEventPublisher = platformEventPublisher;
    }

    // Gets the number of records which are currently stored wtihin the platform event
    public Integer getNumRecordsInPlatformEvent() {
        return numRecordsInPlatformEvent;
    }

    // Sets the number of records which are currently stored within the platform event
    public void setNumRecordsInPlatformEvent(Integer numRecordsInPlatformEvent) {
        this.numRecordsInPlatformEvent = numRecordsInPlatformEvent;
    }

    // Get the user's profile - reduces soql queries used during transaction in case the public methods in this class are called multiple times
    private List<Profile> getUserProfile() {
        if(userProfileList == null) {
            List<Profile> tempProfileList = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];

            userProfileList = tempProfileList;
        }

        return userProfileList;
    }

}