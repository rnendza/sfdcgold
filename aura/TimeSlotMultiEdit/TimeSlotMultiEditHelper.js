({
    /**
     * initial config of data table.
     * @param cmp
     */
    initDatatableColumns: function (cmp) {
        //var actions = [];    {label: 'Clone', name: 'cloneRecord'},

        var actions = [
            {label: 'Edit', name: 'editRecord'},
            {label: 'Copy', name: 'cloneRecord'},
            {label: 'Delete', name: 'deleteRecord'}
        ];
        cmp.set('v.columns', [
            {label: 'Name', fieldName: 'name', type: 'text', sortable: true},
            {label: 'Day of Week', fieldName: 'dayOfWeek', sortable: true, type: 'text'},
            {
                label: 'Start Time',
                fieldName: 'startTime',
                type: 'date',
                sortable: true,
                typeAttributes: {hour: "2-digit", minute: "2-digit", timeZone: "UTC", hour12:true}
            },
            {
                label: 'End Time',
                fieldName: 'endTime',
                sortable: true,
                type: 'date',
                typeAttributes: {hour: "2-digit", minute: "2-digit", timeZone: "UTC", hour12:true}
            },
            {label: 'Type', fieldName: 'type', type: 'text'},
            {label: 'Last Modified', fieldName: 'lastModifiedDate', type: 'date-local', sortable: true},
            {label: 'Last Modified By', fieldName: 'lastModifiedByName', sortable: true, type: 'text'},
            {type: 'action', typeAttributes: {rowActions: actions}}
        ]);
    },
    /**
     *
     * @param cmp
     * @param row
     */
    deleteTimeSlot: function (cmp, row) {
        console.log('call delete for:'+row.timeSlotId);
        var self = this;
        cmp.set("v.showSpinner", true);
        var action = cmp.get('c.deleteTimeSlot');
        action.setParams({  "timeSlotId": row.timeSlotId});
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                if (dto.isSuccess) {
                    var rows = cmp.get('v.rawData');
                    var rowIndex = rows.indexOf(row);
                    rows.splice(rowIndex, 1);
                    cmp.set('v.data', rows);
                    cmp.set("v.showSpinner", false);
                    self.displayUiMsg(cmp, dto.severity, dto.message);
                } else {
                    cmp.set("v.showSpinner", false);
                    self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                self.log(cmp, '', 'error', errors);
                self.displayUiMsg(cmp, 'error', JSON.stringify(errors));
            }
        }));
        $A.enqueueAction(action);
    },
    /**
     *
     * @param cmp
     * @param row
     */
    doOpenCloneModal : function(cmp, row) {
        $A.createComponent("c:TimeSlotForm", { recordId : row.timeSlotId },
            function(content, status) {
                if (status === "SUCCESS") {
                    cmp.find('overlayLib').showCustomModal({
                        header: "Copy  Time Slot",
                        body: content,
                        showCloseButton: true,
                        cssClass: "slds-modal_small",
                    })
                }
            });
    },
    /**
     *
     * @param cmp
     */
    getTimeSlotData: function (cmp) {
        var self = this;
        cmp.set("v.showSpinner", true);
        var action = cmp.get('c.retrieveTimeSlotWraps');
        var collectionUtils = cmp.find('collectionUtils');
        var selectedSmId = cmp.get("v.selectedServiceMemberId");
        var selectedDayOfWeek = cmp.get('v.selectedDayOfWeek');
        var daysOfWeek = [];
        if(selectedDayOfWeek && selectedDayOfWeek != null) {
            daysOfWeek.push(selectedDayOfWeek);
        }
        action.setParams({  "serviceTerritoryId": cmp.get('v.selectedTerritoryId'),
                            "selectedSmId": selectedSmId,
                            "daysOfWeek" : daysOfWeek });

        self.log(cmp, 'Calling retrieveTimeSlotWraps with params ', 'debug', action.getParams());
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                var daysOfWeekSet = new Set(); //ES6
                var daysOfWeek = [];
                self.log(cmp, 'timeslot response dto', 'debug', dto);

                var timeSlots = [], serviceMembers = [];
                collectionUtils.getMapValue('SERVICE_MEMBERS', dto.values, function (value) {
                    serviceMembers = value;
                });
                collectionUtils.getMapValue('TIME_SLOTS', dto.values, function (value) {
                    timeSlots = value;
                    if(!cmp.get('v.showDaysOfWeekPl')) { // only do this once..
                        if (timeSlots && timeSlots.length > 0) {
                            cmp.set('v.showDaysOfWeekPl', true);
                            try {
                                timeSlots.forEach(function (timeSlot, index) {
                                    if (timeSlot.dayOfWeek && timeSlot.dayOfWeek != '') {
                                        daysOfWeekSet.add(timeSlot.dayOfWeek);
                                    }
                                });
                            } catch (e) {
                                self.log(cmp, 'error processing days of week', 'error', e.message);
                            }
                            var arrDaysOfWeek = Array.from(daysOfWeekSet);
                            var sorter = {
                                // "sunday": 0, // << if sunday is first day of week
                                "monday": 1,
                                "tuesday": 2,
                                "wednesday": 3,
                                "thursday": 4,
                                "friday": 5,
                                "saturday": 6,
                                "sunday": 7
                            }
                            arrDaysOfWeek.sort(function sortByDay(a, b) {
                                var day1 = a.toLowerCase();
                                var day2 = b.toLowerCase();
                                return sorter[day1] > sorter[day2];
                            });
                            cmp.set('v.daysOfWeek', arrDaysOfWeek);
                        }
                    }
                });

                cmp.set('v.data', timeSlots);
                cmp.set('v.rawData', timeSlots);
                cmp.set('v.serviceMembers', serviceMembers);
                try {
                    let smSelect = cmp.find("serviceMemberSelect");
                    if(smSelect && smSelect.isValid()) {
                        smSelect.set("v.selectedValue", cmp.get('v.selectedServiceMemberId'));
                    }
                   // cmp.find("serviceMemberSelect").set("v.selectedValue", cmp.get('v.selectedServiceMemberId'));
                } catch (e) {
                    self.log(cmp,'unabled to find serviceMemberSelect..','error',e);
                }
                cmp.set("v.showSpinner", false);

                if (!dto.isSuccess) {
                    self.log(cmp, 'timeslot retrieval failed.. ', 'error', dto);
                    self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                self.log(cmp, '', 'error', errors);
            }
        }));
        $A.enqueueAction(action);
    },
    /**
     *
     * @param cmp
     */
    getUserTerritories: function (cmp) {
        var self = this;
        var action = cmp.get('c.retrieveUserTerritories');
        var lAccelRoles = cmp.get('v.accelRoles');
        var collectionUtils = cmp.find('collectionUtils');
        action.setParams({"sAccelRoles": JSON.stringify(lAccelRoles)});
        cmp.set("v.showSpinner", true);
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                self.log(cmp, 'Success getting user territories', 'debug', response.getReturnValue());
                var dto = response.getReturnValue();
                if (dto.isSuccess) {
                    collectionUtils.getMapValue('TIME_EDIT_SETTINGS', dto.values, function (value) {
                        cmp.set('v.timeEditSettings', value);
                    });
                    cmp.set('v.debugConsole',true);
                    var bSingleTerritory = false;
                    var userTerritories = [];
                    collectionUtils.getMapValue('USER_TERRITORIES', dto.values, function (value) {
                        userTerritories = value;
                        cmp.set('v.userTerritories', userTerritories);
                        if (userTerritories && userTerritories.length === 1) {
                            bSingleTerritory = true;
                            cmp.set('v.showServiceMbrPl',true);
                            self.log(cmp, 'Single Territory only', 'debug');
                        }
                    });
                    var timeSlots = [];
                    var daysOfWeek = new Set(); //ES6
                    collectionUtils.getMapValue('TIME_SLOTS', dto.values, function (value) {
                        timeSlots = value;
                        cmp.set('v.data', timeSlots);
                        cmp.set('v.rawData', timeSlots);
                        if(timeSlots && timeSlots.length > 0) {
                            cmp.set('v.showDaysOfWeekPl',true);
                            try {
                                timeSlots.forEach(function (timeSlot, index) {
                                    if (timeSlot.dayOfWeek && timeSlot.dayOfWeek != '') {
                                        daysOfWeek.add(timeSlot.dayOfWeek);
                                    }
                                });
                            } catch (e) {
                                self.log(cmp, 'error processing days of week', 'error', e.message);
                            }
                          //  cmp.set('v.daysOfWeek',daysOfWeek);
                        }
                    });
                    if (bSingleTerritory) {
                        cmp.set('v.singleTerritory', true);
                        cmp.set('v.currentTerritory', userTerritories[0]);
                        cmp.set('v.selectedTerritoryId', userTerritories[0].FSL__ServiceTerritory__c);
                        this.getTimeSlotData(cmp);
                    } else {
                        cmp.set("v.showSpinner", false);
                    }
                } else {
                    cmp.set("v.showSpinner", false);
                    //-------  self.displayUiMsg(cmp, 'warning', dto.message);  don't prompt ui.. just write to console.
                    self.log(cmp, dto.message, dto.severity);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                self.log(cmp, '', 'error', errors);
                self.displayUiMsg(cmp, 'error', JSON.stringify(errors));
            }
        }));
        $A.enqueueAction(action);
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.data", data);
        cmp.set('v.rawData', data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function (x) {
                return primer(x[field])
            } :
            function (x) {
                return x[field]
            };
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    /**
     * Simply a wrapper around The Utils Component / log method.
     *
     * @param cmp
     * @param msg - the message to logn...
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
     */
    log: function (cmp, msg, level, jsonObj) {
        try {
            if (cmp.get("v.debugConsole") || level === 'error') {
                var cmpName = '--- TimeSlotMultiEdit ';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, level, msg, jsonObj);
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    }
})

// {
//     type: 'button',
//         typeAttributes: {
//     iconName: 'utility:edit',
//         label: 'Edit',
//         name: 'editRecord',
//         title: 'editTitle',
//         disabled: false,
//         value: 'test'
// }