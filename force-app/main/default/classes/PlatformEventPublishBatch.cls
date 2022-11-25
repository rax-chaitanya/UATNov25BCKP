// Batch job will consume staged platform events and publsih them. This batch job will be scheduled to run in a set time interval.

public with sharing class PlatformEventPublishBatch implements Database.Batchable<sObject>, Database.Stateful {

    private final Integer HEAP_DIFFERENCE = 1500000;    // If there is 1.5mb of space left on the heap publish all of the platform events and wipe the objectNamePlatformEventMap
    private final Integer PLATFORM_EVENT_PUBLISHER_BUFFER_SIZE = 200;    // The maximum number of platform event publisher records present in the buffer

    private Map<String, PlatformEventHandlerHelper> objectNameHandlerMap = new Map<String, PlatformEventHandlerHelper>();    // Relates the sObject name to its corresponding handler
    
    private List<Platform_Event_Publisher__c> platformEventPublisherBuffer = new List<Platform_Event_Publisher__c>();    // List containing the buffer of Platform Event Publisher records
    private Set<Platform_Event_Publisher__c> platformEventPublisherBufferTracker = new Set<Platform_Event_Publisher__c>();    // Set containing the buffer records currently in use and not yet set to processed
    private String query;

    // Constructor for general code execution - schedule with this constructor
    public PlatformEventPublishBatch() {
        query = 'SELECT Id, Destination_System__c, sObject_Type__c, Platform_Event_Payload__c, Platform_Event_Publisher__c, Platform_Event_Type__c, Record_Id__c FROM Platform_Event_Stage__c WHERE Platform_Event_Stage_Status__c IN (\'New\',\'Processed\') AND Platform_Event_Source__c = \'Batch\' ORDER BY CreatedDate ASC';
    }

    // Constructor for specific platform event operations
    public PlatformEventPublishBatch(String query) {
        this.query = query;
    }

    // Start method gets staged platform events for given query
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Make sure that we have 200 Platform Event Publisher records in the buffer
        platformEventPublisherBuffer.addAll(refillPlatformEventPublisherBuffer());

        return Database.getQueryLocator(query);
    }

    // Execute method will publish all of the platform events. Maximizing memory usage on each platform event which is published.
    public void execute(Database.BatchableContext BC, List<Platform_Event_Stage__c> scope) {
        Map<String, List<sObject>> platformEventPublishMap = new Map<String, List<sObject>>();    // Map of platform events to publish
        Map<String, List<Platform_Event_Publisher__c>> platformEventPublisherProcessedListMap = new Map<String, List<Platform_Event_Publisher__c>>();    // Map of Platform Event Publisher records to process

        // Always make sure that there are 200 Platform Event Publisher records present in the buffer (200 because in a worst case we are working on 200 separate platform events due to max batch size being 200)
        platformEventPublisherBuffer.addAll(refillPlatformEventPublisherBuffer());

        System.debug('Platform Event Publish Buffer size is: ' + platformEventPublisherBuffer.size());
        System.debug('Platform Event Buffer Tracker size is: ' + platformEventPublisherBufferTracker.size());

        // Build objectNamePlatformEventMap by assocatiating a platform event with its associated object type
        for(Platform_Event_Stage__c thePlatformEventStage : scope) {
            System.debug('The heap at the start of scope: ' + Limits.getHeapSize());

            // Initialize all maps which correspond to the current platform event stored 
            if(!objectNameHandlerMap.containsKey(thePlatformEventStage.sObject_Type__c)) {
                objectNameHandlerMap.put(thePlatformEventStage.sObject_Type__c, platformEventHandlerHelperFactory(thePlatformEventStage.sObject_Type__c));    // Initialize objectNameHandlerMap with sobject type and the sobject's corresponding platform event handler helper

                // Set necessary values on the handler
                objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).setPlatformEvent(platformEventFactory(thePlatformEventStage.sObject_Type__c));    // Sets the platform event value on the handler related to this type of platform event
                objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).setPlatformEventPublisher(getPlatformEventPublisherBufferRecord());    // Sets the platform event publisher value on the handler related to this typ of platform event

                System.debug('The heap after initialization: ' + Limits.getHeapSize());
            }

            // If the amount of records in the platform event is equal to the maximum amount allowed for the platform event type then add the platform event to the platformEventPublishMap and reset the platform event and the record counter
            if(objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getNumRecordsInPlatformEvent() == objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventMetadata().Num_Records_Allowed_Per_Platform_Event__c) {    

                // Add the platform event to the platformEventPublishMap (this is the case when we have already added a platform event to be published to the map)
                if(platformEventPublishMap.containsKey(thePlatformEventStage.sObject_Type__c)) {
                    platformEventPublishMap.get(thePlatformEventStage.sObject_Type__c).add(objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEvent());
                    platformEventPublisherProcessedListMap.get(thePlatformEventStage.sObject_Type__c).add(objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventPublisher());

                    System.debug('The heap inside contains key if: ' + Limits.getHeapSize());
                } 
                // Initialize the list containing the platform events to be published (when we are initially adding a platform event of a specific type to the map)
                else {
                    List<sObject> platformEventList = new List<sObject>();
                    //platformEventList.add(objectNamePlatformEventMap.get(thePlatformEventStage.sObject_Type__c));
                    platformEventList.add(objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEvent());
                    
                    List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();
                    //platformEventPublisherList.add(objectNamePlatformEventPublisherMap.get(thePlatformEventStage.sObject_Type__c));
                    platformEventPublisherList.add(objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventPublisher());

                    platformEventPublishMap.put(thePlatformEventStage.sObject_Type__c, platformEventList);
                    platformEventPublisherProcessedListMap.put(thePlatformEventStage.sObject_Type__c, platformEventPublisherList);

                    System.debug('The heap inside contains key else: ' + Limits.getHeapSize());
                }
                
                // Reset values in objectNamePlatformEventMap and objectNameNumRecordsInPlatformEventMap then populate the platform event data from the platform event stage which triggered this code block
                objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).setPlatformEvent(platformEventFactory(thePlatformEventStage.sObject_Type__c));    // Sets the platform event value on the handler related to this type of platform event
                objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).setPlatformEventPublisher(getPlatformEventPublisherBufferRecord());    // Sets the platform event publisher value on the handler related to this typ of platform event
                objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).setNumRecordsInPlatformEvent(0);    // Resets the number of records in platform event back to 0

                System.debug('The heap after value reset: ' + Limits.getHeapSize());

                objectNameHandlerMap.put(thePlatformEventStage.sObject_Type__c, populatePlatformEventData(thePlatformEventStage));

                thePlatformEventStage.Platform_Event_Publisher__c = objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventPublisher().Id;    // Update the Platform Event Stage being iterated over with the id of the Platform Event Publisher record in the objectNamePlatformEventPublisherMap

                System.debug('The heap at end of contains key: ' + Limits.getHeapSize());
            }
            // If the amount of records is less than the maximum amount allowed for the platform event type then add the platform event to the objectNamePlatformEventMap and increment the corresponding value in the objectNameNumRecordsInPlatformEventMap by 1
            else {
                objectNameHandlerMap.put(thePlatformEventStage.sObject_Type__c, populatePlatformEventData(thePlatformEventStage));

                thePlatformEventStage.Platform_Event_Publisher__c = objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventPublisher().Id;    // Update the Platform Event Stage being iterated over with the id of the Platform Event Publisher record in the objectNamePlatformEventPublisherMap

                System.debug('The heap at end of scope else: ' + Limits.getHeapSize());
            }

            /* // If the heap size is within 1.5mb of the 12mb limit then make sure that all platform events are present in the platformEventPublishMap and then publish the platform events to free up heap space
            if(Limits.getLimitHeapSize() - Limits.getHeapSize() <= HEAP_DIFFERENCE) {
                System.debug('This is the heap exception execution');
                
                for(String sObjectType : objectNamePlatformEventMap.keySet()) {
                    // Check to see if there are any records within the platform event
                    if(objectNameNumRecordsInPlatformEventMap.get(sObjectType) > 0) {
                        // Initialize the list containing the platform events to be published (will only be doing this once since we will have less than the maximum amount of records per object type)
                        List<sObject> platformEventList = new List<sObject>();
                        platformEventList.add(objectNamePlatformEventMap.get(sObjectType));
                        
                        // Immediately wipe the platform event out of the objectNamePlatformEventMap in order to free up heap (we are essentially duplicating the platform event temporarily by adding it to the above list). Also reset the record count for the platform event.
                        objectNamePlatformEventMap.put(thePlatformEventStage.sObject_Type__c, platformEventFactory(thePlatformEventStage.sObject_Type__c));
                        objectNameNumRecordsInPlatformEventMap.put(sObjectType, 0);

                        platformEventPublishMap.put(sObjectType, platformEventList);    // Add the platform event list to the map for publishing
                    }
                }
                
                publishPlatformEvents(platformEventPublishMap);
            } */
        }

        // Publish platform events which are ready to be published
        publishPlatformEvents(platformEventPublishMap, platformEventPublisherProcessedListMap);

        System.debug('The heap at end of scope: ' + Limits.getHeapSize());

        try {
            update scope;    // Update the platform event records with the correct Publisher ids
        } catch(DmlException e) {
            // TODO: implement clog insertion here
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    // Finish method will finish inserting platform events if any more remain
    public void finish(Database.BatchableContext BC) {
        Map<String, List<sObject>> platformEventPublishMap = new Map<String, List<sObject>>();    // Map of platform events to publish
        Map<String, List<Platform_Event_Publisher__c>> platformEventPublisherProcessedListMap = new Map<String, List<Platform_Event_Publisher__c>>();    // Map of Platform Event Publishers to update to Processed

        System.debug('The heap at start of finish method: ' + Limits.getHeapSize());

        // Publish all platform events which are remaining
        for(String sObjectType : objectNameHandlerMap.keySet()) {
            if(objectNameHandlerMap.get(sObjectType).getNumRecordsInPlatformEvent() > 0) {
                System.debug('The heap at start of finish method loop: ' + Limits.getHeapSize());
                
                // Initialize the list containing the platform events to be published (will only be doing this once since we will have less than the maximum amount of records per object type)
                List<sObject> platformEventList = new List<sObject>();
                //platformEventList.add(objectNamePlatformEventMap.get(sObjectType));
                platformEventList.add(objectNameHandlerMap.get(sObjectType).getPlatformEvent());

                // Intialize the platformEventPublisherProcessedListMap
                List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();
                //platformEventPublisherList.add(objectNamePlatformEventPublisherMap.get(sObjectType));
                platformEventPublisherList.add(objectNameHandlerMap.get(sObjectType).getPlatformEventPublisher());

                System.debug('The heap at middle of finish method loop: ' + Limits.getHeapSize());

                // Immediately wipe the platform event out of the objectNamePlatformEventMap in order to free up heap (we are essentially duplicating the platform event temporarily by adding it to the above list). Also reset the record count for the platform event.
                objectNameHandlerMap.get(sObjectType).setPlatformEvent(null);
                objectNameHandlerMap.get(sObjectType).setPlatformEventPublisher(null);
                objectNameHandlerMap.get(sObjectType).setNumRecordsInPlatformEvent(0);
                
                platformEventPublishMap.put(sObjectType, platformEventList);    // Add the platform event list to the map for publishing
                platformEventPublisherProcessedListMap.put(sObjectType, platformEventPublisherList);    // Add the Platform Event Publisher list to the map for updating records to Processed

                System.debug('The heap at end of finish method loop: ' + Limits.getHeapSize());
            }
        }

        System.debug('This is the heap size at the end finish method before publish: ' + Limits.getHeapSize());

        // Publish the platform events
        publishPlatformEvents(platformEventPublishMap, platformEventPublisherProcessedListMap);

        System.debug('The heap at end of finish method loop: ' + Limits.getHeapSize());
    }

    // Publish platform events
    private void publishPlatformEvents(Map<String, List<sObject>> platformEventPublishMap, Map<String, List<Platform_Event_Publisher__c>> platformEventPublisherProcessedListMap) {
        System.debug('The heap at start of publish platform events: ' + Limits.getHeapSize());
        
        List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();    // List contains the new Platform_Event_Publisher__c records required to be created
        List<sObject> platformEventList = new List<sObject>();    // Allows bulk publishing of all platform event types simultaneously

        // Assign the Platform Event Publisher id to the individual platform events as well as mark the Platform Event Publisher record as 'Processed' and update the Platform Event Publisher records
        Integer size;
        for(String sObjectType : platformEventPublishMap.keySet()) {
            size = platformEventPublishMap.get(sObjectType).size();
            for(Integer i = size - 1; i >= 0; i--) {
                System.debug('The iterator is: ' + i);
                System.debug('The size of the platformEventPublishMap list is: ' + platformEventPublishMap.get(sObjectType).size());
                System.debug('The size of the platformEventPublisherProcessedListMap list is: ' + platformEventPublishMap.get(sObjectType).size());
                    
                platformEventPublishMap.get(sObjectType)[i].put('Platform_Event_Publisher_Id__c', platformEventPublisherProcessedListMap.get(sObjectType)[i].Id);    // It is an invariant within this batch job that the lists stored in these maps always have the same order - index i in platformEventPublishMap corresponds to index i in platformEventPublisherProcessedMap

                platformEventPublisherProcessedListMap.get(sObjectType)[i].Publisher_Status__c = 'Processed';    // Mark the Platform Event Publisher as Processed
                platformEventPublisherBufferTracker.remove(platformEventPublisherProcessedListMap.get(sObjectType)[i]);    // Remove the Platform Event Publisher from the tracker because we only need to worry about duplicates when the Publisher Status is equal to New (queries check for New status in this batch job)

                System.debug('The publisher status is: ' + platformEventPublisherProcessedListMap.get(sObjectType)[i].Publisher_Status__c);

                platformEventList.add(platformEventPublishMap.get(sObjectType)[i]);    // Add the platform event to the list for publishing
                platformEventPublisherList.add(platformEventPublisherProcessedListMap.get(sObjectType)[i]);    // Add the Platform Event Publisher to the list for updating

                platformEventPublishMap.get(sObjectType).remove(i);    // Pop the object stored in the index to free memory as we go since we are copying the values
                platformEventPublisherProcessedListMap.get(sObjectType).remove(i);    // Pop the Platform Event Publisher stored in the index to free memory as we go since we are copying the values
            }
        }

        System.debug('The heap after first loop of publish platform events: ' + Limits.getHeapSize());

        // Update the Platform Event Publisher records as Processed
        try {
            update platformEventPublisherList;
        } catch(DmlException e) {
            // TODO: implement clog insertion here
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

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
                        
                cLog__c errorLog = new cLog__c(Name = PlatformEventHandlerHelper.PLATFORM_EVENT_ALL_EVENTS_METADATA.cLog_Name__c,
                                               Action_Name__c = PlatformEventHandlerHelper.PLATFORM_EVENT_ALL_EVENTS_METADATA.cLog_Action_Name__c,
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
        
        System.debug('The heap at end of publish platform events: ' + Limits.getHeapSize());

        platformEventList.clear();    // Clear list of platform events for the next round
        platformEventPublishMap.clear();    // After publishing platform events clear the map's list in order to free up heap
        platformEventPublisherProcessedListMap.clear();    // After publishing platform events clear the list of processed Platform Event Publishers

        System.debug('platformEventPublishMap in end publish platform event method: ' + platformEventPublishMap.values().size());
        
    }

    // Always makes sure that we have 200 Platform Event Publisher records in the memory buffBer
    private List<Platform_Event_Publisher__c> refillPlatformEventPublisherBuffer() {
        List<Platform_Event_Publisher__c> platformEventPublisherBufferAdditionList = new List<Platform_Event_Publisher__c>();    // List containing all Platform Event Publisher records to reset the buffer to 200 records
        List<Platform_Event_Publisher__c> platformEventPublisherBufferCurrentList = new List<Platform_Event_Publisher__c>();    // List containing all currently existing Platform Event Publisher records

        platformEventPublisherBuffer.clear();    // Clear the buffer

        // Check to make sure that we aren't adding any records which are already in use which are tracked in the tracker - will only hit this case during running of this batch job. If a record is present in the tracker then it hasn't had its status updated to Processed yet but it will after the batch job is finished running.
        if(!platformEventPublisherBufferTracker.isEmpty()) {
            for(Platform_Event_Publisher__c thePublisher : [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Publisher_Status__c = 'New' ORDER BY CreatedDate DESC]) {
                if(!platformEventPublisherBufferTracker.contains(thePublisher) && platformEventPublisherBufferCurrentList.size() < PLATFORM_EVENT_PUBLISHER_BUFFER_SIZE) {
                    platformEventPublisherBufferCurrentList.add(thePublisher);
                }
            }
        } 
        // If the tracker is empty then just refill the buffer to maximum size
        else {
            for(Platform_Event_Publisher__c thePublisher : [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Publisher_Status__c = 'New' ORDER BY CreatedDate DESC]) {
                if(platformEventPublisherBufferCurrentList.size() < PLATFORM_EVENT_PUBLISHER_BUFFER_SIZE) {
                    platformEventPublisherBufferCurrentList.add(thePublisher);
                }
            }
        }
        
        // The platformEventPublisherBufferAdditionList size will always be <= to PLATFORM_EVENT_PUBLISHER_BUFFER_SIZE. Add new Platform Event Publisher records to the buffer as required.
        for(Integer i = 0; i < PLATFORM_EVENT_PUBLISHER_BUFFER_SIZE - platformEventPublisherBufferCurrentList.size(); i++) {
            platformEventPublisherBufferAdditionList.add(new Platform_Event_Publisher__c());
        }

        // Insert new Platform Event Publisher records to reset buffer
        if(!platformEventPublisherBufferAdditionList.isEmpty()) {
            try {
                insert platformEventPublisherBufferAdditionList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        platformEventPublisherBufferCurrentList.clear();    // Clear the list
        platformEventPublisherBufferAdditionList.clear();    // Clear list for reuse

        // Get the newly inserted Platform Event Publisher records and return the list void of duplicates
        if(!platformEventPublisherBufferTracker.isEmpty()) {
            for(Platform_Event_Publisher__c thePublisher : [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Publisher_Status__c = 'New' ORDER BY CreatedDate DESC]) {
                if(!platformEventPublisherBufferTracker.contains(thePublisher)) {
                    platformEventPublisherBufferAdditionList.add(thePublisher);
                }
            }

            return platformEventPublisherBufferAdditionList;
        } else {
            return [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Publisher_Status__c = 'New' ORDER BY CreatedDate DESC];
        }
    }

    // Gets a Platform Event Publisher record from the Platform Event Publisher buffer
    private Platform_Event_Publisher__c getPlatformEventPublisherBufferRecord() {
        Platform_Event_Publisher__c platformEventPublisher = platformEventPublisherBuffer.remove(0);    // Gets the record stored in the first index of the platformEventPublisherBuffer and removes it from the list
        
        platformEventPublisherBufferTracker.add(platformEventPublisher);    // Add the buffer record to the tracker
        
        return platformEventPublisher;
    }

    // ***The following methods must be tied into each Platform Event Handler class which is created for every platform event***

    // Create new platform events based on sObject type
    private sObject platformEventFactory(String sObjectType) {
        String sObjectName = objectNameHandlerMap.get(sObjectType).getPlatformEventMetadata().sObject_Name__c;    // Get the sObjectName from the objectNameHandlerMap
        
        // If the platform event will be generated by a contact record then return a Contact__e event
        if(sObjectName == PlatformEventContactHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return new Contact__e();
        }
        // If the platform event will be generated by a cLog record then return a cLog_Event__e event
        else if(sObjectName == PlatformEventClogHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return new cLog_Event__e();
        }
        // If the platform event will be generated by an ACR record then return a ACR__e event
        else if(sObjectName == PlatformEventAcrHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return new ACR__e();
        }

        return null;
    }

    // Create new platform event handler helpers based on sObject type
    private PlatformEventHandlerHelper platformEventHandlerHelperFactory(String sObjectType) {
        // If the platform event will be generated by a contact record then return a PlatformEventContactHandler helper
        if(sObjectType == PlatformEventContactHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventContactHandler.HELPER;
        }
        // If the platform event will be generated by a cLog record then return a PlatformEventClogHandler helper
        else if(sObjectType == PlatformEventClogHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventClogHandler.HELPER;
        }
        // If the platform event will be generated by an ACR record then return a PlatformEventClogHandler helper
        else if(sObjectType == PlatformEventAcrHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventAcrHandler.HELPER;
        }

        return null;
    }

    // Populate the platform event depending on the type of platform event stage
    private PlatformEventHandlerHelper populatePlatformEventData(Platform_Event_Stage__c thePlatformEventStage) {
        String sObjectName = objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c).getPlatformEventMetadata().sObject_Name__c;
        
        // If the platform event is a contact event then populate the platform event with the corresponding data
        if(sObjectName == PlatformEventContactHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventContactHandler.populatePlatformEventData(thePlatformEventStage, objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c));
        }
        // If the platform event is a cLog event then populate the platform event with the corresponding data
        else if(sObjectName == PlatformEventClogHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventClogHandler.populatePlatformEventData(thePlatformEventStage, objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c));
        }
        // If the platform event is an ACR event then populate the platform event with the corresponding data
        else if(sObjectName == PlatformEventAcrHandler.HELPER.getPlatformEventMetadata().sObject_Name__c) {
            return PlatformEventAcrHandler.populatePlatformEventData(thePlatformEventStage, objectNameHandlerMap.get(thePlatformEventStage.sObject_Type__c));
        }

        return null;
    }

}