var exec = require('cordova/exec');

var MCCameraSwiftPlugin = {

    shoot: function (isProd,deviceNumber,customer,onSuccess, onError) {
        exec(onSuccess, onError, "MCCameraSwiftPlugin", "shoot", [isProd,deviceNumber,customer]);
    },
};
module.exports = MCCameraSwiftPlugin;