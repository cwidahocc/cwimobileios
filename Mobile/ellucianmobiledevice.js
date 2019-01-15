window.EllucianMobileDevice = {

    log : function (message) {
        var params = {"name" : "log", "message" : message};
        webkit.messageHandlers.ellucian.postMessage(params);
    },
    openMenu : function (name, type) {
        var params = {"name" : "openMenu", "moduleName" : name, "moduleType" : type};
        webkit.messageHandlers.ellucian.postMessage(params);
    },
    refreshRoles : function ( ) {
        var params = {"name" : "refreshRoles"};
        webkit.messageHandlers.ellucian.postMessage(params);
    },
    reloadWebModule : function ( ) {
        var params = {"name" : "reloadWebModule"};
        webkit.messageHandlers.ellucian.postMessage(params);
    }
};
