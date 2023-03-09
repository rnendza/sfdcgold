export const dtHelper = {

    getFilesDtColumns() {
        const rowActions = [
            { label: 'Delete', name: 'delete' },
            { label: 'Preview', name: 'preview' },
            { label: 'Publish', name: 'publish' },
        ];
        const columns = [
            {
                label: 'Title', fieldName: 'fileLinkName', type:'url', wrapText: true,
                initialWidth: 300,
                typeAttributes: {
                    label: { fieldName: 'fileTitleTruncated' }, target: '_parent'},
                cellAttributes: {
                    iconName: 'doctype:csv', iconPosition: 'left',
                    class: 'slds-truncate_container_75'
                }
            },
            {
                label: 'Status', fieldName: 'fileUploadStatus', wrapText: true,
                initialWidth: 125,
                cellAttributes: { class: { fieldName: 'statusCssClass' } }
            },
            {
                label: 'File Size', fieldName: 'fileSize',
                initialWidth: 100,

            },
            // {
            //     label: 'Created By', fieldName: 'fileCreatedByName',
            //     cellAttributes: {
            //         iconName: 'standard:user', iconPosition: 'left'
            //     }
            // },
            {
                label: 'Created By', fieldName: 'fileCreatedByLinkName', type:'url', wrapText: true,
                typeAttributes: {
                    label: { fieldName: 'fileCreatedByName' }, target: '_blank'},
                cellAttributes: {
                    iconName: 'standard:user', iconPosition: 'left',
                }
            },


            {label: 'Created Date', fieldName: 'fileCreatedByDate',type: 'date',
                typeAttributes: {
                    day:'numeric',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true
                }
            },
            {
                type: 'action',
                typeAttributes: { rowActions: rowActions },
            },
        ];
        return columns;
    }
}