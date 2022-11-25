public with sharing class PlatformEventAccountHandler {
    public static final PlatformEventHandlerHelper HELPER = new PlatformEventHandlerHelper('Account_Events');    // Create helper instance which contains all common methods and variables used between all platform event handlers

    private static Set<Id> accountCustomerRecordTypeSet;    // Set conteining the Account Customer Record Type id
    private static Set<Id> accountGovtRecordTypeSet;    // Set conteining the Account Government Record Type id
    private static Set<Id> accountRBURecordTypeSet;    // Set conteining the Account RBU Record Type id
    private static Set<Id> accountCompanyRecordTypeSet;    // Set contining the Account Record Type ids which have a developer name including company
    private static Boolean platformEventCreationOnInsertComplete = false;    // Will be set to true if the insert logic is hit
    private static Boolean platformEventCreationOnUpdateComplete = false;    // Prevents recursion on updates when true

    // Create a class (struct) which will contain all fields which would have been stored on the Platform Event Stage object. This class instance will be populated and stringified then stored on the Platform Event Stage object to avoid creating loads of fields
    // for each platform event on the Platform Event Stage object. Will also make query in the platform event batch jobs easy because we just need to grab the stringified data. Each platform event handler will have its own specific fields added to its
    // corresponding struct class.
    public class PlatformEventStagePayloadStruct {
        public String Account_Number;
        public String Destination_System;
        public String DP_CustomerId;
        public String DP_Parent_AccountId;
        public String Id;
        public String OIC_Company_Number;
        public Boolean OIC_Participant;
        public String OIC_Participant_Id;
        public String OIC_Partner_Id;
        public String Old_Record_Id;
        public String Platform_Event_Publisher_Id = null;
        public String Platform_Event_Stage_Id = null;
        public String Platform_Event_Type = null;
        public String RCN;
        public String Status;
    }

    // Method handles platform events which should be fired on insert
    public static void createPlatformEventsOnInsert(List<Account> newList) {
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
    public static void createPlatformEventsOnUpdate(Map<Id, Account> oldMap, List<Account> newList) {
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
    public static void createPlatformEventsOnDelete(List<Account> oldList) {
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
    public static void createPlatformEventsOnUnDelete(List<Account> newList) {
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
    private static void stagePlatformEvents(String triggerOperation, List<Account> newList, Map<Id, Account> oldMap) {
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
        List<Account> newList = (List<Account>) JSON.deserialize(jsonNewList, List<Account>.class);    // Recreate objects from json strings
        Map<Id, Account> oldMap;    // Map containing the deseriablized oldMap

        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
            oldMap = (Map<Id, Account>) JSON.deserialize(jsonOldMap, Map<Id, Account>.class);
        }
        
        stagePlatformEvents(triggerOperation, newList, oldMap);
    }

    // Contains common platform event staging data logic - because of future methods being unable to be called in a batch or future context the stagePlatformEvent methods are duplicated
    private static void stagePlatformEventData(String triggerOperation, List<Account> newList, Map<Id, Account> oldMap, String source) {
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
        list<Account__e> platformEventList = new List<Account__e>();    // List holds all of the platform events to be published
        Account__e platformEvent = new Account__e();    // Platform event which will be created

        // First create all of the platformEventStageRecords
        for(Account theRecord : newList) {             
            listIteration++;    // Count the number of list iterations to perform exit loop operations when we are at the last record in newlist
            
            // Determine the destination system
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null);
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id));
            }
            
            
            // If no destinationSystem or endpointObject is populated then no platform event needs to be generated for this cLog record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.Account_Number = theRecord.Account_Number__c;
            platformEventPayloadStruct.DP_CustomerId = theRecord.DP_CustomerId__c;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_Parent_AccountId = theRecord.DP_Parent_AccountId__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.OIC_Company_Number = theRecord.OIC_Company_Number__c;
            platformEventPayloadStruct.OIC_Participant = theRecord.OIC_Participant__c;
            platformEventPayloadStruct.OIC_Participant_Id = theRecord.OIC_Participant_Id__c;
            platformEventPayloadStruct.OIC_Partner_Id = theRecord.OIC_Partner_Id__c;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Publisher_Id = platformEventPublisher.Id;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RCN = theRecord.RCN__c;
            platformEventPayloadStruct.Status = theRecord.Status__c;
 
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
                platformEvent = new Account__e();    // Allocate memory for a new platform event to be added to the platform event list
            }
            // If this is the first loop iteration but not the final
            else if(platformEventPublisherId == null) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;
            }
            // If there is a change of platform event publisher id then update accordingly
            else if(platformEventPublisherId != thePlatformEventStage.Platform_Event_Publisher__c) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;

                platformEventList.add(platformEvent);    // Add the platform event to the list for publishing
                platformEvent = new Account__e();    // Allocate memory for a new platform event to be added to the platform event list
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
    private static void stagePlatformEventDataBatch(String triggerOperation, List<Account> newList, Map<Id, Account> oldMap, String source) {
        // The following group of fields will be common across all implementations of this method
        List<Platform_Event_Stage__c> platformEventStageList = new List<Platform_Event_Stage__c>();    // List of platform event stagine objects to be inserted into the database
        Platform_Event_Stage__c platformEventStage = new Platform_Event_Stage__c();    // Platform event stage record to create and add to the list
        PlatformEventStagePayloadStruct platformEventPayloadStruct = new PlatformEventStagePayloadStruct();    // Struct used to organize data in order to serialize it so it is able to be unravaelled later during platform event creation
        String destinationSystem;
        String serializedStruct;

        for(Account theRecord : newList) { 
            // Determine the destination system
            if(triggerOperation != PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, null);
            } else {
                destinationSystem = determinePlatformEventDestination(triggerOperation, theRecord, oldMap.get(theRecord.Id));
            }

            // If no destinationSystem or endpointObject is populated then no platform event needs to be generated for this cLog record in this loop iteration
            if(destinationSystem == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.Account_Number = theRecord.Account_Number__c;
            platformEventPayloadStruct.DP_CustomerId = theRecord.DP_CustomerId__c;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.DP_Parent_AccountId = theRecord.DP_Parent_AccountId__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.OIC_Company_Number = theRecord.OIC_Company_Number__c;
            platformEventPayloadStruct.OIC_Participant = theRecord.OIC_Participant__c;
            platformEventPayloadStruct.OIC_Participant_Id = theRecord.OIC_Participant_Id__c;
            platformEventPayloadStruct.OIC_Partner_Id = theRecord.OIC_Partner_Id__c;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RCN = theRecord.RCN__c;
            platformEventPayloadStruct.Status = theRecord.Status__c;

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

    // Assign values to a Account platform event - method is called from the PlatformEventPublishBatch class
    public static PlatformEventHandlerHelper populatePlatformEventData(Platform_Event_Stage__c thePlatformEventStage, PlatformEventHandlerHelper theHelper) {
        PlatformEventClogHandler.PlatformEventStagePayloadStruct platformEventPayload = (PlatformEventClogHandler.PlatformEventStagePayloadStruct)JSON.deserialize(thePlatformEventStage.Platform_Event_Payload__c, PlatformEventClogHandler.PlatformEventStagePayloadStruct.class);    // Deserialize the payload and cast it as the correct object from the handler corresponding to the type of sObject being iterated over in the batch job
        Account__e platformEvent = (Account__e)theHelper.getPlatformEvent();    //  Cast the platform event to the corresponding object being iterated over in the batch job
        Integer platformEventCount = theHelper.getNumRecordsInPlatformEvent();    // Get the platform event count

        /* // Do not want to start appending strings until after the first run because null will be appended to the start of the strings otherwise
        if(platformEventCount == 0) {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c = thePlatformEventStage.Id;
            platformEvent.Id__c = thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c = thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c = thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.Action_Name__c = platformEventPayload.actionName;
            platformEvent.Action_Record_ID__c = platformEventPayload.actionRecordId;
            platformEvent.Endpoint_Object__c = platformEventPayload.endpointObject;
            platformEvent.Focus_Area__c = platformEventPayload.focusArea;
            platformEvent.IsDeleted__c = platformEventPayload.isDeleted;
            platformEvent.IsDeletedC__c = platformEventPayload.isDeletedC;
            platformEvent.Name__c = platformEventPayload.name;
            platformEvent.Old_Record_Id__c = platformEventPayload.oldRecordId;
            platformEvent.OLD_Related_Id__c = platformEventPayload.oldRelatedId;
            platformEvent.RPN__c = platformEventPayload.rpn;

            platformEventCount++;    // Increment records added to platform event counter
        } else {
            // Fields which are common across all of the Platform Event Stage records and because of this are not stored in any payload on any Platform Event Stage record
            platformEvent.Platform_Event_Stage_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Id;
            platformEvent.Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Record_Id__c;
            platformEvent.Destination_System__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Destination_System__c;
            platformEvent.Platform_Event_Type__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + thePlatformEventStage.Platform_Event_Type__c;

            // Fields which are unique to this type of Platform Event Stage record so all of them are stored in the payload field
            platformEvent.Action_Name__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.actionName;
            platformEvent.Action_Record_ID__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.actionRecordId;
            platformEvent.Endpoint_Object__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.endpointObject;
            platformEvent.Focus_Area__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.focusArea;
            platformEvent.IsDeleted__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.isDeleted;
            platformEvent.IsDeletedC__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.isDeletedC;
            platformEvent.Name__c += platformEventPayload.name;
            platformEvent.Old_Record_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.oldRecordId;
            platformEvent.OLD_Related_Id__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.oldRelatedId;
            platformEvent.RPN__c += PlatformEventHandlerHelper.PLATFORM_EVENT_DELIMITER + platformEventPayload.rpn;

            platformEventCount++;    // Increment records added to platform event counter
        } */

        // Update the values in the associated helper class
        theHelper.setPlatformEvent(platformEvent);
        theHelper.setNumRecordsInPlatformEvent(platformEventCount);

        return theHelper;
    }

    // Determine what the destination system should be. If this value is null then that means that no platform event should be generated.
    private static String determinePlatformEventDestination(String triggerOperation, Account theRecord, Account oldRecord) {
        String destinationSystem = '';    // String containing the destination systems
        
        if(determineCdhSfdcToFusionCreateAccountsRequired(triggerOperation, theRecord, oldRecord) ||
           determineCdhSfdcToFusionUpdateAccountsRequired(triggerOperation, theRecord)) {
            destinationSystem += PlatformEventHandlerHelper.CMS_DESTINATION_CODE;
        }

        if(determineGtmoNewSfdcToFusionUpdCompOicParticipRequired(theRecord) ||
           determineGtmoOicSfdcToFusionUpdatePartnerAccRequired(triggerOperation, theRecord, oldRecord)) {
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.OIC_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.OIC_DESTINATION_CODE;
            }
        }

        if(determineNewSfdcToFusionCreateAccountsRequired(triggerOperation, theRecord) ||
           determineNewSfdcToFusionDeleteUndeleteAccountsRequired(triggerOperation, theRecord, oldRecord) ||
           determineNewSfdcToFusionUpdateAccountsRequired(triggerOperation, theRecord, oldRecord)) {
            // Assign temp value of none until receiving the actual values from Mulesoft
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            }
        }

        return destinationSystem;
    }

    // Determine if the record should have a CDH_NewSfdcToFusion-DeleteContact platform event staged
    private static Boolean determineCdhSfdcToFusionCreateAccountsRequired(String triggerOperation, Account theRecord, Account oldRecord) {
        if(!HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           theRecord.RCN__c != '' &&
           theRecord.RCN__c != null &&
           (accountRecordTypeIdIsCustomerRecordType(theRecord.RecordTypeId) || accountRecordTypeIdIsGovtRecordType(theRecord.RecordTypeId) || accountRecordTypeIdIsRBURecordType(theRecord.RecordTypeId)) &&
           ((triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE && theRecord.Type == 'Customer' && !accountRecordTypeIdIsCustomerRecordType(oldRecord.RecordTypeId)) || theRecord.Type == 'Customer' || theRecord.Type == 'Former Customer')) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a CDH_NewSfdcToFusion-DeleteContact platform event staged
    private static Boolean determineCdhSfdcToFusionUpdateAccountsRequired(String triggerOperation, Account theRecord) {
        if(!HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           theRecord.RCN__c != '' &&
           theRecord.RCN__c != null &&
           accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a GTMO_NewSfdcToFusion_UpdCompOICParticip platform event staged
    private static Boolean determineGtmoNewSfdcToFusionUpdCompOicParticipRequired(Account theRecord) {
        if(accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           theRecord.OIC_Participant__c &&
           theRecord.OIC_Participant_Id__c == null) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a GTMO_OIC_SfdcToFusion_UpdatePartnerAcc platform event staged
    private static Boolean determineGtmoOicSfdcToFusionUpdatePartnerAccRequired(String triggerOperation, Account theRecord, Account oldRecord) {
        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE &&
           accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           !HELPER.userInSkipUserIdSet() &&
           theRecord.OIC_Participant_Id__c != null &&
           theRecord.OIC_Participant_Id__c != '' &&
           theRecord.OIC_Participant__c &&
           ((theRecord.Partner_Level__c != null && theRecord.Partner_Level__c != '' && theRecord.Partner_Level__c != oldRecord.Partner_Level__c) || 
           (theRecord.Primary_Member__c != null && theRecord.Primary_Member__c != '' && theRecord.Primary_Member__c != oldRecord.Primary_Member__c) ||
           (theRecord.Contract_Type__c != null && theRecord.Contract_Type__c != '' && theRecord.Contract_Type__c != oldRecord.Contract_Type__c) ||
           (theRecord.Tier_Level__c != null && theRecord.Tier_Level__c != '' && theRecord.Tier_Level__c != oldRecord.Tier_Level__c) ||
           (theRecord.Contract_Signed_Date__c != oldRecord.Contract_Signed_Date__c) ||
           (theRecord.Oracle_Vendor_ID__c != null && theRecord.Oracle_Vendor_ID__c != '' && theRecord.Oracle_Vendor_ID__c != oldRecord.Oracle_Vendor_ID__c) ||
           (theRecord.Oracle_Site_Id__c != null && theRecord.Oracle_Site_Id__c != '' && theRecord.Oracle_Site_Id__c != oldRecord.Oracle_Site_Id__c))) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_CreateAccounts platform event staged
    private static Boolean determineNewSfdcToFusionCreateAccountsRequired(String triggerOperation, Account theRecord) {
        if(triggerOperation == PlatformEventHandlerHelper.INSERT_OPERATION_CODE &&
           accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           !HELPER.userInSkipUserIdSet() &&
           !HELPER.recordTypeIdIsGovtRecordType(theRecord.RecordTypeId)) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_DeleteUndeleteAccounts platform event staged
    private static Boolean determineNewSfdcToFusionDeleteUndeleteAccountsRequired(String triggerOperation, Account theRecord, Account oldRecord) {
        if((triggerOperation == PlatformEventHandlerHelper.DELETE_OPERATION_CODE || triggerOperation == PlatformEventHandlerHelper.UNDELETE_OPERATION_CODE) &&
           accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           !HELPER.recordTypeIdIsGovtRecordType(theRecord.RecordTypeId) &&
           !HELPER.userInSkipUserIdSet() &&
           theRecord.Status__c != oldRecord.Status__c &&
           (theRecord.Status__c == 'Deleted' || oldRecord.Status__c == 'Deleted')) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion_UpdateAccounts platform event staged
    private static Boolean determineNewSfdcToFusionUpdateAccountsRequired(String triggerOperation, Account theRecord, Account oldRecord) {
        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE &&
           accountRecordTypeContainsCompany(theRecord.RecordTypeId) &&
           !HELPER.recordTypeIdIsGovtRecordType(theRecord.RecordTypeId) &&
           !HELPER.userInSkipUserIdSet() &&
           !logicHelper(theRecord, oldRecord)) {
            return true;
        }

        return false;
    }

    // Builds accountCustomerRecordTypeId set, if the Set is null, and determines if the given record type id is present within it
    private static Boolean accountRecordTypeIdIsCustomerRecordType(Id recordTypeId) {
        // If accountCustomerRecordTypeSet is null the populate it
        if(accountCustomerRecordTypeSet == null) {
            accountCustomerRecordTypeSet = new Set<Id>();

            accountCustomerRecordTypeSet.addAll((List<Id>)Label.AccountCustomerRecordTypeId.split(','));
        }

        return accountCustomerRecordTypeSet.contains(recordTypeId);
    }

    // Builds accountGovtRecordTypeSet set, if the Set is null, and determines if the given record type id is present within it
    private static Boolean accountRecordTypeIdIsGovtRecordType(Id recordTypeId) {
        // If accountGovtRecordTypeSet is null the populate it
        if(accountGovtRecordTypeSet == null) {
            accountGovtRecordTypeSet = new Set<Id>();

            accountGovtRecordTypeSet.addAll((List<Id>)Label.AccountGovernmentRecordTypeId.split(','));
        }

        return accountGovtRecordTypeSet.contains(recordTypeId);
    }

    // Builds accountRBURecordTypeSet set, if the Set is null, and determines if the given record type id is present within it
    private static Boolean accountRecordTypeIdIsRBURecordType(Id recordTypeId) {
        // If accountRBURecordTypeSet is null the populate it
        if(accountRBURecordTypeSet == null) {
            accountRBURecordTypeSet = new Set<Id>();

            accountRBURecordTypeSet.addAll((List<Id>)Label.AccountRBURecordTypeId.split(','));
        }

        return accountRBURecordTypeSet.contains(recordTypeId);
    }

    // Builds accountCompanyRecordTypeSet set, if the Set is null, and determines if the given record type id is present within it
    private static Boolean accountRecordTypeContainsCompany(Id recordTypeId) {
        // If accountCompanyRecordTypeSet is null the populate it
        if(accountCompanyRecordTypeSet == null) {
            accountCompanyRecordTypeSet = new Set<Id>();

            accountCompanyRecordTypeSet.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Government_Company').getRecordTypeId());
            accountCompanyRecordTypeSet.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Company').getRecordTypeId());
            accountCompanyRecordTypeSet.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('RBU_Company').getRecordTypeId());
            accountCompanyRecordTypeSet.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Standard_Company').getRecordTypeId());
        }

        return accountCompanyRecordTypeSet.contains(recordTypeId);
    }

    private static Boolean logicHelper(Account theRecord, Account oldRecord) {
        if(theRecord.Status__c != oldRecord.Status__c &&
           (theRecord.Status__c == 'Deleted' ||
           oldRecord.Status__c == 'Deleted')) {
            return true;
        }

        return false;
    }

}