import { LightningElement, track, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import LOAN_MESSAGE_CHANNEL from '@salesforce/messageChannel/LoanMessageChannel__c';
import getAllLoanRequests from '@salesforce/apex/LoanRequestController.getAllLoanRequests';

export default class LoanDisplay extends LightningElement {
    @track loans = [];
    @track isLoading = true;

    //for LMS
    @wire(MessageContext)
    messageContext;

    
    connectedCallback() {
        this.loadLoans(); //fetch all current loans from LoanRequest__c
        this.subscribeToMessageChannel(); // listener for new loan messages
        document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));  
    }


    subscribeToMessageChannel() {
        subscribe(this.messageContext, LOAN_MESSAGE_CHANNEL, (message) => {
            if (message.loan) {                 
                this.loans = [message.loan, ...this.loans.filter(loanItem => loanItem.Id !== message.loan.Id)];
                // Ronen note:
                // Using local state update for performance (no spinner on LMS event).
                // If loan list gets out of sync (e.g., after navigating away and back), enable loadLoans() instead.
                //this.loadLoans();
            }
        });
    }

    //listner to catch visibility change
    handleVisibilityChange() {
        if (document.visibilityState === 'visible') {
            this.loadLoans();
        }
    }
    
    //build loans list
    loadLoans() {
        this.isLoading = true;
        getAllLoanRequests()
            .then(result => {
                this.loans = result;
            })
            .catch(error => {
                console.error('Error loading loans:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
