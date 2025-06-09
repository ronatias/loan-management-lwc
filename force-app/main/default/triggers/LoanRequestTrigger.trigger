
trigger LoanRequestTrigger on LoanRequest__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LoanRequestHelper.enforcePendingStatus(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            LoanRequestHelper.processLoanRequests(Trigger.new, Trigger.oldMap);
        }
    }
}
