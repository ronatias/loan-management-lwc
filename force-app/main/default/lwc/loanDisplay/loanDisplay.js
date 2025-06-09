import { LightningElement, track, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import LOAN_MESSAGE_CHANNEL from '@salesforce/messageChannel/LoanMessageChannel__c';
import getAllLoanRequests from '@salesforce/apex/LoanRequestController.getAllLoanRequests';

export default class LoanDisplay extends LightningElement {
    @track loans = [];

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadLoans();
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        subscribe(this.messageContext, LOAN_MESSAGE_CHANNEL, (message) => {
            if (message.loan) {
                // Prepend the actual loan from message
                this.loans = [message.loan, ...this.loans];
            }
        });
    }

    loadLoans() {
        getAllLoanRequests()
            .then(result => {
                this.loans = result;
            })
            .catch(error => {
                console.error('Error loading loans:', error);
            });
    }
}
