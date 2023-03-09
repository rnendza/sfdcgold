import {LightningElement, track, api, wire} from 'lwc';
import Id from '@salesforce/user/Id';
import retrieveAsyncApexJobs from '@salesforce/apex/BatchUiController.retrieveAsyncApexJobs';
import retrieveAllAsyncApexJobsToday from '@salesforce/apex/BatchUiController.retrieveAllAsyncApexJobsToday';
import retrieveUserDetails from '@salesforce/apex/BatchUiController.retrieveUserDetails';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {loadStyle} from "lightning/platformResourceLoader";
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import { NavigationMixin } from 'lightning/navigation';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class BatchJobsStatus extends NavigationMixin(LightningElement) {

    @api recipientEmailUserId;
    @api chainBatchJobs = false;
    @api asyncJobName;
    @api showBatchJobHelpSection = false;
    @api batchJobTriggered = false;

    @track showRunningJob = false;
    @track batchJobViewValue = 'My current job';
    @track wiredAllJobsDto;

    _jobId;
    _batchJobViewOptions =  [{ label: 'My Jobs Today', value: 'My jobs today' }, {label: 'My Current Job', value:'My current job'}];

    @api
    get jobId() {
        return this._jobId;
    }
    set jobId(val) {
        if(val) {
            this.showRunningJob = true;
            this.batchJobViewValue = 'My current job';
            this._jobId = val;
        }
    }
    @api
    get showOverallJobStatus() {
        return this._showOverallJobStatus;
    }
    set showOverallJobStatus(val) {
        this._showOverallJobStatus = val;
    }
    @api
    get batchStatusRefreshInterval() {
        return this._batchStatusRefreshInterval;
    }
    set batchStatusRefreshInterval(val) {
        if(this.val) {
            this._batchStatusRefreshInterval = val * 1000;
        }
    }
    @api
    get apexClassNames() { return this._apexClassNames; }
    set apexClassNames(val) {
        this._apexClassNames = val;
    }
    @api
    get jobParams() { return  this._jobParams;}
    set jobParams(val) {
        this.paramDatas = [];
        this._jobParams;
        if(val) {
            Object.keys(val).map(e => {
                this.paramDatas.push({paramName:e, paramValue:val[e]});
            });
        }
    }
    @api
    get resultsTableStyle() {
        return '';
        // let height = '50px';
        // if(this.chainBatchJobs) {
        //     height = '115px';
        // }
        // return 'min-height:'+height;
    }
    @api
    handleBatchJobTriggered() {
        //  Fire query on an interval as defined by parent. @todo replace with PE / Change data capture?
        if(this.batchJobTriggered) {
            this.isProcessing = true;
            this._statusRefreshRef = setInterval(() => {
                this.queryForJobStatus();
            }, this.batchStatusRefreshInterval);
        }
    }
    @api
    get anyRunningJobsFound() {
        return this._anyRunningJobsFound;
    }
    set anyRunningJobsFound(val) {
        if(val) {
            this._anyRunningJobsFound = val;
            this.anyJobsFound = val || this.anyTodaysJobsFound;
        }
    }
    @api
    get anyTodaysJobsFound() {
        return this._anyTodaysJobsFound;
    }
    set anyTodaysJobsFound(val) {
        if(val) {
            this._anyTodaysJobsFound = val;
            this.anyJobsFound = val || this.anyRunningJobsFound;
        }
    }
    @api
    get anyJobsFound() {
        return this._anyJobsFound;
    }
    set anyJobsFound(val) {
        this._anyJobsFound = this.anyRunningJobsFound || this.anyTodaysJobsFound;
    }

    @api
    get showRunningJobSelected() {
        return this.batchJobViewValue === 'My current job';
    }

    @track paramDatas = [];
    @track isProcessing = false;
    @track columns = [];
    @track jobs = [];
    @track rowOffset = 0;
    @track allJobsCompleted = false;
    @track recipientEmailUser;
    @track asyncJobRecord;
    @track sortedBy = 'submittedDate';
    @track sortedDirection = 'desc';


    //  General Utility / Logging stuff
    _hasRendered    = false;
    _debugConsole   = false;
    _className      = 'BatchJobsStatus';
    _logger         = new Logger(this._debugConsole);
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);
    _anyRunningJobsFound = false;
    _anyTodaysJobsFound = false;
    _anyJobsFound = false;
    _userId;

    _apexClassNames = [];
    _jobParams = {};
    _batchStatusRefreshInterval = 1000;
    _statusRefreshRef;
    _showOverallJobStatus = false;


    constructor() {
        super();
    }
    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.handleBatchJobTriggered();
            this.columns = this.buildStatusColumns(); // build data table columns.
            this.loadCustomStyles();
            this.buildOverrideCss();
        }
    }
    connectedCallback() {
        this._userId = Id;
    }


    /**
     * Keep querying for job status on an interval. when all completed. clear the interval.
     * Shape the data for something suitable for a datatable and recreate to allow mutation if necessary.
     */
    queryForJobStatus() {

        let params = { apexClassNames: this.apexClassNames, jobId: this.jobId,
            bChain: this.chainBatchJobs, asyncJobName: this.asyncJobName
        };
        retrieveAsyncApexJobs(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    let tmp = (this._accelUtils.getMapValue('jobs', dto.values));
                    this.asyncJobRecord = this._accelUtils.getMapValue('async_job_record',dto.values);
                    this.shapeJobStatuses(tmp);
                    this.anyRunningJobsFound = true;
                } else {
                    this.anyRunningJobsFound = false;
                }
            })
            .catch(error => {
                this.isProcessing = false;
                console.error(JSON.stringify(error));
                clearInterval(this._statusRefreshRef);
                this.log('info', '<<< clear refresh interval! >>>');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while processing current jobs.',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    queryForJobsToday() {
        this.isProcessing = true;
        let params = {userId: this._userId};


        retrieveAllAsyncApexJobsToday(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    this.anyTodaysJobsFound = true;
                    this.isProcessing = false;
                    let tmp = (this._accelUtils.getMapValue('jobs', dto.values));
                    this.shapeJobStatuses(tmp);
                } else {
                    this.isProcessing = false;
                    this.anyTodaysJobsFound = false;
                }
            })
            .catch(error => {
                this.isProcessing = false;
                console.error(JSON.stringify(error));
                clearInterval(this._statusRefreshRef);
                this.log('info', '<<< clear refresh interval! >>>');

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while processing todays jobs',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    shapeJobStatuses(jobs) {
        let newJobs = [];
        this.jobs = [];
        if(jobs) {
            jobs.forEach(job => {
                let newJob = Object.assign({}, job);
                newJob.jobId = job.Id;
                newJob.submittedDate = job.CreatedDate;
                if(job.ApexClass) {
                    newJob.apexClassName = job.ApexClass.Name;
                } else {
                    newJob.apexClassName = '';
                }
                newJob.jobItemsProcessed = job.JobItemsProcessed;
                newJob.status = job.Status;
                newJob.totalJobItems = job.TotalJobItems;
                newJob.numberOfErrors = job.NumberOfErrors;
                newJob.completedDate = job.CompletedDate;
                newJob.createdByUsername = job.CreatedBy.Username;
                newJob.statusClass = (newJob.status === 'Completed' ? 'slds-text-color_success' :
                    newJob.status === 'Error' ? 'slds-text-color_error' : '');
                newJobs.push(newJob);
            });
        }
        this.jobs = newJobs;
        if(this.asyncJobRecord) {
            this.showOverallJobStatus = true;
            if(this.asyncJobRecord.Batch_Group_Status__c && this.asyncJobRecord.Batch_Group_Status__c === 'Completed') {
                this.allJobsCompleted = true;
            }
        } else {
            this.showOverallJobStatus = false;
        }
        if(this.allJobsCompleted) {
            try {
                this.isProcessing = false;
                clearInterval(this._statusRefreshRef);
                this.dispatchEvent( new CustomEvent('alljobscompleted') );
                this.log('info', '<<< clear refresh interval! >>>');
            } catch (e) {
                alert(e);
            }
        }

    }



    /**
     * Get full user details (as opposed to just userId, in case it's needed)
     * @param error
     * @param data
     */
    @wire(retrieveUserDetails, { userId: '$recipientEmailUserId' })
    wiredUserDetails({ error, data }) {
        if (data) {
            this.recipientEmailUser = data;
        } else if (error) {
            //this.error = error;
        }
    }
    handleBatchJobPlChange(event) {
        this.batchJobViewValue = event.detail.value;
        if(this.batchJobViewValue === 'My jobs today') {
            this.showRunningJob = false;
            clearInterval(this._statusRefreshRef);
            this.jobs = [];
            this.anyRunningJobsFound = false;
            this.queryForJobsToday();
        } else {
            this.showRunningJob = true;
            this.jobs = [];
            this.anyRunningJobsFound = false;
            this.queryForJobStatus();
        }
    }

    handleDatatableSort(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.jobs = this.sortData(this.jobs,fieldName, sortDirection);
    }
    sortData(data, fieldname, direction) {
        // serialize the data before calling sort function
        //  @todo this is slow on large results use a spread or deep copy instead..
        let parseData = JSON.parse(JSON.stringify(data));

        // Return the value stored in the field
        let keyValue = (a) => { return a[fieldname];};
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        // set the sorted data to data table data
        return parseData;
    }

    handleAbortJob(event) {

    }
    buildStatusColumns() {
        return [
            {
                label: 'Submitted', fieldName: 'submittedDate', type: 'date', sortable: true, typeAttributes: {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true
                }
            },
            {
                label: 'Completed', fieldName: 'completedDate', type: 'date', sortable: true, typeAttributes: {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true
                }
            },
            {
                label: 'Status',
                fieldName: 'status',
                sortable: true,
                cellAttributes: {'class': {"fieldName": 'statusClass'}}
            },
            {
                label: 'Total Batches',
                fieldName: 'totalJobItems',
                sortable: true,
                type: 'number',
                cellAttributes: {alignment: 'lef'}
            },
            {
                label: 'Processed',
                fieldName: 'jobItemsProcessed',
                type: 'number',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Failures',
                fieldName: 'numberOfErrors',
                type: 'number',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Apex Class', fieldName: 'apexClassName', sortable: true, initialWidth: 285, tooltip: {
                    fieldName: 'apexClassName'
                }
            }
        ];
    }
    @api
    get batchJobViewOptions() {
       return this._batchJobViewOptions
    }
    set batchJobViewOptions( val ) {
        this._batchJobViewOptions = val;
    }
    loadCustomStyles() {
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {
            this.log('DEBUG','lwc_datatable_styles loaded');
        }).catch (error => {
            console.log(error);
        });
    }
    buildOverrideCss() {
        let css ='.slds-table {font-size:.875em!important} .c3llc-autocomplete-tab slds-tabs_scoped__content{padding-top:4px}';

        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.fake-theme-overrides-class');
        target.appendChild(style);
    }
    /**
     *
     * @param logType  The type of log (see the constants). (optional)
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            if(msg) {
                if(this._className) {
                    msg = this._className + ' - ' + msg;
                }
            }
            switch (logType) {
                case DEBUG:
                    this._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    this._logger.logError(msg,obj);
                    break;
                case INFO:
                    this._logger.logInfo(msg,obj);
                    break;
                default:
                    this._logger.log(msg, obj);
            }
        }
    }
}