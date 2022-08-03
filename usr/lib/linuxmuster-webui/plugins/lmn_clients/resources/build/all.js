'use strict';

angular.module('lmn.clients', ['lmn.common']);


'use strict';

angular.module('lmn.clients').config(function ($routeProvider) {
    $routeProvider.when('/view/lmn_clients', {
        templateUrl: '/lmn_clients:resources/partial/index.html',
        controller: 'Lmn_clientsIndexController'
    });
});


'use strict';

angular.module('lmn.clients').controller('Lmn_clientsIndexController', function ($scope, $http, pageTitle, gettext, notify) {
    pageTitle.set(gettext('Lmn_clients'));

    $scope.pathToEdit = '';
    $scope.scriptContent = '';

    $http.get('/api/lmn/clients/scripts').then(function (resp) {
        $scope.custom_scripts_path = resp.data['path'];
        $scope.custom_scripts_linux = resp.data['linux'];
        $scope.custom_scripts_windows = resp.data['windows'];
    });

    $scope.editScript = function (script) {
        $scope.scriptToEdit = script;
    };

    $scope.saveScript = function (script) {
        $http.post('/api/lmn/client/script', { 'path': script.path, 'content': script.content }).then(function () {
            $scope.scriptToEdit = '';
            notify.success(gettext('Script saved !'));
        }, function () {
            return notify.error(gettext('Error while saving script'));
        });
    };

    $scope.closeEditScript = function () {
        $scope.scriptToEdit = '';
    };

    $scope.loadDrives = function () {
        $http.get('/api/lmn/samba/drives').then(function (resp) {
            $scope.drives = resp.data[0];
            $scope.availableDriveLetters = resp.data[1];
        });
    };

    $scope.saveDrives = function () {
        $http.post('/api/lmn/samba/drives', { 'drives': $scope.drives }).then(function (resp) {
            return notify.success(gettext('Saved !'));
        }, function (err) {
            return notify.error(err.data.message);
        });
    };
}).filter('driveLettersOptions', function ($filter) {
    return function (value, driveLetter) {
        return value.filter(function (obj) {
            return !obj.active || obj.active && obj.letter == driveLetter;
        });
    };
});


