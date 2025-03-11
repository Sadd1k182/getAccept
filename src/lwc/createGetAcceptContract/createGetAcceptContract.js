import {LightningElement, api} from 'lwc';
import createAndSendContract from '@salesforce/apex/GetAcceptContractService.createAndSendContract';
import getAccessToken from '@salesforce/apex/GetAcceptAuthService.getAccessToken';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {TOAST_VARIANTS, ERROR_MESSAGES, SUCCESS_MESSAGES, BUTTON_LABELS} from 'c/utils';

export default class CreateGetAcceptContract extends LightningElement {
    @api recordId;
    isLoading = false;
    error = null;
    contractId = null;

    labels = {
        toastSuccess: TOAST_VARIANTS.SUCCESS,
        toastError: TOAST_VARIANTS.ERROR,
        createContractButton: BUTTON_LABELS.CREATE_CONTRACT,
        contractCreatedMessage: SUCCESS_MESSAGES.CONTRACT_CREATED,
        createContractErrorMessage: ERROR_MESSAGES.CREATE_CONTRACT,
        authErrorMessage: ERROR_MESSAGES.AUTH_ERROR,
    };

    async handleCreateContract() {
        this.isLoading = true;
        this.error = null;
        this.contractId = null;

        try {
            const accessToken = await this.getAuthenticatedToken();
            if (!accessToken) {
                return;
            }

            const contractId = await createAndSendContract({accessToken, opportunityId: this.recordId});
            this.contractId = contractId;
            this.showSuccessToast(this.labels.contractCreatedMessage, contractId);
        } catch (error) {
            this.handleContractError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async getAuthenticatedToken() {
        try {
            return await getAccessToken();
        } catch (error) {
            this.handleAuthError(error);
            return null;
        }
    }

    handleAuthError(error) {
        const message = error.body?.message || this.labels.authErrorMessage;
        this.showErrorToast(message);
        console.error('Authentication Error:', error);
    }

    handleContractError(error) {
        let message = this.labels.createContractErrorMessage;
        if (error.body && error.body.message) {
            message = error.body.message;
        }
        this.showErrorToast(message);
        console.error('Contract Creation Error:', error);
    }

    showSuccessToast(message, contractId) {
        this.showToast('Success', `${message}${contractId}`, this.labels.toastSuccess);
    }

    showErrorToast(message) {
        this.showToast('Error', message, this.labels.toastError);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({title, message, variant}));
    }
}