@isTest
private class NewProviderHelpcase_Test {
    @isTest static void testNewProviderHelpcaseTrigger() {
        // Create test data
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Provider_Help' LIMIT 1];
        System.assertNotEquals(null, recordType, 'Record type not found or test user does not have access.');

        // Create a test case
        String uniqueSubject = 'Test Case Subject ' + DateTime.now().format('yyyy-MM-dd_HH:mm:ss');
        Case testCase = new Case(
            Subject = uniqueSubject,
            Description = 'Test Case Description',
            Status = 'closed',
            RecordTypeId = recordType.Id,
            Origin = 'Email',
            Member_LOB__C = 'Individual'
            
        );
        insert testCase;

        // Create a test email message related to the test case
        EmailMessage testEmailMessage = new EmailMessage(
            Subject = 'Test Email Subject',
            TextBody = 'Test Email Body',
            FromAddress = 'test@example.com',
            RelatedToId = testCase.Id,
            Incoming = true
        );

        // Test trigger by inserting email message
        Test.startTest();
        insert testEmailMessage;
        Test.stopTest();

        // Verify the new case has been created
        List<Case> newCases = [SELECT Id, Subject, Description, SuppliedEmail, RecordTypeId, OwnerId, Origin FROM Case WHERE Subject = 'Test Email Subject' AND CreatedDate = TODAY];
        System.assertEquals(1, newCases.size());
        Case newCase = newCases[0];
        System.assertEquals(testEmailMessage.Subject, newCase.Subject);
        System.assertEquals(testEmailMessage.TextBody, newCase.Description);
        System.assertEquals(testEmailMessage.FromAddress, newCase.SuppliedEmail);
        System.assertEquals(recordType.Id, newCase.RecordTypeId);
    }
}