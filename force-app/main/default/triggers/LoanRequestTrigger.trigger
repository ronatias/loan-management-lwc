trigger LoanRequestTrigger on LoanRequest__c (before insert, before update, after insert, after update) {
    
    //enforce pending status if status was not assigned + loanAmount > 2500000 (Ronen - consider to remove, handled this case in lwc side)
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
