@isTest
public class LoanRequestControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Insert some approved and declined loan histories
        LoanHistory__c history1 = new LoanHistory__c(
            Customer__c = acc.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Approved',
            LoanDate__c = Date.today()
        );
        insert history1;
    }

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

        System.assertNotEquals(null, result);
        System.assertEquals(acc.Id, result.Customer__c);
        System.assertEquals(150000, result.LoanAmount__c);
    }

    @isTest
    static void testGetAccountIdByName_Found() {
        Test.startTest();
        Id accId = LoanRequestController.getAccountIdByName('Test Account');
        Test.stopTest();

        System.assertNotEquals(null, accId);
    }

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
        System.assert(isAuraHandledException, 'Expected AuraHandledException was not thrown');
    }



    @isTest
    static void testGetApprovedLoanRequests() {
        Test.startTest();
        List<LoanHistory__c> approvedLoans = LoanRequestController.getApprovedLoanRequests();
        Test.stopTest();

        System.assert(!approvedLoans.isEmpty(), 'Should return approved loan history records');
        System.assertEquals('Approved', approvedLoans[0].LoanStatus__c);
    }

    @isTest
    static void testGetAllLoanRequests() {
        // Create mock Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create mock LoanRequest
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
