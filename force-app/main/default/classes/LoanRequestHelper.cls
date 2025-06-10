    public class LoanRequestHelper {
        //Ronen note - not sure if needed any more, this was my first approch but I added in the lwc case when loanAmount > 2500000
        //the status will be pending and the field will be disabled.
        public static void enforcePendingStatus(List<LoanRequest__c> loans) {
            if (
                 // Permission checks
                Schema.sObjectType.LoanRequest__c.fields.LoanAmount__c.isAccessible() &&
                Schema.sObjectType.LoanRequest__c.fields.LoanStatus__c.isAccessible() &&
                Schema.sObjectType.LoanRequest__c.fields.LoanStatus__c.isUpdateable()
            ) {
                for (LoanRequest__c loan : loans) {
                    if (loan.LoanAmount__c > 250000 && String.isBlank(loan.LoanStatus__c)) {
                        loan.LoanStatus__c = 'Pending';
                    }
                }
            } else {
                System.debug('FLS violation: user does not have access to required fields.');
            }
        }
    
        public static void processLoanRequests(List<LoanRequest__c> newList, Map<Id, LoanRequest__c> oldMap) {
            // FLS and CRUD permission checks
            Boolean canInsertTask     = Schema.sObjectType.Task.isCreateable();
            Boolean canInsertHistory  = Schema.sObjectType.LoanHistory__c.isCreateable();
            Boolean canInsertDecline  = Schema.sObjectType.DeclinedLoanReport__c.isCreateable();
            Boolean canReadCustomer   = Schema.sObjectType.Account.fields.Name.isAccessible();
            Boolean canReadAmount     = Schema.sObjectType.LoanRequest__c.fields.LoanAmount__c.isAccessible();
    
            List<Task> tasksToInsert = new List<Task>();
            List<LoanHistory__c> historiesToInsert = new List<LoanHistory__c>();
            List<DeclinedLoanReport__c> declinesToInsert = new List<DeclinedLoanReport__c>();
    
            //Collect customer IDs
            Set<Id> customerIds = new Set<Id>();
            for (LoanRequest__c loan : newList) {
                if (loan.Customer__c != null) {
                    customerIds.add(loan.Customer__c);
                }
            }
    
            //Query customer names
            Map<Id, Account> accountMap = new Map<Id, Account>();
            if (canReadCustomer && !customerIds.isEmpty()) {
                accountMap = new Map<Id, Account>(
                    [SELECT Id, Name FROM Account WHERE Id IN :customerIds]
                );
            }
    
            //Loop through new loan requests
            for (LoanRequest__c loan : newList) {
                String oldStatus = oldMap != null && oldMap.containsKey(loan.Id)
                    ? oldMap.get(loan.Id).LoanStatus__c
                    : null;
    
                // Create task if amount is high
                if (canReadAmount && loan.LoanAmount__c > 250000 && canInsertTask) {
                    String customerName = accountMap.containsKey(loan.Customer__c)
                        ? accountMap.get(loan.Customer__c).Name
                        : 'Unknown';
    
                    tasksToInsert.add(buildHighValueTask(loan, customerName));
                }
    
                // Create history if status is "Approved"
                if (canInsertHistory && loan.LoanStatus__c == 'Approved' && oldStatus != 'Approved') {
                    historiesToInsert.add(buildLoanHistoryRecord(loan));
                }
    
                // Create decline report if status is "Declined"
                if (canInsertDecline && loan.LoanStatus__c == 'Declined' && oldStatus != 'Declined') {
                    declinesToInsert.add(buildDeclinedReport(loan));
                }
            }
    
            //Insert records in bulk (outside loop)
            if (!tasksToInsert.isEmpty()) insert tasksToInsert;
            if (!historiesToInsert.isEmpty()) insert historiesToInsert;
            if (!declinesToInsert.isEmpty()) upsert declinesToInsert;
        }    
        
        //Create new task
        private static Task buildHighValueTask(LoanRequest__c loan, String customerName) {
            return new Task(
                Subject      = 'Review High-Value Loan',
                WhatId       = loan.Id,
                Status       = 'Not Started',
                Priority     = 'High',
                Description  = 'Customer: ' + customerName +
                               ', Amount: ' + loan.LoanAmount__c,
                ActivityDate = loan.LoanDate__c
            );
        }
        
        //build LoanHistory__c item
        private static LoanHistory__c buildLoanHistoryRecord(LoanRequest__c loan) {
            return new LoanHistory__c(
                Customer__c   = loan.Customer__c,
                LoanAmount__c = loan.LoanAmount__c,
                LoanStatus__c = loan.LoanStatus__c,
                LoanDate__c   = loan.LoanDate__c
            );
        }
        
        //build DeclinedLoanReport__c item
        private static DeclinedLoanReport__c buildDeclinedReport(LoanRequest__c loan) {
            return new DeclinedLoanReport__c(
                LoanRequest__c = loan.Id,
                Reason__c      = 'Status changed to Declined',
                LoanAmount__c  = loan.LoanAmount__c
            );
        }
    }
    
