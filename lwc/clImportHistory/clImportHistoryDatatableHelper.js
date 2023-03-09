export const dtHelper = {

    getFilesDtColumns() {
        const rowActions = [
            { label: 'Delete', name: 'delete' },
            { label: 'Preview', name: 'preview' }
        ];
        const columns = [
            // {
            //     label: 'Title', fieldName: 'fileTitle', wrapText: true,
            //     initialWidth: 400,
            //     cellAttributes: {
            //         iconName: {fieldName: 'icon'}, iconPosition: 'left'
            //     }
            // },
            {
                label: 'Title', fieldName: 'fileLinkName', type:'url', wrapText: true,
                initialWidth: 425,
                typeAttributes: {
                    label: { fieldName: 'fileTitle' }, target: '_parent'},
                cellAttributes: {
                    iconName: 'doctype:csv', iconPosition: 'left'
                }
            },
            {
                label: 'File Size', fieldName: 'fileSize',
                initialWidth: 100,
            },
            {
                label: 'Created By', fieldName: 'fileCreatedByName',
                cellAttributes: {
                    iconName: 'standard:user', iconPosition: 'left'
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