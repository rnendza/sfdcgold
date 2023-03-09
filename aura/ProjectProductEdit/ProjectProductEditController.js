({
    init : function(component, event, helper) {
        component.set('v.columns', helper.getColumnDefinitions());
    },

    handleEdit: function(component, event, helper) {
        var projectLines = component.get('v.projectLines');
        var draftProjectLines = component.find('projectLineTable').get('v.draftValues');
        for(var i = 0; i < projectLines.length; i++) {
            var projectLine = projectLines[i];
            if(draftProjectLines.length > 0) {
                if(projectLine.Id === draftProjectLines[0].Id) {
                    for(var key in draftProjectLines[0]) {
                        projectLine[key] = draftProjectLines[0][key];
                        projectLines[i] = projectLine;
                    }    
                }
            }
        }
        component.set('v.projectLines', projectLines);
        component.find('projectLineTable').set('v.draftValues', null);
    },

    saveProjectLineItems : function(component, event, helper) {
        var params = event.getParam('arguments');
        var saveProjectLinesCallback;
        if (params) {
            saveProjectLinesCallback = params.saveProjectLinesCallback;
        }

        helper.executeAction(component, 'c.saveProjectLines', {
            'projectLines' : component.get('v.projectLines'),
            'projectId' : component.get('v.recordId')
        })
        .then($A.getCallback(function(response) {
            if (saveProjectLinesCallback) saveProjectLinesCallback(response);
        }))
        .catch($A.getCallback(function(error) {
            console.log(error.message);
        }));
    }
})