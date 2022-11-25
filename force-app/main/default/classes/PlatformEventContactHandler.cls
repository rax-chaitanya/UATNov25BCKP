// Class which will handle new platform events created on the contact object. 

// How to implement new platform event:
// 1. Copy this class and change the constants within to match the corresponding values for any new platform event as well as all of the object types
// 2. You must implement new versions of stagePlatformEvents() and updateFieldsChanged()

public with sharing class PlatformEventContactHandler {
    public static final PlatformEventHandlerHelper HELPER = new PlatformEventHandlerHelper('Contact_Events');    // Create helper instance which contains all common methods and variables used between all platform event handlers

    private static Boolean platformEventCreationOnInsertComplete = false;    // Will be set to true if the insert logic is hit
    private static Boolean platformEventCreationOnUpdateComplete = false;    // Prevents recursion on updates when true

    // Create a class (struct) which will contain all fields which would have been stored on the Platform Event Stage object. This class instance will be populated and stringified then stored on the Platform Event Stage object to avoid creating loads of fields
    // for each platform event on the Platform Event Stage object. Will also make query in the platform event batch jobs easy because we just need to grab the stringified data. Each platform event handler will have its own specific fields added to its
    // corresponding struct class.
    public class PlatformEventStagePayloadStruct {
        public String Destination_System = null;
        public String DP_ContactId = null;
        public String Id = null;
        public String Old_Record_Id = null;
        public String Platform_Event_Publisher_Id = null;
        public String Platform_Event_Stage_Id = null;
        public String Platform_Event_Type = null;
        public String RPN = null;
        public String Status = null;
    }

    // Method handles platform events which should be fired on insert
    public static void createPlatformEventsOnInsert(List<Contact> newList) {
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
    public static void createPlatformEventsOnUpdate(Map<Id, Contact> oldMap, List<Contact> newList) {
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

    // Method handles platform events which should be created based on delete
    public static void createPlatformEventsOnDelete(List<Contact> oldList) {
        // Determine if the platform event is active and if the user's profile is allowed to generate platform events
        if(!HELPER.platformEventActive() || HELPER.userProfileIsRestricted()) {
            return;
        }

        // Stage new platform events for publishing
        if(System.isBatch() || System.isFuture() || System.isQueueable()) {
            stagePlatformEvents(PlatformEventHandlerHelper.DELETE_OPERATION_CODE, oldList, null);
        } else {
            // Turn input into strings for future method call
            String jsonOldList = JSON.serialize(oldList);

            stagePlatformEvents(PlatformEventHandlerHelper.DELETE_OPERATION_CODE, jsonOldList, null);
        }
    }
        
    // Method handles platform events which should be created based on undelete
    public static void createPlatformEventsOnUnDelete(List<Contact> newList) {
        // Determine if the platform event is active and if the user's profile is allowed to generate platform events
        if(!HELPER.platformEventActive() || HELPER.userProfileIsRestricted()) {
            return;
        }

        // Stage new platform events for publishing
        if(System.isBatch() || System.isFuture() || System.isQueueable()) {
            stagePlatformEvents(PlatformEventHandlerHelper.UNDELETE_OPERATION_CODE, newList, null);
        } else {
            // Turn input into strings for future method call
            String jsonNewList = JSON.serialize(newList);

            stagePlatformEvents(PlatformEventHandlerHelper.UNDELETE_OPERATION_CODE, jsonNewList, null);
        }
    }

    // Contains logic which will stage the correct platform events
    private static void stagePlatformEvents(String triggerOperation, List<Contact> newList, Map<Id, Contact> oldMap) {
        // If the source is a batch job then mark the source of the platform events as batch and don't fire the platform events immediately
        if(PlatformEventHandlerHelper.PLATFORM_EVENT_ALL_EVENTS_METADATA.Batch_Mode_Enabled__c) {
            stagePlatformEventDataBatch(triggerOperation, newList, oldMap, PlatformEventHandlerHelper.SOURCE_BATCH);
        } 
        // If the source is the app, future context/queueable contaxt will always be from the app, then mark the source of the platform events as app and fire the platform events immediately
        else {
            stagePlatformEventData(triggerOperation, newList, oldMap, PlatformEventHandlerHelper.SOURCE_APP);
        }
    }

    // Contains logic which will stage the correct platform events asyncronously
    @future @testVisible
    private static void stagePlatformEvents(String triggerOperation, String jsonNewList, String jsonOldMap) {
        List<Contact> newList = (List<Contact>) JSON.deserialize(jsonNewList, List<Contact>.class);    // Recreate objects from json strings
        Map<Id, Contact> oldMap;    // Map containing the deseriablized oldMap

        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
            oldMap = (Map<Id, Contact>) JSON.deserialize(jsonOldMap, Map<Id, Contact>.class);
        }
        
        stagePlatformEvents(triggerOperation, newList, oldMap);
    }

    // Contains common platform event staging data logic - because of future methods being unable to be called in a batch or future context the stagePlatformEvent methods are duplicated
    private static void stagePlatformEventData(String triggerOperation, List<Contact> newList, Map<Id, Contact> oldMap, String source) {
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

        // The following field will need to have its datatype updated for each handler's implementation of this method
        list<Contact__e> platformEventList = new List<Contact__e>();    // List holds all of the platform events to be published
        Contact__e platformEvent = new Contact__e();    // Platform event which will be created
        
        // The following field(s) are unique to this handler's implementation of this method
        Map<Id, Id> recordIdRelatedAccountRecordTypeIdMap = getRelatedAccountRecordTypeIdMap(newList);    // Map relating the record id of the contact with the record type of the related account

        // First create all of the platformEventStageRecords
        for(Contact theRecord : newList) {
            listIteration++;    // Count the number of list iterations to perform exit loop operations when we are at the last record in newlist

            // Get the destination systems for the record - check triggerOperation so we don't try to get oldMap during an insert
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null, recordIdRelatedAccountRecordTypeIdMap.get(theRecord.Id));
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id), recordIdRelatedAccountRecordTypeIdMap.get(theRecord.Id));
            }
            
            // If no destinationSystem is populated then no platform event needs to be generated for this contact record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_ContactId = theRecord.DP_ContactId__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Publisher_Id = platformEventPublisher.Id;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RPN = theRecord.RPN__c;
            platformEventPayloadStruct.Status = theRecord.Status__c;
                    
            serializedStruct = JSON.serialize(platformEventPayloadStruct);    // Serialize the struct so we can store the payload as a string on the Platform Event Stage object

            // Assign values to the Platform Event Stage record
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
                platformEvent = new Contact__e();    // Wipe memory in the platform event
            }
            // If this is the first loop iteration but not the final
            else if(platformEventPublisherId == null) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;
            }
            // If there is a change of platform event publisher id then update accordingly
            else if(platformEventPublisherId != thePlatformEventStage.Platform_Event_Publisher__c) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;

                platformEventList.add(platformEvent);    // Add the platform event to the list for publishing
                platformEvent = new Contact__e();    // Allocate memory for a new platform event to be added to the platform event list
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
    private static void stagePlatformEventDataBatch(String triggerOperation, List<Contact> newList, Map<Id, Contact> oldMap, String source) {
        List<Platform_Event_Stage__c> platformEventStageList = new List<Platform_Event_Stage__c>();    // List of platform event stagine objects to be inserted into the database
        Platform_Event_Stage__c platformEventStage = new Platform_Event_Stage__c();    // Platform event stage record to create and add to the list
        PlatformEventStagePayloadStruct platformEventPayloadStruct = new PlatformEventStagePayloadStruct();    // Struct used to organize data in order to serialize it so it is able to be unravaelled later during platform event creation
        String destinationSystem;
        String serializedStruct;

        Map<Id, Id> recordIdRelatedAccountRecordTypeIdMap = getRelatedAccountRecordTypeIdMap(newList);    // Get any data required to complete platform event staging

        for(Contact theRecord : newList) { 
            // Get the destination systems for the record - check triggerOperation so we don't try to get oldMap during an insert
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null, recordIdRelatedAccountRecordTypeIdMap.get(theRecord.Id));
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id), recordIdRelatedAccountRecordTypeIdMap.get(theRecord.Id));
            }
            
            // If no destinationSystem is populated then no platform event needs to be generated for this contact record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_ContactId = theRecord.DP_ContactId__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RPN = theRecord.RPN__c;
            platformEventPayloadStruct.Status = theRecord.Status__c;
                
            serializedStruct = JSON.serialize(platformEventPayloadStruct);    // Serialize the struct so we can store the payload as a string on the Platform Event Stage object

            // Assign values to the Platform Event Stage record
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

    // Determine what the destination system should be. If this value is null then that means that no platform event should be generated.
    private static String determinePlatformEventDestination(String triggerOperation, Contact theRecord, Contact oldRecord, Id accountRecordTypeId) {
        String destinationSystem = '';    // String containing the destination systems
        
        if(determineCdhSfdcToFusionUpdateContactRequired(triggerOperation, theRecord, oldRecord)) {
            destinationSystem += PlatformEventHandlerHelper.CMS_DESTINATION_CODE;
        }

        if(determineNewSfdcToFusionCreateContactRequired(triggerOperation, theRecord, oldRecord, accountRecordTypeId) ||
           determineNewSfdcToFusionDeleteUndeleteContactRequired(triggerOperation, theRecord)) {
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            }
        }

        return destinationSystem;
    }

    // Determine if the record should have a CDH_SfdcToFusion_UpdateContact platform event staged
    private static Boolean determineCdhSfdcToFusionUpdateContactRequired(String triggerOperation, Contact theRecord, Contact oldRecord) {
        // Perform initial logic checks - this platform event requires that the record be updated so including change checks
        if(!HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           theRecord.RPN__c != '' && 
           theRecord.RPN__c != null) {
            /* // If the record is inserted via a batch job then it is possible that the RPN value is known already - is this required?
            if(triggerOperation == PlatformEventHandlerHelper.INSERT_OPERATION_CODE) {
                return true;
            } */
            // If the record is updated to meet the criteria or values changed
            if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                return true;
            }
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_CreateContact platform event staged
    private static Boolean determineNewSfdcToFusionCreateContactRequired(String triggerOperation, Contact theRecord, Contact oldRecord, Id accountRecordTypeId) {
        // Perform initial logic checks
        if(!HELPER.userInSkipUserIdSet() && 
           !HELPER.recordTypeIdIsGovtRecordType(theRecord.RecordTypeId) && 
           !HELPER.recordTypeIdIsGovtRecordType(accountRecordTypeId)) {
            // If the record is inserted or updated then send the platform event to stash
            if(triggerOperation == PlatformEventHandlerHelper.INSERT_OPERATION_CODE || triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                return true;
            } 
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_DeleteUndeleteContact platform event staged
    private static Boolean determineNewSfdcToFusionDeleteUndeleteContactRequired(String triggerOperation, Contact theRecord) {
        if((triggerOperation == PlatformEventHandlerHelper.DELETE_OPERATION_CODE || triggerOperation == PlatformEventHandlerHelper.UNDELETE_OPERATION_CODE) &&
           !HELPER.userInSkipUserIdSet() &&
           !HELPER.recordTypeIdIsGovtRecordType(theRecord.RecordTypeId)) {
            return true;
        }

        return false;
    }

    // Get the record type ids of the Account record related to each Contact
    private static Map<Id, Id> getRelatedAccountRecordTypeIdMap(List<Contact> newList) {
        Map<Id, Id> relatedAccountRecordTypeIdMap = new Map<Id, Id>();
        Map<Id, Id> accountIdContactIdMap = new Map<Id, Id>();

        // Relate the Account Ids on each Contact record to the Contact record's id
        for(Contact theContact : newList) {
            accountIdContactIdMap.put(theContact.AccountId, theContact.Id);
        }

        // Relate the Contact ids to the related Account record's Record Type Id
        for(Account theAccount : [SELECT Id, RecordTypeId FROM Account WHERE Id IN :accountIdContactIdMap.keySet()]) {
            if(accountIdContactIdMap.containsKey(theAccount.Id)) {
                relatedAccountRecordTypeIdMap.put(accountIdContactIdMap.get(theAccount.Id), theAccount.RecordTypeId);
            }
        }

        return relatedAccountRecordTypeIdMap;
    }

    // Assign values to a contact platform event - method is called from the PlatformEventPublishBatch class
    public static PlatformEventHandlerHelper populatePlatformEventData(Platform_Event_Stage__c thePlatformEventStage, PlatformEventHandlerHelper theHelper) {
        PlatformEventContactHandler.PlatformEventStagePayloadStruct platformEventPayload = (PlatformEventContactHandler.PlatformEventStagePayloadStruct)JSON.deserialize(thePlatformEventStage.Platform_Event_Payload__c, PlatformEventContactHandler.PlatformEventStagePayloadStruct.class);    // Deserialize the payload and cast it as the correct object from the handler corresponding to the type of sObject being iterated over in the batch job
        Contact__e platformEvent = (Contact__e)theHelper.getPlatformEvent();    //  Cast the platform event to the corresponding object being iterated over in the batch job
        Integer platformEventCount = theHelper.getNumRecordsInPlatformEvent();    // Get the platform event count

        /* // Do not want to start appending strings until after the first run because null will be appended to the start of the strings otherwise
        if(platformEventCount == 0) {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c = thePlatformEventStage.Id;
            platformEvent.Id__c = thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c = thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c = thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.Data_Pipe_Contact_Id__c = platformEventPayload.dpContactId;
            platformEvent.Old_Record_Id__c = platformEventPayload.oldRecordId;
            platformEvent.RPN__c = platformEventPayload.rpn;
            platformEvent.Status__c = platformEventPayload.status;

            platformEventCount++;    // Increment records added to platform event counter
        } else {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Id;
            platformEvent.Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.Data_Pipe_Contact_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.dpContactId;
            platformEvent.Old_Record_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.oldRecordId;
            platformEvent.RPN__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.rpn;
            platformEvent.Status__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.status;

            platformEventCount++;    // Increment records added to platform event counter
        } */

        // Update the values in the associated helper class
        theHelper.setPlatformEvent(platformEvent);
        theHelper.setNumRecordsInPlatformEvent(platformEventCount);

        return theHelper;
    }
    
}