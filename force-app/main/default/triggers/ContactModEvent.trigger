trigger ContactModEvent on Contact_Mod__e (after insert) {

    List<String> platformEventPublisherUpdateList = new List<String>();
    List<FeedItem> feedItemList = new List<FeedItem>();    // Contains the feed posts for debugging
    String feedbody = '';
    Integer count = 0;
    
    for(Contact_Mod__e conEvent : trigger.New){
        count++;

        // Add the Platform Event Publisher Id to the list of Platform Event Publisher Ids
        // platformEventPublisherUpdateList.add(conEvent.Payload_Set_1__c.indexOf('platformEventPublisherId'));

        // Generate body of feed post for every conEvent record
        String feedBodyAppend = 'Environment: IntTest' + '\n' +
        'Object: ' + 'Contact Mod' + '\n' +
        'The number of platform events present: ' + count + '\n' + '\n' +
        'The payload is: ' + conEvent.Payload_Set_1__c + '\n' + '\n' + '\n';

        //String feedBodyAppend = 'Test' + '\n' + '\n' + '\n';

        feedbody += feedBodyAppend;
    }

    // Update the Platform Event Publisher records to Published
    List<Platform_Event_Publisher__c> platformEventPublisherList = new List<Platform_Event_Publisher__c>();
    for(Platform_Event_Publisher__c thePublisher : [SELECT Id, Publisher_Status__c FROM Platform_Event_Publisher__c WHERE Id IN :platformEventPublisherUpdateList]) {
        thePublisher.Publisher_Status__c = PlatformEventHandlerHelper.PUBLISHED_PUBLISHER_STATUS_CODE;

        platformEventPublisherList.add(thePublisher);
    }

    if(!platformEventPublisherList.isEmpty()) {
        try {
            update platformEventPublisherList;
        } catch(DmlException e) {
            // TODO: implement clog insertion here
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    // Sesha's feed item
    FeedItem newFeedItem1 = new FeedItem(Body = feedbody,
                                         ParentId = '0053f000000pLAKAA2',
                                         Type = 'TextPost');
    feedItemList.add(newFeedItem1);

    // Nathan's feed item
    FeedItem newFeedItem2 = new FeedItem(Body = feedbody,
                                         ParentId = '0053f000000Ww7UAAS',
                                         Type = 'TextPost');
    feedItemList.add(newFeedItem2);

    if(feedItemList.size() > 0) {
        insert feedItemList;
    }

}