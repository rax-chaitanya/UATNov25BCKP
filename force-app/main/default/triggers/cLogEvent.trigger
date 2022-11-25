trigger cLogEvent on cLog_Event__e (after insert) {
    // Mark the platform event publisher records as published
    PlatformEventTriggerHandler.publishPlatformEventPublishers(Trigger.new);

    // If enabled output the platform event payload as a feed item to configured users
    PlatformEventTriggerHandler.outputFeedToUsers(Trigger.new, 'cLog_Events');
}