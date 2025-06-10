public with sharing class LoanRequestController {

    @AuraEnabled
    public static LoanRequest__c createLoanRequest(String customerId, Decimal loanAmount, String loanStatus) {
        // Create a new LoanRequest__c record with the provided details
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customerId,
            LoanAmount__c = loanAmount,
            LoanStatus__c = loanStatus,
            LoanDate__c = Date.today()
        );

        // Insert the loan request record
        insert loan;
        
        // After inserting, retrieve the loan request and include the related Account's name (Customer__r.Name)
        loan = [
            SELECT Id, LoanAmount__c, LoanDate__c, LoanStatus__c, Customer__c, Customer__r.Name
            FROM LoanRequest__c
            WHERE Id = :loan.Id
            LIMIT 1
        ];

        return loan;
    }

    @AuraEnabled(cacheable=true) //Get Account object is not find raise error toast
    public static Id getAccountIdByName(String accountName) {
        List<Account> accounts = [
            SELECT Id FROM Account WHERE Name = :accountName LIMIT 1
        ];
        if (!accounts.isEmpty()) {
            return accounts[0].Id;
        } else {
            throw new AuraHandledException('Account not found with name: ' + accountName);
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
