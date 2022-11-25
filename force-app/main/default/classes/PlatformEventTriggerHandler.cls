// Trigger handler for all Platform Event triggers

public with sharing class PlatformEventTriggerHandler {
    @TestVisible private static String feedItemIdList;    // Comma separated list containing the ids of users to send feed items to
    @TestVisible private static Boolean allEventsFeedItemOutputEnabled = false;    // Testing value to simulate the Feed Item Output Enabled field on the All_Events metadata record
    @TestVisible private static Boolean thisEventFeedItemOutputEnabled = false;    // Testing value to simulate the Feed Item Output Enabled field on this event's metadata record

    // Output the platform event payload as a feed item to a specified group of users
    public static void outputFeedToUsers(List<sObject> newList, String platformEventManagerName) {
        // Get the all events custom metadata record
        Platform_Event_Manager__mdt allEventsMetadata = [SELECT Id, Feed_Item_Id_List__c, Feed_Item_Output_Enabled__c
                                                         FROM Platform_Event_Manager__mdt 
                                                         WHERE DeveloperName = 'All_Events' LIMIT 1];

        // Get the custom metadata record for this object
        Platform_Event_Manager__mdt thisEventMetadata = [SELECT Id, Feed_Item_Output_Enabled__c, sObject_Name__c
                                                         FROM Platform_Event_Manager__mdt 
                                                         WHERE DeveloperName = :platformEventManagerName LIMIT 1];

        List<FeedItem> feedItemList = new List<FeedItem>();    // Contains the feed posts for debugging
        String feedbody = '';    // The body of text to send to the users' feeds/emails
        Integer count = 0;    // Counts the number of platform events iterated over

        // If the feed output is enabled then build the feedbody and output it to the users
        if(Test.isRunningTest() && (!allEventsFeedItemOutputEnabled || !thisEventFeedItemOutputEnabled)) {
            return;
        } else if(!allEventsMetadata.Feed_Item_Output_Enabled__c || !thisEventMetadata.Feed_Item_Output_Enabled__c) {
            return;
        }

        // Build the feedbody
        for(sObject theEvent : newList) {
            count++;    // Increment count to track the number of platform events processed
            
            // Generate body of feed post for every conEvent record
            String feedBodyAppend = 'Environment: ' + UserInfo.getOrganizationId() + '\n' +
                                    'Object: ' + thisEventMetadata.sObject_Name__c + '\n' +
                                    'The number of platform events present: ' + count + '\n' + '\n' +
                                    'The payload is: ' + theEvent.get('Payload_Set_1__c') + theEvent.get('Payload_Set_2__c') + theEvent.get('Payload_Set_3__c') + theEvent.get('Payload_Set_4__c') + '\n' + '\n' + '\n';

            feedbody += feedBodyAppend;
        }

        // Get the list of ids to send to users. If a test is not running then overwrite the feedItemIdList with the list of ids from the All_Events custom metadata record
        if(!Test.isRunningTest()) {
            feedItemIdList = allEventsMetadata.Feed_Item_Id_List__c;
        }
        
        // Build the feedItemList
        for(String userId : feedItemIdList.split(',')) {
            FeedItem newFeedItem = new FeedItem(Body = feedbody,
                                                ParentId = userId,
                                                Type = 'TextPost');

            feedItemList.add(newFeedItem);
        }

        // Insert the feedItemList
        if(feedItemList.size() > 0) {
            insert feedItemList;
        }
    }

    // Mark the platform event publisher records as published
    public static void publishPlatformEventPublishers(List<sObject> newList) {
        List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();    // List of platform event publishers to be updated to published
        List<String> platformEventPublisherUpdateList = new List<String>();    // List of strings (platform event publisher ids) extracted from the platform event payloads
        String publisherId;    // The platform even publisher id extracted from the platform event payload
        String payload;
        Integer startIndex;    // The starting index in the platform event payload where the platform event publisher id begins

        // Build the platformEventPublisherUpdateList
        for(sObject theEvent : newList) {
            payload = (String)theEvent.get('Payload_Set_1__c');    // Get the payload string (must convert it to string from an object first)
            
            // Add the Platform Event Publisher Id to the list of Platform Event Publisher Ids
            startIndex = payload.indexOf('Platform_Event_Publisher_Id');    // Get the start of the platform event publisher id in the payload string
            publisherId = payload.subString(startIndex + 30, startIndex + 48);    // Get the 18 character platform event publisher id substring from the payload string
            platformEventPublisherUpdateList.add(publisherId);    // Add the publisherId to the platformEventPublisherUpdateList
        }

        // Update the Platform Event Publisher records to Published
        for(Platform_Event_Publisher__c thePublisher : [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Id IN :platformEventPublisherUpdateList]) {
            thePublisher.Publisher_Status__c = PlatformEventHandlerHelper.PUBLISHED_PUBLISHER_STATUS_CODE;

            platformEventPublisherList.add(thePublisher);
        }

        // Update the platform event publisher records
        if(!platformEventPublisherList.isEmpty()) {
            try {
                update platformEventPublisherList;
            } catch(DmlException e) {
                // TODO: implement clog insertion here
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }

}