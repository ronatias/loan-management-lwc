public with sharing class LoanRequestController {

    @AuraEnabled
    public static LoanRequest__c createLoanRequest(String customerId, Decimal loanAmount, String loanStatus) {
        try {
            LoanRequest__c loan = new LoanRequest__c(
                Customer__c = customerId,
                LoanAmount__c = loanAmount,
                LoanStatus__c = loanStatus,
                LoanDate__c = Date.today()
            );
    
            insert loan;
    
            loan = [
                SELECT Id, LoanAmount__c, LoanDate__c, LoanStatus__c, Customer__c, Customer__r.Name
                FROM LoanRequest__c
                WHERE Id = :loan.Id
                LIMIT 1
            ];
    
            return loan;
        } catch (Exception e) {
            // Turn system exception into a user-friendly AuraHandledException
            throw new AuraHandledException('Loan creation failed: ' + e.getMessage());
        }
    }

    @AuraEnabled // Get Customer object or raise error toast
    public static Id getAccountIdByName(String customerName) {
    System.debug('Input: ' + customerName);
    List<Customer__c> customers = [
        SELECT Id FROM Customer__c WHERE Name = :customerName LIMIT 1
    ];
    System.debug('Customer count: ' + customers.size());
    if (!customers.isEmpty()) {
        return customers[0].Id;
    } else {
        throw new AuraHandledException('Customer not found with name: ' + customerName);
    }
    }

    @AuraEnabled// get loans from LoanRequest__c - removed (cacheable=true) casued bug in list rendreing  
    public static List<LoanRequest__c> getAllLoanRequests() {
        return [
            SELECT Id, LoanAmount__c, LoanStatus__c, Customer__r.Name
            FROM LoanRequest__c
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

}
