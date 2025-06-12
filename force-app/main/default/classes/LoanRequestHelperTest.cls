@isTest
private class LoanRequestHelperTest {

    private static Customer__c createCustomer() {
        Customer__c customer = new Customer__c(Name = 'Test Customer ' + System.currentTimeMillis());
        insert customer;
        return customer;
    }

    private static LoanRequest__c createLoan(Customer__c customer, Decimal amount, String status) {
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c   = customer.Id,
            LoanAmount__c = amount,
            LoanStatus__c = status,
            LoanDate__c   = Date.today()
        );
        insert loan;
        return loan;
    }

    @isTest
    static void testEnforcePendingStatus_WhenAmountHighAndStatusBlank() {
        LoanRequest__c loan = new LoanRequest__c(
            LoanAmount__c = 300000,
            LoanStatus__c = null
        );

        LoanRequestHelper.enforcePendingStatus(new List<LoanRequest__c>{ loan });

        System.assertEquals('Pending', loan.LoanStatus__c, 'Loan status should default to Pending');
    }

    @isTest
    static void testProcessLoanRequests_FullPathExecution() {
        Customer__c customer = createCustomer();

        LoanRequest__c approvedLoan = createLoan(customer, 500000, 'Approved');
        LoanRequest__c declinedLoan = createLoan(customer, 100000, 'Declined');

        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>{
            approvedLoan.Id => new LoanRequest__c(Id = approvedLoan.Id, LoanStatus__c = 'Pending'),
            declinedLoan.Id => new LoanRequest__c(Id = declinedLoan.Id, LoanStatus__c = 'Pending')
        };

        Test.startTest();
        LoanRequestHelper.processLoanRequests(
            new List<LoanRequest__c>{ approvedLoan, declinedLoan },
            oldMap
        );
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM LoanHistory__c WHERE Customer__c = :customer.Id], 'Expected 2 LoanHistory record');
        System.assertEquals(2, [SELECT COUNT() FROM DeclinedLoanReport__c WHERE LoanRequest__c = :declinedLoan.Id], 'Expected 2 DeclinedLoanReport');
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE WhatId = :approvedLoan.Id], 'Expected 2 Task');
        System.assertEquals(2, [SELECT COUNT() FROM AuditLog__c WHERE RelatedLoanRequest__c = :approvedLoan.Id], 'Expected 2 AuditLog');
    }

    @isTest
    static void testProcessLoanRequests_NoNewActivity() {
        Customer__c customer = createCustomer();

        LoanRequest__c neutralLoan = createLoan(customer, 100000, 'Approved');

        // Simulate that status hasn't changed
        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>{
            neutralLoan.Id => new LoanRequest__c(Id = neutralLoan.Id, LoanStatus__c = 'Approved')
        };

        Test.startTest();
        LoanRequestHelper.processLoanRequests(new List<LoanRequest__c>{ neutralLoan }, oldMap);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :neutralLoan.Id], 'Expected no Task');
        System.assertEquals(1, [SELECT COUNT() FROM LoanHistory__c WHERE Customer__c = :customer.Id], 'Expected LoanHistory');
        System.assertEquals(0, [SELECT COUNT() FROM DeclinedLoanReport__c WHERE LoanRequest__c = :neutralLoan.Id], 'Expected no DeclinedLoanReport');
        System.assertEquals(0, [SELECT COUNT() FROM AuditLog__c WHERE RelatedLoanRequest__c = :neutralLoan.Id], 'Expected no AuditLog');
    }

}



