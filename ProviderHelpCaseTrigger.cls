trigger NewProviderHelpcase on EmailMessage (after insert) {
    // Query the Record Type object to find the ID of the "Provider help" record type
    Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Provider_Help' LIMIT 1].Id;

    // Query the Queue Id for 'Provider Help'
    Id providerHelpQueueId;
    List<Group> providerHelpQueues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Provider_Help' LIMIT 1];
    if (!providerHelpQueues.isEmpty()) {
        providerHelpQueueId = providerHelpQueues[0].Id;
    } else {
        // If the 'Provider Help' queue is not found, you may need to create it in your org
        System.debug('Provider Help queue not found');
        return;
    }
    system.debug('*** providerHelpQueues is here: '+providerHelpQueues);
    List<Case> casesToInsert = new List<Case>();

    // Get the related Case records
    Map<Id, Case> parentCasesMap = new Map<Id, Case>([SELECT Id, IsClosed, RecordTypeId FROM Case WHERE Id IN (SELECT RelatedtoId FROM EmailMessage WHERE Id IN :Trigger.new)AND Status = 'closed']);
    system.debug('*** parentCasesMap is here: '+parentCasesMap);
    
    for (EmailMessage emailMessage : Trigger.new) {
        Case parentCase = parentCasesMap.get(emailMessage.RelatedtoId);
        system.debug('*** emailMessage is here: '+emailMessage);
        if (parentCase != null && parentCase.IsClosed && parentCase.RecordTypeId == recordTypeId) {
            Case newCase = new Case(
                Subject = emailMessage.Subject,
                Description = emailMessage.TextBody,
                SuppliedEmail = emailMessage.FromAddress,
                RecordTypeId = recordTypeId,
                OwnerId = providerHelpQueueId,
                Origin = 'Email',
                Status = 'New'
            );
            casesToInsert.add(newCase);
        }
    }
    system.debug('*** casesToInsert is here: '+casesToInsert);
    if (!casesToInsert.isEmpty()) {
        insert casesToInsert;
    }
}