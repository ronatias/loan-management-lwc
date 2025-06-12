import { LightningElement, track, wire } from 'lwc';
import getAccountIdByName from '@salesforce/apex/LoanRequestController.getAccountIdByName';
import createLoanRequest from '@salesforce/apex/LoanRequestController.createLoanRequest';
import { publish, MessageContext } from 'lightning/messageService';
import LOAN_MESSAGE_CHANNEL from '@salesforce/messageChannel/LoanMessageChannel__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class LoanForm extends LightningElement {
    @track customerName = '';
    @track loanAmount = null;
    @track isLoading = false;
    @track message = '';
    @track isStatusDisabled = false;
    @track loanStatus = 'Pending'; 

    @track loanStatusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Declined', value: 'Declined' }
    ];

    //for LMS 
    @wire(MessageContext)
    messageContext;

    //handler for lightning-input (customerName, loanAmount)
    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value; //set value according field name
        //
        if (name === 'loanAmount') {
            const amount = parseFloat(value);
            if (!isNaN(amount) && amount > 250000) {
                this.loanStatus = 'Pending';
                this.isStatusDisabled = true; //Block the user to change the status, loan request needs to be approved by manager.
            } else {
                this.isStatusDisabled = false;
            }
        }
    }

    handleSave() {
        this.isLoading = true; //trigger spinner
        this.message = '';

        const amount = parseFloat(this.loanAmount);
        //Validation to loanAmount value
        if (isNaN(amount) || amount <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Loan amount must be greater than 0.',
                    variant: 'error'
                })
            );
            this.isLoading = false; //close spinner
            return;
        }
        
        getAccountIdByName({ customerName: this.customerName }) //Check if account name is valid if yes trigger createLoanRequest
            .then(accountId => {
                return createLoanRequest({
                    customerId: accountId,
                    loanAmount: parseFloat(this.loanAmount),
                    loanStatus: this.loanStatus
                });
            })
            .then(result => {
                //reset values + Success toast
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
                //send message using channel LoanMessageChannel__c to expose loanRequest values (no common parent)
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
                // Loan creation fail toast
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
                this.isLoading = false; //end spinner handleSave
            });
    }
}
