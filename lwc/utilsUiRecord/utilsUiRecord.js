/**
 * Returns the object's master record type id
 * @param {Object} objectInfo Object metadata
 */
export function getMasterRecordTypeId(objectInfo) {
    if (objectInfo.recordTypeInfos) {
        for (let rtId in objectInfo.recordTypeInfos) {
            if (objectInfo.recordTypeInfos[rtId].master) {
                return objectInfo.recordTypeInfos[rtId].recordTypeId;
            }
        }
    }
    return null;
}
/**
 * Returns the specific field object if found in objectInfo
 * @param {Object} objectInfo Object metadata
 * @param {String} fieldApiName The api name of the field.
 * @see https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_responses_field.htm#
 */
export function getSpecificField(objectInfo,fieldApiName) {
    if (objectInfo.fields) {
        if(objectInfo.fields[fieldApiName]) {
            return objectInfo.fields[fieldApiName];
        }
    }
    return null;
}
/**
 * Returns the record's record type id
 * @param {Object} record SObject record
 */
export function getRecordTypeId(record) {
    if (record.recordTypeInfo) {
        return record.recordTypeInfo.recordTypeId;
    }
    return null;
}