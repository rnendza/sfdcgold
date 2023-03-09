({
    MAP_KEY_PROGRESS_INDICATORS      :  'MAP_KEY_PROGRESS_INDICATORS',
    MAP_KEY_PARENT_STATUS_IND        : 'MAP_KEY_PARENT_STATUS_IND',
    collectionUtils:null, loggingUtils:null,
    /**
     * Retrieves the Inventory_Request_Progress_Indicators__mdt custom metadata which will be wrapped in a List
     * of custom ProgressIndicator classes.
     *
     * @param cmp
     * @see ProgressIndicator
     */
    retrieveIrProgressIndicators: function(cmp) {
        const action = 'c.retrieveIrProgressIndicators';
        const params = {inventoryRequestId : cmp.get('v.recordId')};
        this.log(cmp,'calling retrieveIrProgressIndicators','debug','params:'+JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                if(response) {
                    let dto = response;
                    this.log(cmp, 'cb of retrieveIrProgressIndicators: ','debug',dto);
                    if(dto.isSuccess) {
                        let progressWraps = this.collectionUtils.getData(this.MAP_KEY_PROGRESS_INDICATORS, dto.values);
                        let parentStatusInd = this.collectionUtils.getData(this.MAP_KEY_PARENT_STATUS_IND, dto.values);
                        this.log(cmp,'parent status ind','info',JSON.stringify(parentStatusInd));
                        let oldParentStatusInd = cmp.get('v.parentStatusIndicator');
                        if(parentStatusInd && parentStatusInd.isLocked && oldParentStatusInd && !oldParentStatusInd.isLocked) {
                            cmp.set('v.hideLockedPill',false);
                        }
                        cmp.set('v.parentStatusIndicator',parentStatusInd);
                        if(progressWraps && Array.isArray(progressWraps)) {
                            cmp.set('v.totalNbrOfSteps',progressWraps.length);
                        }
                        cmp.set('v.progressIndicators',progressWraps);
                        // if LDS Record was cached we must do this here as that call will return faster then this one.
                        this.flagCurrentProgressIndicator(cmp);
                    } else {
                        let msg = dto.message;
                        let type = 'error';
                        this.log(cmp, dto.technicalMsg,'error',dto);
                        this.displayUiMsg(cmp,type,msg);
                    }
                }
            })
            .catch(errors => {
                this.handleInitErrors(cmp,errors);
            });
    },
    /**
     * Basically we are deciding which progress indicator object in the list to flag as completed based on the results
     * of flagCurrentProgressIndicator. The assumes the array is in order and linear!
     *
     * 1. Find the element in the array flagged as completed.
     * 2. Find all earlier elements in the array based on the order property and filter to another array.
     * 3. Flag all found in #2 as completed.
     * 4. Modify the original array. ie attribute v.progressIndicators to reflect these changes.
     *
     * @param cmp
     * @param progressIndicators - A List of ProgressIndicator ie
     *                          [ { value:x, displayValue:x, description:x, order:1, current:false, completed:false, textStyle: xyz} ]
     *
     */
    flagProgressIndicatorsAsCompleted: function(cmp, progressIndicators) {
        this.log(cmp, 'flagProgressIndicatorsASCompleted ','debug',progressIndicators);
        if(progressIndicators && progressIndicators.length > 0) {
            let currentPi =  progressIndicators.find(ele => ele.current);
            if(currentPi) {
                progressIndicators.forEach( pi  => pi.completed = false);
                let earlierProgressIndicators = progressIndicators.filter( ele => {
                    return ele.order < currentPi.order  //  Note: filter does *NOT* mutate
                });
                earlierProgressIndicators.forEach( pi  => {
                    pi.completed = true;    //  if they are earlier in order flag as completed.
                    pi.textClass = 'accel-completed-text';
                });
                //  Now go back and MUTATE original array replace items with values set in earliestProgressIndicators.
                let flaggedPis = progressIndicators.map(pi =>
                    earlierProgressIndicators.find( pi2 => pi.value === pi2.value) || pi );

                //  Flag last one as completed if it's current
                let lastPi = flaggedPis[flaggedPis.length - 1];
                if(lastPi.current) {
                    lastPi.completed = true;
                    lastPi.current = false;
                }
                cmp.set('v.progressIndicators',flaggedPis);
                this.log(cmp, 'results of flagging progress indicators','debug',cmp.get('v.progressIndicators'));
            }
        }
    },
    /**
     * Here we roll through the v.progressIndicators array and flag the current / active entry based on Status__c.
     * 1. Find the Status__c value that was provided to us by LDS.
     * 2. Set all current progressIndicators to current = false;
     * 3. Do a match on v.progressIndicators by value of status and set that entry to current.
     *
     * @param cmp
     */
    flagCurrentProgressIndicator: function(cmp) {
        this.log(cmp, 'start flagCurrentProgressIndicators','debug');

        let record = cmp.get('v.record');
        if(record) {
            let currentStatus = Object.assign({}, record.fields.Status__c); //  Clone Just In Case.
            let progressIndicators = cmp.get('v.progressIndicators');

            if (currentStatus && progressIndicators && progressIndicators.length > 0) {
                //  Set all progressIndicators to not current.
                progressIndicators.forEach((el) => {
                    el.current = false;
                    el.textClass = '';
                    el.valueContainerClass = '';
                }); //  Note: MUTATES!
                let foundIdx = progressIndicators.findIndex(x => x.value === currentStatus.value);
                if (foundIdx !== -1) {    //  Set specific item in collection to current.
                    cmp.set('v.currentStepNbr',foundIdx + 1);
                    let progressIndicator = progressIndicators[foundIdx];
                    progressIndicator.current = true; //  Note: MUTATES!
                    progressIndicator.textClass = 'accel-current-text';
                    progressIndicator.valueContainerClass = 'accel-highlight-container';
                    this.calcProgressPct(cmp);
                    this.log(cmp, 'found idx of current', 'debug', progressIndicators);
                    this.flagProgressIndicatorsAsCompleted(cmp, progressIndicators);
                }
            }
        }
    },
    /**
     * This calculates the percent of the process completed ie. step 6 of 6 total steps = 100 pct complete.
     * This value is used for assistive text for screen readers.
     *
     * @param cmp
     */
    calcProgressPct: function(cmp) {
      let pct = 0;
      const currentStep = cmp.get('v.currentStepNbr');
      const totalSteps = cmp.get('v.totalNbrOfSteps');
      if(currentStep && totalSteps && currentStep !==0 && totalSteps !==0) {
          pct = currentStep / totalSteps * 100;
      }
      cmp.set('v.progressPct',pct);
    },
    /**
     *
     * @param cmp
     * @param payload
     */
    fireAppEvent: function( cmp, payload ) {
        let appEvent = $A.get("e.c:appEvent");
        appEvent.setParams({ "payload" : payload });
        appEvent.fire();
    },
    /**
     * Init generally aura utils.
     * @param cmp
     */
    initUtils:  function(cmp) {
        this.collectionUtils = cmp.find('collectionUtils');
        this.loggingUtils = cmp.find('loggingUtils');
        this.uiMessagingUtils = cmp.find('uiMessagingUtils');
    },
    /**
     * Toast an error msg with user friendly msg.
     * @param cmp
     * @param errors
     */
    handleInitErrors: function(cmp, errors,msg) {
        this.log(cmp,JSON.stringify(errors),'error');
        this.displayUiMsg(cmp,'error',msg);
    },
    /**
     * Fires a toast..
     * @param cmp
     * @param type [success,warning,error]
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
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
        let lvl;
        if (arguments.length === 0) {
            console.error('you must minimally pass the cmp ref and message to the log function');
            return;
        } else if (arguments.length === 1) {
            console.error('could not find message to log');
            return;
        } else if (arguments.length === 2) {
            lvl = 'debug';
        } else  {
            lvl = level;
        }
        try {
            if (cmp.get("v.debugConsole") || lvl === 'error') {
                var cmpName = '---- '+cmp.getName() + ' ----';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, lvl, msg, jsonObj);
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
});