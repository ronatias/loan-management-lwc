import { LightningElement, track, wire } from 'lwc';
import getAccountIdByName from '@salesforce/apex/LoanRequestController.getAccountIdByName';
import createLoanRequest from '@salesforce/apex/LoanRequestController.createLoanRequest';
import { publish, MessageContext } from 'lightning/messageService';
import LOAN_MESSAGE_CHANNEL from '@salesforce/messageChannel/LoanMessageChannel__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class LoanForm extends LightningElement {
    @track customerName = '';
    @track loanAmount = null;
    @track loanStatus = '';
    @track isLoading = false;
    @track message = '';
    @track isStatusDisabled = false;
    @track loanStatus = 'Pending'; 

    @track loanStatusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Declined', value: 'Declined' }
    ];

    @wire(MessageContext)
    messageContext;

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;

        if (name === 'loanAmount') {
            const amount = parseFloat(value);
            if (!isNaN(amount) && amount > 250000) {
                this.loanStatus = 'Pending';
                this.isStatusDisabled = true;
            } else {
                this.isStatusDisabled = false;
            }
        }
    }

    handleSave() {
        this.isLoading = true;
        this.message = '';

        const amount = parseFloat(this.loanAmount);
        if (isNaN(amount) || amount <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Loan amount must be greater than 0.',
                    variant: 'error'
                })
            );
            this.isLoading = false;
            return;
        }

        getAccountIdByName({ accountName: this.customerName })
            .then(accountId => {
                return createLoanRequest({
                    customerId: accountId,
                    loanAmount: parseFloat(this.loanAmount),
                    loanStatus: this.loanStatus
                });
            })
            .then(result => {
                this.customerName = '';
                this.loanAmount = null;
                this.loanStatus = '';
                this.isStatusDisabled = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Loan created with Id: ' + result.Id + ', Status: ' + result.LoanStatus__c,
                        variant: 'success'
                    })
                );

                publish(this.messageContext, LOAN_MESSAGE_CHANNEL, {
                    loan: {
                        Id: result.Id,
                        Customer__r: { Name: result.Customer__r.Name },
                        LoanAmount__c: result.LoanAmount__c,
                        LoanStatus__c: result.LoanStatus__c
                    }
                });
                
            })
            .catch(error => {
                // ❌ Show error toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating loan',
                        message: error.body?.message || error.message,
                        variant: 'error'
                    })
                );
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}

/* working version
import { LightningElement, track, wire } from 'lwc';
import getAccountIdByName from '@salesforce/apex/LoanRequestController.getAccountIdByName';
import createLoanRequest from '@salesforce/apex/LoanRequestController.createLoanRequest';
import { publish, MessageContext } from 'lightning/messageService';
import LOAN_MESSAGE_CHANNEL from '@salesforce/messageChannel/LoanMessageChannel__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class LoanForm extends LightningElement {
    @track customerName = '';
    @track loanAmount = null;
    @track loanStatus = '';
    @track isLoading = false;
    @track message = '';
    @track isStatusDisabled = false;

    @track loanStatusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Declined', value: 'Declined' }
    ];

    @wire(MessageContext)
    messageContext;

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;

        if (name === 'loanAmount') {
            const amount = parseFloat(value);
            if (!isNaN(amount) && amount > 250000) {
                this.loanStatus = 'Pending';
                this.isStatusDisabled = true;
            } else {
                this.isStatusDisabled = false;
            }
        }
    }

    handleSave() {
        this.isLoading = true;
        this.message = '';

        getAccountIdByName({ accountName: this.customerName })
            .then(accountId => {
                return createLoanRequest({
                    customerId: accountId,
                    loanAmount: parseFloat(this.loanAmount),
                    loanStatus: this.loanStatus
                });
            })
            .then(result => {
                this.customerName = '';
                this.loanAmount = null;
                this.loanStatus = '';
                this.isStatusDisabled = false;

                this.message = 'Loan created with Id: ' + result.Id + ', Status: ' + result.LoanStatus__c;

                publish(this.messageContext, LOAN_MESSAGE_CHANNEL, {
                    loan: {
                        Id: result.Id,
                        Customer__r: { Name: result.Customer__r.Name },
                        LoanAmount__c: result.LoanAmount__c,
                        LoanStatus__c: result.LoanStatus__c
                    }
                });
                
            })
            .catch(error => {
                this.message = 'Error: ' + (error.body?.message || error.message);
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
    */
