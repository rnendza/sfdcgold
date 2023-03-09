export const dtHelper = {
    getPreUploadDtColumns() {
        let columns = [
            {
                label: 'Row #',
                fieldName: 'rowNumber',
                hideDefaultActions: true,
                sortable: true,
                initialWidth: 90,
                cellAttributes: { class: { fieldName: 'rowNumCssClass' } }
            },
            {
                label: 'Route Name',
                fieldName: 'routeName',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Account Id',
                fieldName: 'accountId',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Collection Type',
                fieldName: 'collectionType',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Stop #',
                fieldName: 'stopNumber',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 1 Fill Level',
                fieldName: 'x1FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 5 Fill Level',
                fieldName: 'x5FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 20 Fill Level',
                fieldName: 'x20FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 50 Fill Level',
                fieldName: 'x50FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 100 Fill Level',
                fieldName: 'x100FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Replenishment Type',
                fieldName: 'replenishmentType',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Valid',
                fieldName: 'valid',
                hideDefaultActions: true,
                type: "boolean",

                cellAttributes: {
                    class: {
                        fieldName: 'validCSSClass'
                    },
                    // iconName: 'utility:question'
                }
            },
        ];
        return columns
    },
    getPreUploadErrorsDtColumns() {
        let columns = [
            {
                label: 'Row #',
                fieldName: 'rowNumber',
                hideDefaultActions: true,
                sortable: true,
                initialWidth: 90,
                cellAttributes: { class: { fieldName: 'rowNumCssClass' } }
            },
            {
                label: 'Error Message',
                fieldName: 'message',
                hideDefaultActions: true,
                initialWidth: 300,
                sortable: true
            },
            {
                label: 'Route Name',
                fieldName: 'routeName',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Account Id',
                fieldName: 'accountId',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Collection Type',
                fieldName: 'collectionType',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Stop #',
                fieldName: 'stopNumber',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 1 Fill Level',
                fieldName: 'x1FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 5 Fill Level',
                fieldName: 'x5FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 20 Fill Level',
                fieldName: 'x20FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 50 Fill Level',
                fieldName: 'x50FillLevel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'X 100 Fill Level',
                fieldName: 'x100FillLevel',
                hideDefaultActions: true,
                sortable: true
            }
        ];
        return columns
    },
}