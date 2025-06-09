public with sharing class LoanRequestController {

    @AuraEnabled
    public static LoanRequest__c createLoanRequest(String customerId, Decimal loanAmount, String loanStatus) {
        // Create a new LoanRequest__c record with the provided details
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customerId,  // Make sure this is a valid Account ID
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

        // Debugging the loan record to verify the results
        System.debug('Loan record after insert: ' + loan);

        return loan;
    }


    @AuraEnabled(cacheable=true)
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

    @AuraEnabled(cacheable=true)
    public static List<LoanHistory__c> getApprovedLoanRequests() {
        return [SELECT Id, Customer__r.Name, LoanAmount__c, LoanStatus__c, LoanDate__c FROM LoanHistory__c LIMIT 100];
    }

    @AuraEnabled(cacheable=true)
    public static List<LoanRequest__c> getAllLoanRequests() {
        return [
            SELECT Id, LoanAmount__c, LoanStatus__c, Customer__r.Name
            FROM LoanRequest__c
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

}
