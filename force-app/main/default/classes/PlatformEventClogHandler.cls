// Class which will handle new platform events created on the cLog__c object. 

// How to implement new platform event:
// 1. Copy this class and change the constants within to match the corresponding values for any new platform event as well as all of the object types
// 2. You must implement new versions of stagePlatformEvents() and updateFieldsChanged()

public with sharing class PlatformEventClogHandler {
    public static final PlatformEventHandlerHelper HELPER = new PlatformEventHandlerHelper('cLog_Events');    // Create helper instance which contains all common methods and variables used between all platform event handlers

    // Create a class (struct) which will contain all fields which would have been stored on the Platform Event Stage object. This class instance will be populated and stringified then stored on the Platform Event Stage object to avoid creating loads of fields
    // for each platform event on the Platform Event Stage object. Will also make query in the platform event batch jobs easy because we just need to grab the stringified data. Each platform event handler will have its own specific fields added to its
    // corresponding struct class.
    public class PlatformEventStagePayloadStruct {
        public String Action_Name = null;
        public String Action_RecordId = null;
        public String Destination_System = null;
        public String Endpoint_Object = null;
        public String Focus_Area = null;
        public String Id = null;
        public String is_Deleted = null;
        public String is_Deleted_C = null;
        public String Name = null;
        public String Old_Record_Id = null;
        public String Old_Related_Id = null;
        public String Platform_Event_Publisher_Id = null;
        public String Platform_Event_Stage_Id = null;
        public String Platform_Event_Type = null;
        public String RPN = null;
        public String ACR_ContactId = null;
    }

    // Method handles platform events which should be fired on insert
    public static void createPlatformEventsOnInsert(List<cLog__c> newList) {
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

    // Contains logic which will stage the correct platform events
    private static void stagePlatformEvents(String triggerOperation, List<cLog__c> newList, Map<Id, cLog__c> oldMap) {
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
        List<cLog__c> newList = (List<cLog__c>) JSON.deserialize(jsonNewList, List<cLog__c>.class);    // Recreate objects from json strings
        Map<Id, cLog__c> oldMap;    // Map containing the deseriablized oldMap

        if(triggerOperation == PlatformEventHandlerHelper.UPDATE_OPERATION_CODE) {
            oldMap = (Map<Id, cLog__c>) JSON.deserialize(jsonOldMap, Map<Id, cLog__c>.class);
        }
        
        stagePlatformEvents(triggerOperation, newList, oldMap);
    }

    // Contains common platform event staging data logic - because of future methods being unable to be called in a batch or future context the stagePlatformEvent methods are duplicated
    private static void stagePlatformEventData(String triggerOperation, List<cLog__c> newList, Map<Id, cLog__c> oldMap, String source) {
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
        list<cLog_Event__e> platformEventList = new List<cLog_Event__e>();    // List holds all of the platform events to be published
        cLog_Event__e platformEvent = new cLog_Event__e();    // Platform event which will be created
        
        // The following field(s) are unique to this handler's implementation of this method
        String endpointObject;

        // Bulkify the ACR_ContactId query. This map will only have values present when there are ACR records being deleted.
        Map<Id, String> cLogIdContactIdMap = createcLogIdContactIdMap(newList);

        // First create all of the platformEventStageRecords
        for(cLog__c theRecord : newList) {             
            listIteration++;    // Count the number of list iterations to perform exit loop operations when we are at the last record in newlist
            
            // Determine the destination system
            destinationSystem = determinePlatformEventDestination(theRecord);

            // Determine the endpointObject
            endpointObject = determinePlatformEventEndpointObject(theRecord);
            
            // If no destinationSystem or endpointObject is populated then no platform event needs to be generated for this cLog record in this loop iteration
            if(destinationSystem == '' || endpointObject == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.Action_Name = theRecord.Action_Name__c;
            platformEventPayloadStruct.Action_RecordId = theRecord.Action_Record_ID__c;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.Endpoint_Object = endpointObject;
            platformEventPayloadStruct.Focus_Area = theRecord.Focus_Area__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.is_Deleted = String.valueOf(theRecord.IsDeleted);
            platformEventPayloadStruct.is_Deleted_C = String.valueOf(theRecord.IsDeleted__c);
            platformEventPayloadStruct.Name = theRecord.Name;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Old_Related_Id = theRecord.OLD_Related_Id__c;
            platformEventPayloadStruct.Platform_Event_Publisher_Id = platformEventPublisher.Id;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RPN = theRecord.RPN__c;

            // Set the ACR_ContactId if the cLogIdContactIdMap contains the cLog's id as a key
            if(cLogIdContactIdMap.containsKey(theRecord.Id)) {
                platformEventPayloadStruct.ACR_ContactId = cLogIdContactIdMap.get(theRecord.Id);
            }
                    
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
                platformEvent = new cLog_Event__e();    // Allocate memory for a new platform event to be added to the platform event list
            }
            // If this is the first loop iteration but not the final
            else if(platformEventPublisherId == null) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;
            }
            // If there is a change of platform event publisher id then update accordingly
            else if(platformEventPublisherId != thePlatformEventStage.Platform_Event_Publisher__c) {
                platformEventPublisherId = thePlatformEventStage.Platform_Event_Publisher__c;

                platformEventList.add(platformEvent);    // Add the platform event to the list for publishing
                platformEvent = new cLog_Event__e();    // Allocate memory for a new platform event to be added to the platform event list
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
    private static void stagePlatformEventDataBatch(String triggerOperation, List<cLog__c> newList, Map<Id, cLog__c> oldMap, String source) {
        // The following group of fields will be common across all implementations of this method
        List<Platform_Event_Stage__c> platformEventStageList = new List<Platform_Event_Stage__c>();    // List of platform event stagine objects to be inserted into the database
        Platform_Event_Stage__c platformEventStage = new Platform_Event_Stage__c();    // Platform event stage record to create and add to the list
        PlatformEventStagePayloadStruct platformEventPayloadStruct = new PlatformEventStagePayloadStruct();    // Struct used to organize data in order to serialize it so it is able to be unravaelled later during platform event creation
        String destinationSystem;
        String serializedStruct;

        // The following field(s) are unique to this handler's implementation of this method
        String endpointObject;

        // Bulkify the ACR_ContactId query. This map will only have values present when there are ACR records being deleted.
        Map<Id, Id> cLogIdContactIdMap = createcLogIdContactIdMap(newList);

        for(cLog__c theRecord : newList) { 
            // Determine the destination system
            destinationSystem = determinePlatformEventDestination(theRecord);

            // Determine the endpointObject
            endpointObject = determinePlatformEventEndpointObject(theRecord);
            
            // If no destinationSystem or endpointObject is populated then no platform event needs to be generated for this cLog record in this loop iteration
            if(destinationSystem == '' || endpointObject == '') {
                continue;
            }

            // Assign values to the struct before serializing it. ***These values will always be different across all platform events***
            platformEventPayloadStruct.Action_Name = theRecord.Action_Name__c;
            platformEventPayloadStruct.Action_RecordId = theRecord.Action_Record_ID__c;
            platformEventPayloadStruct.Destination_System = destinationSystem;
            platformEventPayloadStruct.Endpoint_Object = endpointObject;
            platformEventPayloadStruct.Focus_Area = theRecord.Focus_Area__c;
            platformEventPayloadStruct.Id = theRecord.Id;
            platformEventPayloadStruct.is_Deleted = String.valueOf(theRecord.IsDeleted);
            platformEventPayloadStruct.is_Deleted_C = String.valueOf(theRecord.IsDeleted__c);
            platformEventPayloadStruct.Name = theRecord.Name;
            platformEventPayloadStruct.Old_Record_Id = theRecord.Old_Record_Id__c;
            platformEventPayloadStruct.Old_Related_Id = theRecord.OLD_Related_Id__c;
            platformEventPayloadStruct.Platform_Event_Type = triggerOperation;
            platformEventPayloadStruct.RPN = theRecord.RPN__c;
                
            // Set the ACR_ContactId if the cLogIdContactIdMap contains the cLog's id as a key
            if(cLogIdContactIdMap.containsKey(theRecord.Id)) {
                platformEventPayloadStruct.ACR_ContactId = cLogIdContactIdMap.get(theRecord.Id);
            }

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

    // Assign values to a cLog__c platform event - method is called from the PlatformEventPublishBatch class
    public static PlatformEventHandlerHelper populatePlatformEventData(Platform_Event_Stage__c thePlatformEventStage, PlatformEventHandlerHelper theHelper) {
        PlatformEventClogHandler.PlatformEventStagePayloadStruct platformEventPayload = (PlatformEventClogHandler.PlatformEventStagePayloadStruct)JSON.deserialize(thePlatformEventStage.Platform_Event_Payload__c, PlatformEventClogHandler.PlatformEventStagePayloadStruct.class);    // Deserialize the payload and cast it as the correct object from the handler corresponding to the type of sObject being iterated over in the batch job
        cLog_Event__e platformEvent = (cLog_Event__e)theHelper.getPlatformEvent();    //  Cast the platform event to the corresponding object being iterated over in the batch job
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
    private static String determinePlatformEventDestination(clog__c theRecord) {
        String destinationSystem = '';    // String containing the destination systems
        
        if(determineCdhNewSfdcToFusionDeleteContactRequired(theRecord) ||
           determineNewSfdcToFusionDeleteAcrRequired(theRecord)) {
            destinationSystem += PlatformEventHandlerHelper.CMS_DESTINATION_CODE;
        }

        if(determineGtmoNewSfdcToFusionMergeAccountsRequired(theRecord) ||
           determineNewSfdcToFusionMergeCompaniesRequired(theRecord)) {
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.STASH_DESTINATION_CODE;
            }
        }

        if(determineNewSfdcToFusionDeleteAccountRequired(theRecord) ||
           determineNewSfdcToFusionDeleteContactRequired(theRecord) ||
           determineNewSfdcToFusionDeleteDealCenterRequestRequired(theRecord) ||
           determineNewSfdcToFusionDeleteOppFocusAreaRequired(theRecord) ||
           determineNewSfdcToFusionDeleteOpportunityRequired(theRecord) ||
           determineNewSfdcToFusionDeleteOppTeamMemRequired(theRecord)) {
            // Assign temp value of none until receiving the actual values from Mulesoft
            if(destinationSystem != '') {
                destinationSystem += PlatformEventHandlerHelper.PLATFORM_EVENT_DESTINATION_SYSTEM_DELIMITER + PlatformEventHandlerHelper.NONE_DESTINATION_CODE;
            } else {
                destinationSystem += PlatformEventHandlerHelper.NONE_DESTINATION_CODE;
            }
        }

        return destinationSystem;
    }

    // Determinethe endpoint object for a platform event. ***This is a unique method for cLog platform events.***
    private static String determinePlatformEventEndpointObject(cLog__c theRecord) {
        String endpointObject = '';

        // If the endpoint URL is for contacts then assign 'contact' to the endpointObject field
        if(determineCdhNewSfdcToFusionDeleteContactRequired(theRecord) ||
           determineNewSfdcToFusionDeleteContactRequired(theRecord)) {
            endpointObject = 'contact';
        }
        // Decided that for ACR records there will be an exception to the url rule and actually provide the object name instead
        else if(determineNewSfdcToFusionDeleteAcrRequired(theRecord)) {
            endpointObject = 'acr';
        }
        // If the endpoint URL is for accounts then assign 'account' to the endpointObject field
        else if(determineGtmoNewSfdcToFusionMergeAccountsRequired(theRecord) ||
                determineNewSfdcToFusionDeleteAccountRequired(theRecord)) {
            endpointObject = 'account';
        }
        // If the endopint URL is for opportunities then assign 'opportunity' to the endpointObject field
        else if(determineNewSfdcToFusionDeleteDealCenterRequestRequired(theRecord) ||
                determineNewSfdcToFusionDeleteOppFocusAreaRequired(theRecord) ||
                determineNewSfdcToFusionDeleteOpportunityRequired(theRecord) ||
                determineNewSfdcToFusionDeleteOppTeamMemRequired(theRecord)) {
            endpointObject = 'opportunity';
        }
        // If the endopint URL is for companies then assign 'company' to the endpointObject field
        else if(determineNewSfdcToFusionMergeCompaniesRequired(theRecord)) {
            endpointObject = 'company';
        }

        return endpointObject;
    }


    // Determine if the record should have a CDH_NewSfdcToFusion-DeleteContact platform event staged
    private static Boolean determineCdhNewSfdcToFusionDeleteContactRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() && 
           !HELPER.userInFmwApiUserIdSet() && 
           theRecord.RPN__c != '' &&
           theRecord.RPN__c != null &&
           theRecord.Name == 'Contact') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a GTMO_NewSfdcToFusion_MergeAccounts platform event staged
    private static Boolean determineGtmoNewSfdcToFusionMergeAccountsRequired(cLog__c theRecord) {
        if(theRecord.Name == 'Account' &&
           theRecord.IsMerged__c &&
           theRecord.Master_Id__c != '' &&
           theRecord.Master_Id__c != null &&
           theRecord.Product_Account__c) {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteAccount platform event staged
    private static Boolean determineNewSfdcToFusionDeleteAccountRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Name == 'Account') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteACR platform event staged
    private static Boolean determineNewSfdcToFusionDeleteAcrRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Name == 'AccountContactRelation') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteContact platform event staged
    private static Boolean determineNewSfdcToFusionDeleteContactRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Name == 'Contact') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteDealCenterRequest platform event staged
    private static Boolean determineNewSfdcToFusionDeleteDealCenterRequestRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Old_Record_Id__c != '' &&
           theRecord.Old_Record_Id__c != null &&
           theRecord.Name == 'Deal_Center_Request__c') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteOppFocusArea platform event staged
    private static Boolean determineNewSfdcToFusionDeleteOppFocusAreaRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Old_Record_Id__c != '' &&
           theRecord.Old_Record_Id__c != null &&
           theRecord.Name == 'Opp_FocusArea__c') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteOpportunity platform event staged
    private static Boolean determineNewSfdcToFusionDeleteOpportunityRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Name == 'Opportunity') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-DeleteOppTeamMem platform event staged
    private static Boolean determineNewSfdcToFusionDeleteOppTeamMemRequired(cLog__c theRecord) {
        if(!HELPER.userInSkipUserIdSet() &&
           theRecord.Name == 'OpportunityTeamMember') {
            return true;
        }

        return false;
    }

    // Determine if the record should have a NewSfdcToFusion-MergeCompanies platform event staged
    private static Boolean determineNewSfdcToFusionMergeCompaniesRequired(cLog__c theRecord) {
        if(theRecord.Name == 'Account' &&
           theRecord.IsMerged__c &&
           theRecord.Master_Id__c != '' &&
           theRecord.Master_Id__c != null) {
            return true;
        }

        return false;
    }

    // Create a map relating the id of the cLog record created with the contact id of the ACR record which was just deleted. Map will only be known when ACR records have been deleted. Required for soql query bulkification.
    private static Map<Id, Id> createcLogIdContactIdMap(List<cLog__c> newList) {
        Map<Id, String> cLogIdContactIdMap = new Map<Id, String>();
        Map<String, Id> cLogActionRecordIDcLogIdMap = new Map<String, Id>();

        // Populate the map with the cLog Id keys and null values and create a set of cLog Action_Record_ID__c so we can get the correct ACR records in the following SOQL query
        for(cLog__c thecLog : newList) {
            if(thecLog.Action_Record_ID__c != null && thecLog.Action_Record_ID__c != '') {
                cLogActionRecordIDcLogIdMap.put(thecLog.Action_Record_ID__c,thecLog.Id);
            }
        }

        // Get the ACR records which were just deleted. Make sure that the id of the ACR record is equal to the Action_Record_ID__c field on the cLog record to make sure that we are getting the record linked to the cLog record.
        List<AccountContactRelation> acrList = [SELECT Id, Account_Contact_Ids__c 
                                                FROM AccountContactRelation 
                                                WHERE Id IN :cLogActionRecordIDcLogIdMap.keySet() 
                                                    AND IsDeleted = true ALL ROWS];

        // If there are ACR records present in the list then relate the cLog id to the Contact Id present on the ACR record
        if(!acrList.isEmpty()) {
            for(AccountContactRelation theAcr : acrList) {
                if(cLogActionRecordIDcLogIdMap.containsKey(theAcr.Id)) {
                    cLogIdContactIdMap.put(cLogActionRecordIDcLogIdMap.get(theAcr.Id),theAcr.Account_Contact_Ids__c.right(18));
                }
            }
        }

        return cLogIdContactIdMap;
    }

}