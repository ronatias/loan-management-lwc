@isTest
public class LoanRequestHelperTest {

    // This sets up a shared test account we can use in all test methods
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Customer');
        insert testAccount;
    }

    // This test makes sure that if a loan is inserted with no status and amount > 250K,
    // the helper sets its status to 'Pending' automatically
    @isTest
    static void testEnforcePendingStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = acc.Id,
            LoanAmount__c = 300000,
            LoanStatus__c = null
        );
        List<LoanRequest__c> loans = new List<LoanRequest__c>{ loan };
        LoanRequestHelper.enforcePendingStatus(loans);
        System.assertEquals('Pending', loan.LoanStatus__c);
    }

    // This test checks the full flow:
    // 1. A high-value loan triggers a task
    // 2. Changing status to 'Approved' adds a LoanHistory record
    // 3. Changing status to 'Declined' adds a DeclinedLoanReport record
    // Also confirms that the task description includes the customer name
    @isTest
    static void testProcessLoanRequests_AllPaths() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        // Insert initial loan
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = testAcc.Id,
            LoanAmount__c = 300000,
            LoanDate__c = Date.today(),
            LoanStatus__c = 'Pending'
        );
        insert loan;

        // Fake old loan data with the same status
        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>();
        LoanRequest__c oldLoan = loan.clone(false, false, false, false);
        oldMap.put(loan.Id, oldLoan);

        // Change loan to approved and process
        loan.LoanStatus__c = 'Approved';
        update loan;
        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{loan}, oldMap);

        // Change loan to declined and process again
        oldMap.put(loan.Id, loan.clone(false, false, false, false));
        loan.LoanStatus__c = 'Declined';
        update loan;
        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{loan}, oldMap);

        // Check that all records were created correctly
        System.assert([SELECT COUNT() FROM Task WHERE WhatId = :loan.Id] > 0, 'Task not created');
        System.assert([SELECT COUNT() FROM LoanHistory__c WHERE Customer__c = :testAcc.Id] > 0, 'LoanHistory__c not created');
        System.assert([SELECT COUNT() FROM DeclinedLoanReport__c WHERE LoanRequest__c = :loan.Id] > 0, 'DeclinedLoanReport__c not created');

        // Make sure the task includes the real customer name (not "Unknown")
        Task createdTask = [SELECT Description FROM Task WHERE WhatId = :loan.Id LIMIT 1];
        System.assert(createdTask.Description.startsWith('Customer: Test Customer'), 'Customer name not resolved correctly in Task description');
    }

    // This test makes sure that if a loan has no customer assigned,
    // the helper doesn't crash and still runs as expected
    @isTest
    static void testProcessLoanRequest_NoCustomer() {
        LoanRequest__c loan = new LoanRequest__c(
            LoanAmount__c = 300000,
            LoanStatus__c = 'Pending',
            LoanDate__c = Date.today()
        );
        insert loan;

        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>();
        oldMap.put(loan.Id, loan.clone(false, false, false, false));

        Test.startTest();
        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{loan}, oldMap);
        Test.stopTest();

        System.assert(true, 'Processed loan with no customer and no crash');
    }
}
