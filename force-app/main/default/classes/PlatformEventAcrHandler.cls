// Class which will handle new platform events created on the ACR__e object. 

// How to implement new platform event:
// 1. Copy this class and change the constants within to match the corresponding values for any new platform event as well as all of the object types
// 2. You must implement new versions of stagePlatformEvents() and updateFieldsChanged()

public with sharing class PlatformEventAcrHandler {
    public static final PlatformEventHandlerHelper HELPER = new PlatformEventHandlerHelper('ACR_Events');    // Create helper instance which contains all common methods and variables used between all platform event handlers

    private static Boolean platformEventCreationOnInsertComplete = false;    // Will be set to true if the insert logic is hit
    private static Boolean platformEventCreationOnUpdateComplete = false;    // Prevents recursion on updates when true

    // Create a class (struct) which will contain all fields which would have been stored on the Platform Event Stage object. This class instance will be populated and stringified then stored on the Platform Event Stage object to avoid creating loads of fields
    // for each platform event on the Platform Event Stage object. Will also make query in the platform event batch jobs easy because we just need to grab the stringified data. Each platform event handler will have its own specific fields added to its
    // corresponding struct class.
    public class PlatformEventStagePayloadStruct {
        public String AccountId = null;
        public String Account_Number = null;
        public String ContactId = null;
        public String Destination_System = null;
        public String DP_ContactId = null;
        public String DP_Customer_Id = null;
        public String Id = null;
        public String Old_Contact_Id = null;
        public String Old_Record_Id = null;
        public String Platform_Event_Publisher_Id = null;
        public String Platform_Event_Stage_Id = null;
        public String Platform_Event_Type = null;
        public String Roles = null;
    }

    // Method handles platform events which should be fired on insert
    public static void createPlatformEventsOnInsert(List<AccountContactRelation> newList) {
        platformEventCreationOnInsertComplete = true;
        
        // Determine if the platform event is active and if the user's profile is allowed to generate platform events
        if(!HELPER.platformEventActive() || HELPER.userProfileIsRestricted()) {
            return;
        }

        // Stage new platform events for publishing
        if(System.isBatch() || System.isFuture() || System.isQueueable()) {
            stagePlatformEvents(PlatformEventHandlerHelper.INSERT_OPERATION_CODE, newList, null);
        } else {
            // Turn input into strings for future method call
            String jsonNewList = JSON.serialize(newList);

            stagePlatformEvents(PlatformEventHandlerHelper.INSERT_OPERATION_CODE, jsonNewList, null);
        }
    }

    // Method handles platform events which should be created based on an update
    public static void createPlatformEventsOnUpdate(Map<Id, AccountContactRelation> oldMap, List<AccountContactRelation> newList) {
        // Prevent recursion for updates
        if(platformEventCreationOnUpdateComplete || platformEventCreationOnInsertComplete) {
            return;
        }
        
        // Prevent recursive operations after method called once
        platformEventCreationOnUpdateComplete = true;
        
        // Determine if the platform event is active and if the user's profile is allowed to generate platform events
        if(!HELPER.platformEventActive() || HELPER.userProfileIsRestricted()) {
            return;
        }

        // Stage new platform events for publishing
        if(System.isBatch() || System.isFuture() || System.isQueueable()) {
            stagePlatformEvents(PlatformEventHandlerHelper.UPDATE_OPERATION_CODE, newList, oldMap);
        } else {
            // Turn input into strings for future method call
            String jsonNewList = JSON.serialize(newList);
            String jsonOldMap = JSON.serialize(oldMap);

            stagePlatformEvents(PlatformEventHandlerHelper.UPDATE_OPERATION_CODE, jsonNewList, jsonOldMap);
        }
    }

    // Contains logic which will stage the correct platform events
    private static void stagePlatformEvents(String triggerOperation, List<AccountContactRelation> newList, Map<Id, AccountContactRelation> oldMap) {
        // If the source is a very large batch job then mark the source of the platform events as batch and don't fire the platform events immediately
        if(PlatformEventHandlerHelper.PLATFORM_EVENT_ALL_EVENTS_METADATA.Batch_Mode_Enabled__c) {
            stagePlatformEventDataBatch(triggerOperation, newList, oldMap, PlatformEventHandlerHelper.SOURCE_BATCH);
        } 
        // If the source is from the app or smaller jobs then mark the source of the platform events as app and fire the platform events immediately
        else {
            stagePlatformEventData(triggerOperation, newList, oldMap, PlatformEventHandlerHelper.SOURCE_APP);
        }
    }

    // Contains logic which will stage the correct platform events asyncronously
    @future @testVisible
    private static void stagePlatformEvents(String triggerOperation, String jsonNewList, String jsonOldMap) {
        List<AccountContactRelation> newList = (List<AccountContactRelation>) JSON.deserialize(jsonNewList, List<AccountContactRelation>.class);    // Recreate objects from json strings
        Map<Id, AccountContactRelation> oldMap;    // Map containing the deseriablized oldMap

        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
            oldMap = (Map<Id, AccountContactRelation>) JSON.deserialize(jsonOldMap, Map<Id, AccountContactRelation>.class);
        }
        
        stagePlatformEvents(triggerOperation, newList, oldMap);
    }

    // Contains common platform event staging data logic - because of future methods being unable to be called in a batch or future context the stagePlatformEvent methods are duplicated
    private static void stagePlatformEventData(String triggerOperation, List<AccountContactRelation> newList, Map<Id, AccountContactRelation> oldMap, String source) {
        // The following group of fields will be common across all implementations of this method
        List<Platform_Event_Publisher__c> platformEventPublisherBuffer = HELPER.buildPlatformEventPublisherBuffer(newList.size());    // List containing the buffer of platform event publisher records
        Platform_Event_Publisher__c platformEventPublisher = platformEventPublisherBuffer.remove(0);    // Get the first platform event publisher in the buffer
        List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();    // List of platform event publisher objects to add to the database
        List<Platform_Event_Stage__c> platformEventStageList = new List<Platform_Event_Stage__c>();    // List of platform event staging objects to be inserted into the database
        Platform_Event_Stage__c platformEventStage = new Platform_Event_Stage__c();    // Platform event stage record to create and add to the list
        PlatformEventStagePayloadStruct platformEventPayloadStruct = new PlatformEventStagePayloadStruct();    // Struct used to organize data in order to serialize it so it is able to be unravaelled later during platform event creation
        PlatformEventStagePayloadStruct platformEventPayload;    // The data stored within the payload field of a Platform Event Stage record
        Id platformEventPublisherId = null;
        String destinationSystem;    // The destination system of the data within the platform event
        String serializedStruct;    // The struct (class) which is being serialized and added to the payload field in the Platform Event Stage record
        String payloadSetString = PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_START_CHARACTER;    // Because we need to build a json array start the string to store on the platform event with an open bracket
        Integer listIteration = 0;    // Keeps track of the number of records we have iterated through in the newList - required to know when we exit the loop
        Integer numRecordsAddedToPlatformEvent = 0;    // Keeps track of the number of records we have added to the platform event
        Integer listSize = newList.size();    // Stores the size of the list in order to avoid multiple size calculations
        Integer stringSize = 0;    // Keeps track how large the string of the payloads is. Once it reaches the limit of one of the fields on the platform event need to make sure to switch to the next field on the platform event.
        Integer platformEventField = 1;    // Determines which field on the platform event to assign payloads to

        // The following fields will need to have its datatype updated for each handler's implementation of this method
        list<ACR__e> platformEventList = new List<ACR__e>();    // List holds all of the platform events to be published
        ACR__e platformEvent = new ACR__e();    // Platform event which will be created
        
        // The following field(s) are unique to this handler's implementation of this method
        Map<Id, String> acrIdAccountRcnMap = getRelatedAccountRcnMap(newList);    // Relates the ACR record id to the RCN__c value on the related Account record
        Map<Id, Id> acrIdAccountRecordTypeIdMap = getRelatedAccountRecordTypeIdMap(newList);    // Relates the ACR record id to the record type id of the related Account record

        // First create all of the platformEventStageRecords
        for(AccountContactRelation theRecord : newList) {             
            listIteration++;    // Count the number of list iterations to perform exit loop operations when we are at the last record in newlist
            
            // Determine the destination system
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null, acrIdAccountRcnMap.get(theRecord.Id), acrIdAccountRecordTypeIdMap.get(theRecord.Id));
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id), acrIdAccountRcnMap.get(theRecord.Id), acrIdAccountRecordTypeIdMap.get(theRecord.Id));
            }
            
            // If no destinationSystem is populated then no platform event needs to be generated for this ACR record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.AccountId = theRecord.AccountId;
            platformEventPayloadStruct.Account_Number = theRecord.Account_Number__c;
            platformEventPayloadStruct.ContactId = theRecord.ContactId;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_ContactId = theRecord.DP_ContactId__c;
            platformEventPayloadStruct.DP_Customer_Id = theRecord.DP_Customer_Id__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.Old_Contact_Id = theRecord.Old_Contact_ID__c;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Publisher_Id = platformEventPublisher.Id;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.Roles = theRecord.Roles;
                    
            // This statement will never change across all platform event implementations
            serializedStruct = JSON.serialize(platformEventPayloadStruct);    // Serialize the struct so we can store the payload as a string on the Platform Event Stage object

            // Assign values to the Platform Event Stage record. ***These values will never change across all platform events***
            platformEventStage.Platform_Event_Publisher__c = platformEventPublisher.Id;
            platformEventStage.sObject_Type__c = HELPER.getPlatformEventMetadata().sObject_Name__c;
            platformEventStage.Platform_Event_Source__c = source;
            platformEventStage.Destination_System__c = destinationSystem;
            platformEventStage.Record_Id__c = theRecord.Id;
            platformEventStage.Platform_Event_Type__c = triggerOperation;
            platformEventStage.Platform_Event_Payload__c = serializedStruct;

            platformEventStageList.add(platformEventStage);    // Add the newly created Platform Event Stage to the platformEventStageList for insertion
            platformEventStage = new Platform_Event_Stage__c();

            // Increment count to see when we have created the max number of platform event stage records for a platform event publisher
            numRecordsAddedToPlatformEvent++;

            // If the number of platform event stage records has met the limit of the number of allowed stages present on a platform event then get the next platform event publisher record
            if(numRecordsAddedToPlatformEvent >= HELPER.getPlatformEventMetadata().Num_Records_Allowed_Per_Platform_Event__c) {
                platformEventPublisherList.add(platformEventPublisher);    // Add the publisher record already operated on to the list
                    
                platformEventPublisher = platformEventPublisherBuffer.remove(0);    // Get the next publisher record in the buffer because we need to create another platform event
                numRecordsAddedToPlatformEvent = 0;    // Reset the nubmer of records added to the platform event
            }
            // If we have iterated over all of the records in new list
            else if(listIteration >= listSize) {
                platformEventPublisherList.add(platformEventPublisher);    // Add the publisher record already operated on to the list

                numRecordsAddedToPlatformEvent = 0;    // Reset the nubmer of records added to the platform event
            }
        }

        // Update all of the platform event publsher record statuses to processed
        for(Platform_Event_Publisher__c thePlatformEventPublisher : platformEventPublisherList) {
            thePlatformEventPublisher.Publisher_Status__c = PlatformEventHandlerHelper.PROCESSED_PUBLISHER_STATUS_CODE;
        }

        // Insert staged platform event records
        if(!platformEventStageList.isEmpty()) {
            try {
                insert platformEventStageList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        // Update platform event publisher records
        if(!platformEventPublisherList.isEmpty()) {
            // If there are no platform events to be staged then delete the newly inserted platform event publisher records
            if(platformEventStageList.isEmpty()) {
                try {
                    delete platformEventPublisherList;
                } catch(DmlException e) {
                    // TODO: implement clog insertion here
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
            // IF there are platform events to be staged then update the new inserted platform event publisher records
            else {
                try {
                    update platformEventPublisherList;
                } catch(DmlException e) {
                    // TODO: implement clog insertion here
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }

        // Reset the following fields for reuse
        listIteration = 0;

        // Publish platform events, platformEventStageList is an ordered list so we don't have to worry about platform event publisher ids being scrambled when looping through the list here. This enabled us to utilized the platform event publisher id to determine when we need to create a new platform event.
        for(Platform_Event_Stage__c thePlatformEventStage : platformEventStageList) { 
            platformEventPayload = (PlatformEventStagePayloadStruct)JSON.deserialize(thePlatformEventStage.Platform_Event_Payload__c, PlatformEventStagePayloadStruct.class);    // Deserialize the payload and cast it as the correct object from the handler corresponding to the type of sObject being iterated over in the batch job
            listIteration++;

            // Set the Platform_Event_Stage_Id field on the payload linked to the Platform Event Stage record being iterated over here and then serialize it
            platformEventPayload.Platform_Event_Stage_Id = thePlatformEventStage.Id;
            serializedStruct = JSON.serialize(platformEventPayload);

            // Update the payload field on the platformEventStage record being iterated over here
            thePlatformEventStage.Platform_Event_Payload__c = serializedStruct;

            // Get the length of the platform event string and add it to the stringSize
            stringSize += serializedStruct.length();

            // If stringSize is less than the number of characters allowed in one of the fields on the platform event itself then append the payload to the payloadSetString
            if(stringSize < PlatformEventHandlerHelper.PLATFORM_EVENT_FIELD_SIZE) {
                // If the payloadSetString has not data then append the serialized platformEventPayload without a delimiter
                if(payloadSetString == PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_START_CHARACTER) {
                    payloadSetString += serializedStruct;
                }
                // If the payloadSetString has data then append the serialized platformEventPayload with a delimiter
                else {
                    payloadSetString += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + serializedStruct;
                }
            }
            // If stringSize is greater than or equal to the number of chatacters allowed in one of the fields on the platform event its self then increment the platformEventField variable and set the stringSize variable equal to the length of the current payload
            else {
                platformEventField++;
                stringSize = serializedStruct.length();

                payloadSetString = PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_START_CHARACTER + serializedStruct;
            }

            // Assign the payload to a platform event field
            switch on platformEventField {
                when 1 {
                    platformEvent.Payload_Set_1__c = payloadSetString + PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_END_CHARACTER;
                } when 2 {
                    platformEvent.Payload_Set_2__c = payloadSetString + PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_END_CHARACTER;
                } when 3 {
                    platformEvent.Payload_Set_3__c = payloadSetString + PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_END_CHARACTER;
                } when 4 {
                    platformEvent.Payload_Set_4__c = payloadSetString + PlatformEventHandlerHelper.PLATFORM_EVENT_PAYLOAD_END_CHARACTER;
                }
            }

            // If this is the final loop iteration
            if(listIteration == platformEventStageList.size()) {
                platformEventList.add(platformEvent);    // Add the platform event to the list for publishing
                platformEvent = new ACR__e();    // Allocate memory for a new platform event to be added to the platform event list
            }
            // If this is the first loop iteration but not the final
            else if(platformEventPublisherId == null) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;
            }
            // If there is a change of platform event publisher id then update accordingly
            else if(platformEventPublisherId != thePlatformEventStage.Platform_Event_Publisher__c) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;

                platformEventList.add(platformEvent);    // Add the platform event to the list for publishing
                platformEvent = new ACR__e();    // Allocate memory for a new platform event to be added to the platform event list
            }
        }

        // Update the platform event stage records one more time in order to make sure that the platform event stage id is present in the payload
        if(!platformEventStageList.isEmpty()) {
            try {
                update platformEventStageList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        // Publish platform events
        HELPER.publishPlatformEvents(platformEventList);
    }

    // Contains common platform event staging data logic - because of future methods being unable to be called in a batch or future context the stagePlatformEvent methods are duplicated
    private static void stagePlatformEventDataBatch(String triggerOperation, List<AccountContactRelation> newList, Map<Id, AccountContactRelation> oldMap, String source) {
        // The following group of fields will be common across all implementations of this method
        List<Platform_Event_Stage__c> platformEventStageList = new List<Platform_Event_Stage__c>();    // List of platform event stagine objects to be inserted into the database
        Platform_Event_Stage__c platformEventStage = new Platform_Event_Stage__c();    // Platform event stage record to create and add to the list
        PlatformEventStagePayloadStruct platformEventPayloadStruct = new PlatformEventStagePayloadStruct();    // Struct used to organize data in order to serialize it so it is able to be unravaelled later during platform event creation
        String destinationSystem;
        String serializedStruct;

        // The following field(s) are unique to this handler's implementation of this method
        Map<Id, String> acrIdAccountRcnMap = getRelatedAccountRcnMap(newList);    // Relates the ACR record id to the RCN__c value on the related Account record
        Map<Id, Id> acrIdAccountRecordTypeIdMap = getRelatedAccountRecordTypeIdMap(newList);    // Relates the ACR record id to the record type id of the related Account record

        for(AccountContactRelation theRecord : newList) { 
            // Determine the destination system
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null, acrIdAccountRcnMap.get(theRecord.Id), acrIdAccountRecordTypeIdMap.get(theRecord.Id));
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id), acrIdAccountRcnMap.get(theRecord.Id), acrIdAccountRecordTypeIdMap.get(theRecord.Id));
            }
            
            // If no destinationSystem is populated then no platform event needs to be generated for this ACR record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.AccountId = theRecord.AccountId;
            platformEventPayloadStruct.Account_Number = theRecord.Account_Number__c;
            platformEventPayloadStruct.ContactId = theRecord.ContactId;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_ContactId = theRecord.DP_ContactId__c;
            platformEventPayloadStruct.DP_Customer_Id = theRecord.DP_Customer_Id__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.Old_Contact_Id = theRecord.Old_Contact_ID__c;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.Roles = theRecord.Roles;
                
            serializedStruct = JSON.serialize(platformEventPayloadStruct);    // Serialize the struct so we can store the payload as a string on the Platform Event Stage object

            // Assign values to the Platform Event Stage record. ***These values will never change across all platform events***
            platformEventStage.sObject_Type__c = HELPER.getPlatformEventMetadata().sObject_Name__c;
            platformEventStage.Platform_Event_Source__c = source;
            platformEventStage.Destination_System__c = destinationSystem;
            platformEventStage.Record_Id__c = theRecord.Id;
            platformEventStage.Platform_Event_Type__c = triggerOperation;
            platformEventStage.Platform_Event_Payload__c = serializedStruct;

            platformEventStageList.add(platformEventStage);    // Add the newly created Platform Event Stage to the platformEventStageList for insertion
            platformEventStage = new Platform_Event_Stage__c();
        }

        // Insert staged platform events
        if(!platformEventStageList.isEmpty()) {
            try {
                insert platformEventStageList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }

    // Assign values to a AccountContactRelation platform event - method is called from the PlatformEventPublishBatch class
    public static PlatformEventHandlerHelper populatePlatformEventData(Platform_Event_Stage__c thePlatformEventStage, PlatformEventHandlerHelper theHelper) {
        PlatformEventAcrHandler.PlatformEventStagePayloadStruct platformEventPayload = (PlatformEventAcrHandler.PlatformEventStagePayloadStruct)JSON.deserialize(thePlatformEventStage.Platform_Event_Payload__c, PlatformEventAcrHandler.PlatformEventStagePayloadStruct.class);    // Deserialize the payload and cast it as the correct object from the handler corresponding to the type of sObject being iterated over in the batch job
        ACR__e platformEvent = (ACR__e)theHelper.getPlatformEvent();    //  Cast the platform event to the corresponding object being iterated over in the batch job
        Integer platformEventCount = theHelper.getNumRecordsInPlatformEvent();    // Get the platform event count

        /* // Do not want to start appending strings until after the first run because null will be appended to the start of the strings otherwise
        if(platformEventCount == 0) {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c = thePlatformEventStage.Id;
            platformEvent.Id__c = thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c = thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c = thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.AccountId__c = platformEventPayload.accountId;
            platformEvent.Account_Number__c = platformEventPayload.accountNumber;
            platformEvent.ContactId__c = platformEventPayload.contactId;
            platformEvent.DP_ContactId__c = platformEventPayload.dpContactId;
            platformEvent.DP_Customer_Id__c = platformEventPayload.dpCustomerId;
            platformEvent.Old_Contact_ID__c = platformEventPayload.oldContactId;
            platformEvent.Old_Record_Id__c = platformEventPayload.oldRecordId;
            platformEvent.Roles__c = platformEventPayload.roles;

            platformEventCount++;    // Increment records added to platform event counter
        } else {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Id;
            platformEvent.Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.AccountId__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.accountId;
            platformEvent.Account_Number__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.accountNumber;
            platformEvent.ContactId__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.contactId;
            platformEvent.DP_ContactId__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.dpContactId;
            platformEvent.DP_Customer_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.dpCustomerId;
            platformEvent.Old_Contact_ID__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.oldContactId;
            platformEvent.Old_Record_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.oldRecordId;
            platformEvent.Roles__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.roles;

            platformEventCount++;    // Increment records added to platform event counter
        } */

        // Update the values in the associated helper class
        theHelper.setPlatformEvent(platformEvent);
        theHelper.setNumRecordsInPlatformEvent(platformEventCount);

        return theHelper;
    }

    // Determine what the destination system should be. If this value is null then that means that no platform event should be generated.
    private static String determinePlatformEventDestination(String triggerOperation, AccountContactRelation theRecord, AccountContactRelation oldRecord, String acrAccountRcn, Id acrAccountRecordTypeId) {
        String destinationSystem = '';    // String containing the destination systems
        
        System.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!Nathans Test' + acrAccountRcn);
        
        if(determineCdhSfdcToFusionCreateAcrRequired(triggerOperation, theRecord, acrAccountRcn) ||
           determineCdhSfdcToFusionUpdateAcrRequired(triggerOperation, theRecord, oldRecord, acrAccountRcn)) {
            destinationSystem += PlatformEventHandlerHelper.CMS_DESTINATION_CODE;
        }

        if(determineNewSfdcToFusionCreateAcrRequired(triggerOperation, theRecord, acrAccountRecordTypeId) ||
           determineNewSfdcToFusionUpdateAcrRoleRequired(triggerOperation, theRecord, oldRecord, acrAccountRecordTypeId)) {
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            }
        }

        return destinationSystem;
    }

    // Determine if the record should have a CDH_SfdcToFusion_CreateACR platform event staged
    private static Boolean determineCdhSfdcToFusionCreateAcrRequired(String triggerOperation, AccountContactRelation theRecord, String acrAccountRcn) {
        if(triggerOperation == PlatformEventHandlerHelper.INSERT_OPERATION_CODE &&
           !HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           acrAccountRcn != null &&
           acrAccountRcn != '') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a CDH_SfdcToFusion_UpdateACR platform event staged
    private static Boolean determineCdhSfdcToFusionUpdateAcrRequired(String triggerOperation, AccountContactRelation theRecord, AccountContactRelation oldRecord, String acrAccountRcn) {
        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE &&
           !HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           acrAccountRcn != null &&
           acrAccountRcn != '') {
            return true;
        }
        
        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_CreateACR platform event staged
    private static Boolean determineNewSfdcToFusionCreateAcrRequired(String triggerOperation, AccountContactRelation theRecord, Id acrAccountRecordTypeId) {
        if(triggerOperation == PlatformEventHandlerHelper.INSERT_OPERATION_CODE &&
           !HELPER.userInSkipUserIdSet() &&
           !HELPER.recordTypeIdIsGovtRecordType(acrAccountRecordTypeId)) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_UpdateACR_Role platform event staged
    private static Boolean determineNewSfdcToFusionUpdateAcrRoleRequired(String triggerOperation, AccountContactRelation theRecord, AccountContactRelation oldRecord, Id acrAccountRecordTypeId) {
        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE &&
           !HELPER.userInSkipUserIdSet() &&
           !HELPER.recordTypeIdIsGovtRecordType(acrAccountRecordTypeId) &&
           theRecord.Roles != oldRecord.Roles) {
            return true;
        }
        
        return false;
    }

    // Get the RCN__c field of the Account records relates to each ACR
    private static Map<Id, String> getRelatedAccountRcnMap(List<AccountContactRelation> newList) {
        Map<Id, String> relatedAccountRcnMap = new Map<Id, String>();
        Map<Id, Id> accountIdAcrIdMap = new Map<Id, Id>();

        // Relate the Account Ids on each ACR record to the ACR record's id
        for(AccountContactRelation theAcr : newList) {
            accountIdAcrIdMap.put(theAcr.AccountId, theAcr.Id);
        }

        System.debug('The account id acr id map is: ' + accountIdAcrIdMap);
        
        // Relate the ACR ids to the related Account record's Record Type Id
        for(Account theAccount : [SELECT Id, RCN__c FROM Account WHERE Id IN :accountIdAcrIdMap.keySet()]) {
            if(accountIdAcrIdMap.containsKey(theAccount.Id)) {
                relatedAccountRcnMap.put(accountIdAcrIdMap.get(theAccount.Id), theAccount.RCN__c);
            }
        }

        System.debug('The RCN map is: ' + relatedAccountRcnMap);
        
        return relatedAccountRcnMap;
    }

    // Get the record type ids of the Account record related to each ACR
    private static Map<Id, Id> getRelatedAccountRecordTypeIdMap(List<AccountContactRelation> newList) {
        Map<Id, Id> relatedAccountRecordTypeIdMap = new Map<Id, Id>();
        Map<Id, Id> accountIdAcrIdMap = new Map<Id, Id>();

        // Relate the Account Ids on each ACR record to the ACR record's id
        for(AccountContactRelation theAcr : newList) {
            accountIdAcrIdMap.put(theAcr.AccountId, theAcr.Id);
        }

        // Relate the ACR ids to the related Account record's Record Type Id
        for(Account theAccount : [SELECT Id, RecordTypeId FROM Account WHERE Id IN :accountIdAcrIdMap.keySet()]) {
            if(accountIdAcrIdMap.containsKey(theAccount.Id)) {
                relatedAccountRecordTypeIdMap.put(accountIdAcrIdMap.get(theAccount.Id), theAccount.RecordTypeId);
            }
        }

        return relatedAccountRecordTypeIdMap;
    }

}