
   /*  This is the stable working version
    public class LoanRequestHelper {

        public static void processLoanRequests(List<LoanRequest__c> newList, Map<Id, LoanRequest__c> oldMap) {
            List<Task> tasksToInsert = new List<Task>();
            List<LoanHistory__c> historiesToInsert = new List<LoanHistory__c>();
            List<DeclinedLoanReport__c> declinesToUpdate = new List<DeclinedLoanReport__c>();

            for (LoanRequest__c loan : newList) {
                if (loan.LoanAmount__c > 250000) {
                    Task t = new Task(
                        Subject = 'Review High-Value Loan',
                        WhatId = loan.Id,
                        Status = 'Not Started',
                        Priority = 'High',
                        Description = 'Customer: ' + loan.Customer__r.Name + ', Amount: ' + loan.LoanAmount__c,
                        ActivityDate = loan.LoanDate__c
                    );
                    tasksToInsert.add(t);
                }

                String oldStatus = oldMap != null && oldMap.containsKey(loan.Id) ? oldMap.get(loan.Id).LoanStatus__c : null;

                if (loan.LoanStatus__c == 'Approved' && oldStatus != 'Approved') {
                    historiesToInsert.add(new LoanHistory__c(
                        Customer__c = loan.Customer__c,
                        LoanAmount__c = loan.LoanAmount__c,
                        LoanStatus__c = loan.LoanStatus__c,
                        LoanDate__c = loan.LoanDate__c
                    ));
                }

                if (loan.LoanStatus__c == 'Declined' && oldStatus != 'Declined') {
                    declinesToUpdate.add(new DeclinedLoanReport__c(
                        LoanRequest__c = loan.Id,
                        Reason__c = 'Status changed to Declined',
                        LoanAmount__c = loan.LoanAmount__c
                    ));
                }
            }

            if (!tasksToInsert.isEmpty()) insert tasksToInsert;
            if (!historiesToInsert.isEmpty()) insert historiesToInsert;
            if (!declinesToUpdate.isEmpty()) upsert declinesToUpdate;
        }
    }

    */

    public class LoanRequestHelper {

        // Enforce pending status on high-value loans if no status was set
        public static void enforcePendingStatus(List<LoanRequest__c> loans) {
            if (
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
            // Permission checks
            Boolean canInsertTask     = Schema.sObjectType.Task.isCreateable();
            Boolean canInsertHistory  = Schema.sObjectType.LoanHistory__c.isCreateable();
            Boolean canInsertDecline  = Schema.sObjectType.DeclinedLoanReport__c.isCreateable();
    
            Boolean canReadCustomer   = Schema.sObjectType.Account.fields.Name.isAccessible();
            Boolean canReadStatus     = Schema.sObjectType.LoanRequest__c.fields.LoanStatus__c.isAccessible();
            Boolean canReadAmount     = Schema.sObjectType.LoanRequest__c.fields.LoanAmount__c.isAccessible();
            Boolean canReadDate       = Schema.sObjectType.LoanRequest__c.fields.LoanDate__c.isAccessible();
    
            List<Task> tasksToInsert = new List<Task>();
            List<LoanHistory__c> historiesToInsert = new List<LoanHistory__c>();
            List<DeclinedLoanReport__c> declinesToInsert = new List<DeclinedLoanReport__c>();
    
            for (LoanRequest__c loan : newList) {
                String oldStatus = oldMap != null && oldMap.containsKey(loan.Id) ? oldMap.get(loan.Id).LoanStatus__c : null;
    
                if (canReadAmount && loan.LoanAmount__c > 250000 && canInsertTask) {
                    tasksToInsert.add(buildHighValueTask(loan, canReadCustomer));
                }
    
                if (canInsertHistory && loan.LoanStatus__c == 'Approved' && oldStatus != 'Approved') {
                    historiesToInsert.add(buildLoanHistoryRecord(loan));
                }
    
                if (canInsertDecline && loan.LoanStatus__c == 'Declined' && oldStatus != 'Declined') {
                    declinesToInsert.add(buildDeclinedReport(loan));
                }
            }
    
            if (!tasksToInsert.isEmpty()) insert tasksToInsert;
            if (!historiesToInsert.isEmpty()) insert historiesToInsert;
            if (!declinesToInsert.isEmpty()) upsert declinesToInsert;
        }
    
        private static Task buildHighValueTask(LoanRequest__c loan, Boolean canReadCustomer) {
            return new Task(
                Subject      = 'Review High-Value Loan',
                WhatId       = loan.Id,
                Status       = 'Not Started',
                Priority     = 'High',
                Description  = 'Customer: ' + (canReadCustomer && loan.Customer__r != null ? loan.Customer__r.Name : 'Unknown') +
                               ', Amount: ' + loan.LoanAmount__c,
                ActivityDate = loan.LoanDate__c
            );
        }
    
        private static LoanHistory__c buildLoanHistoryRecord(LoanRequest__c loan) {
            return new LoanHistory__c(
                Customer__c   = loan.Customer__c,
                LoanAmount__c = loan.LoanAmount__c,
                LoanStatus__c = loan.LoanStatus__c,
                LoanDate__c   = loan.LoanDate__c
            );
        }
    
        private static DeclinedLoanReport__c buildDeclinedReport(LoanRequest__c loan) {
            return new DeclinedLoanReport__c(
                LoanRequest__c = loan.Id,
                Reason__c      = 'Status changed to Declined',
                LoanAmount__c  = loan.LoanAmount__c
            );
        }
    }
    
