@isTest
public class LoanRequestControllerTest {

    // Set up test data once for all tests: an account and a loan history
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        LoanHistory__c history1 = new LoanHistory__c(
            Customer__c = acc.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Approved',
            LoanDate__c = Date.today()
        );
        insert history1;
    }

    // This test checks if we can create a loan request for a real account,
    // and verifies that the data saved is correct
    @isTest
    static void testCreateLoanRequest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        LoanRequest__c result = LoanRequestController.createLoanRequest(
            acc.Id,
            150000,
            'Approved'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Loan was not created');
        System.assertEquals(acc.Id, result.Customer__c, 'Customer not matched');
        System.assertEquals(150000, result.LoanAmount__c, 'Amount not matched');
    }

    // This test verifies that getAccountIdByName works correctly
    // when given a real, existing account name
    @isTest
    static void testGetAccountIdByName_Found() {
        Test.startTest();
        Id accId = LoanRequestController.getAccountIdByName('Test Account');
        Test.stopTest();

        System.assertNotEquals(null, accId, 'Account ID should have been returned');
    }

    // This test makes sure that if you search for an account name that doesn't exist,
    // the method throws a handled exception instead of crashing
    @isTest
    static void testGetAccountIdByName_NotFound() {
        Test.startTest();
        Boolean isAuraHandledException = false;

        try {
            LoanRequestController.getAccountIdByName('DefinitelyDoesNotExist_' + System.currentTimeMillis());
        } catch (Exception e) {
            if (e instanceof AuraHandledException) {
                isAuraHandledException = true;
            }
        }

        Test.stopTest();
        System.assert(isAuraHandledException, 'Expected AuraHandledException was thrown');
    }

    // This test creates a loan and then checks that getAllLoanRequests
    // returns that loan as part of the results
    @isTest
    static void testGetAllLoanRequests() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = acc.Id,
            LoanAmount__c = 12345,
            LoanStatus__c = 'Approved',
            LoanDate__c = Date.today()
        );
        insert loan;

        Test.startTest();
        List<LoanRequest__c> results = LoanRequestController.getAllLoanRequests();
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Expected loan results');
        System.assertEquals(loan.Id, results[0].Id, 'Expected matching loan record');
    }
}
