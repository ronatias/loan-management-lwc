@isTest
public class LoanRequestControllerTest {

    // Set up shared test data once — runs before all test methods
    @testSetup
    static void setupTestData() {
        // Create a test customer record
        Customer__c customer = new Customer__c(Name = 'Test Customer');
        insert customer;

        // Create a loan history record
        LoanHistory__c history = new LoanHistory__c(
            Customer__c = customer.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Approved',
            LoanDate__c = Date.today()
        );
        insert history;
    }

    // Test method to verify successful loan creation
    @isTest
    static void testCreateLoanRequest() {
        // Query test customer created in @testSetup
        Customer__c customer = [SELECT Id FROM Customer__c WHERE Name = 'Test Customer' LIMIT 1];

        // Call the controller method and validate the created record
        Test.startTest();
        LoanRequest__c result = LoanRequestController.createLoanRequest(
            customer.Id,
            150000,
            'Approved'
        );
        Test.stopTest();

        // Assert the loan was created with correct details
        System.assertNotEquals(null, result, 'Loan should have been created');
        System.assertEquals(customer.Id, result.Customer__c, 'Customer ID mismatch');
        System.assertEquals(150000, result.LoanAmount__c, 'Loan amount mismatch');
    }

    // Test method to verify getAccountIdByName returns the correct ID
    @isTest
    static void testGetAccountIdByName_Found() {
        Test.startTest();
        Id customerId = LoanRequestController.getAccountIdByName('Test Customer');
        Test.stopTest();

        System.assertNotEquals(null, customerId, 'Expected to get Customer ID');
    }

    // Test method to verify exception is thrown if customer name not found
    @isTest
    static void testGetAccountIdByName_NotFound() {
        Boolean caughtException = false;

        Test.startTest();
        try {
            LoanRequestController.getAccountIdByName('NonExistentCustomer_' + System.currentTimeMillis());
        } catch (Exception e) {
            // Check that the exception is a handled AuraHandledException
            if (e instanceof AuraHandledException) {
                caughtException = true;
            }
        }
        Test.stopTest();

        System.assert(caughtException, 'Expected AuraHandledException for unknown customer name');
    }

    // Test that getAllLoanRequests returns recent loan records correctly
    @isTest
    static void testGetAllLoanRequests() {
        // Create another customer and loan record
        Customer__c customer = new Customer__c(Name = 'Another Customer');
        insert customer;

        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customer.Id,
            LoanAmount__c = 25000,
            LoanStatus__c = 'Pending',
            LoanDate__c = Date.today()
        );
        insert loan;

        Test.startTest();
        List<LoanRequest__c> results = LoanRequestController.getAllLoanRequests();
        Test.stopTest();

        // Assert that at least one result exists and contains the expected record
        System.assert(!results.isEmpty(), 'Loan list should not be empty');
        System.assertEquals(loan.Id, results[0].Id, 'Expected latest loan to match');
    }

    @isTest
    static void testCreateLoanRequest_Exception() {
    Boolean didThrow = false;

    // Use invalid customerId to cause a failure
    String invalidCustomerId = '001000000000000'; // Not a real Customer__c Id

    Test.startTest();
    try {
        LoanRequestController.createLoanRequest(
            invalidCustomerId, // wrong object prefix
            100000,
            'Approved'
        );
    } catch (Exception e) {
        // Expecting AuraHandledException from the controller
        didThrow = e instanceof AuraHandledException;
    }
    Test.stopTest();

    System.assert(didThrow, 'Expected AuraHandledException to be thrown for invalid Customer ID');
}

}
