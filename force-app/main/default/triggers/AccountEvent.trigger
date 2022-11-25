trigger AccountEvent on Account__e (after insert) {
    // Mark the platform event publisher records as published
    PlatformEventTriggerHandler.publishPlatformEventPublishers(Trigger.new);

    // If enabled output the platform event payload as a feed item to configured users
    PlatformEventTriggerHandler.outputFeedToUsers(Trigger.new, 'Account_Events');
}