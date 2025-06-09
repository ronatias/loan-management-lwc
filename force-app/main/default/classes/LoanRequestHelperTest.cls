@isTest
public class LoanRequestHelperTest {

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Customer');
        insert testAccount;
    }

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

    @isTest
    static void testProcessLoanRequests_AllPaths() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        // Insert Loan with high value and status Pending
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = testAcc.Id,
            LoanAmount__c = 300000,
            LoanDate__c = Date.today(),
            LoanStatus__c = 'Pending'
        );
        insert loan;

        // Simulate Trigger.oldMap with LoanStatus = 'Pending'
        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>();
        LoanRequest__c oldLoan = loan.clone(false, false, false, false);
        oldMap.put(loan.Id, oldLoan);

        // Update status to Approved
        loan.LoanStatus__c = 'Approved';
        update loan;

        // Call helper manually to simulate Trigger.afterUpdate
        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{loan}, oldMap);

        // Update status to Declined
        oldMap.put(loan.Id, loan.clone(false, false, false, false));
        loan.LoanStatus__c = 'Declined';
        update loan;

        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{loan}, oldMap);

        // Validate results
        System.assert([SELECT COUNT() FROM Task WHERE WhatId = :loan.Id] > 0, 'Task not created');
        System.assert([SELECT COUNT() FROM LoanHistory__c WHERE Customer__c = :testAcc.Id] > 0, 'LoanHistory__c not created');
        System.assert([SELECT COUNT() FROM DeclinedLoanReport__c WHERE LoanRequest__c = :loan.Id] > 0, 'DeclinedLoanReport__c not created');
    }
}
