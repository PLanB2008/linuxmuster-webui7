// Generated by CoffeeScript 1.12.7
(function() {
  angular.module('lm.wdatetime', ['core', 'ajenti.dashboard']);

}).call(this);

// Generated by CoffeeScript 1.12.7
(function() {
  angular.module('lm.wdatetime').controller('lm.wdatetime', function($scope) {
    return $scope.$on('widget-update', function($event, id, data) {
      if (id !== $scope.widget.id) {
        return;
      }
      return $scope.value = data;
    });
  });

  angular.module('lm.wdatetime').controller('lm.wdatetimeconfig', function($scope) {
    var base;
    return (base = $scope.configuredWidget.config).format != null ? base.format : base.format = "%d.%m.%Y %H:%M";
  });

}).call(this);

