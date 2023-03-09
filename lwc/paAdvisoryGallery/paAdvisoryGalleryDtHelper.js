export const dtHelper = {
    getUserColumns() {
        let columns = [
            {
                label: 'Name', fieldName: 'userName', sortable: true,
                iconName: 'standard:user',
                tooltip: {
                    fieldName: 'userName'
                }
            },
            {
                label: 'Advisory #', fieldName: 'advisoryNumber', sortable: true,
                tooltip: {
                    fieldName: 'advisoryNumber'
                },
                iconName: "standard:number_input",
                initialWidth: 135,
            },
            {
                label: 'Advisory Type', fieldName: 'advisoryType', sortable: true,
                tooltip: {
                    fieldName: 'advisoryType'
                },
                iconName: "standard:number_input",
                initialWidth: 165,
            },
            {
                label: 'Advisory Dt', fieldName: 'advisoryDate', sortable: true,
                initialWidth: 135,
                hideDefaultActions: true,
                iconName: "standard:event",
                tooltip: {
                    fieldName: 'advisoryDate'
                },
                type: 'date-local',
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                },
            },
            {
                label: 'Mobile Phone', fieldName: 'userCellPhone', sortable: true, type: 'phone',
                initialWidth: 135,
                hideDefaultActions: true,
                iconName: 'custom:custom22',
                tooltip: {
                    fieldName: 'userCellPhone'
                }
            }
        ];
        return columns
    },
    getUserDtClasses() {
        const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered';
        return classes;
    },
    sortData(fieldname, direction,dtData) {
        // console.log('sort by ',fieldname);
        // console.log('sort dir ',direction);
        // Return the value stored in the field
        let parseData = [...dtData];

        try {
            let keyValue = (a) => {
                return a[fieldname];
            };
            // cheking reverse direction
            let isReverse = direction === 'asc' ? 1 : -1;
            // sorting data
            parseData.sort((x, y) => {
                x = keyValue(x) ? keyValue(x) : ''; // handling null values
                x = x.toLowerCase();
                y = keyValue(y) ? keyValue(y) : '';
                y = y.toLowerCase();
                // sorting values based on direction
                return isReverse * ((x > y) - (y > x));
            });
        } catch (e) {
            console.error('sorting exception',e);
        }
        return parseData;
    }
}