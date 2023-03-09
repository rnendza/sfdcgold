import LightningAlert from "lightning/alert";
import LightningConfirm from 'lightning/confirm';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export const uiHelper = {

    async showAlert(message, theme, label) {
        await LightningAlert.open({
            message: message,
            theme: theme,
            label: label
        }).then(() => {
            console.log("###Alert Closed");
        });
    },
    async showConfirm(message, theme, label) {
        const result = LightningConfirm.open({
            message: message,
            theme: theme,
            label: label,
        });
        return result;
    },
    showToast(ref, title, msg, variant, mode) {
        const evt = new ShowToastEvent({title: title, message: msg, variant: variant, mode: mode});
        ref.dispatchEvent(evt);
    },
    /**
     *
     * @param mKey
     * @param values
     * @returns {*}
     */
    getMapValue(mKey, values) {
        let retValue;
        for (let key in values) {
            if (key === mKey) {
                retValue = values[key];
                break;
            }
        }
        return retValue;
    },
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return (
            errors
                // Remove null/undefined items
                .filter((error) => !!error)
                // Extract an error message
                .map((error) => {
                    // UI API read errors
                    if (Array.isArray(error.body)) {
                        return error.body.map((e) => e.message);
                    }
                    // UI API DML, Apex and network errors
                    if (error.body) {
                        let bodyMessage = [];
                        // top-level error. there can be only one
                        if (error.body.message) {
                            bodyMessage.push(error.body.message);
                        }
                        // page-level errors (validation rules, etc)
                        if (error.body.output.errors) {
                            error.body.output.errors.forEach(error => {
                                bodyMessage.push(error.message);
                            });
                        }
                        if (error.body.fieldErrors) {
                            // field specific errors--we'll say what the field is
                            Object.keys(error.body.fieldErrors).forEach(fieldName => {
                                // each field could have multiple errors
                                error.body.fieldErrors[fieldName].forEach(fieldError => {
                                    bodyMessage.push("Field Error on " + fieldName + " : " + fieldError.message);
                                });
                            });
                        }
                        if (bodyMessage.length > 0) {
                            return bodyMessage.join(" ");
                        }
                    }
                    // JS errors
                    if (typeof error.message === 'string') {
                        return error.message;
                    }
                    // Unknown error shape so try HTTP status text
                    return error.statusText;
                })
                // Flatten
                .reduce((prev, curr) => prev.concat(curr), [])
                // Remove empty strings
                .filter((message) => !!message)
                .join('\n')
        );
    }
}