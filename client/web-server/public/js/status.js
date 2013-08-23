if (typeof String.prototype.startsWith != 'function') {
  String.prototype.startsWith = function (str){
    return this.slice(0, str.length) == str;
  };
}

function StatusCtrl($scope) {
  $scope.log = "";
  $scope.scores = [];

  $scope.source = new EventSource('/events');
  $scope.source.onmessage = function(e) {
    $scope.$apply(function () {
      $scope.logCount++;
      $scope.log += e.data + "\n";
      if(e.data.startsWith("SCORE")){
        $scope.log = "";
        $scope.updateScope(e.data);
      }
    });
  };

  $scope.updateScope = function(msg){
    var scores = msg.substring(6).split(",");
    $scope.scores = scores.map(function(score){
      var items = score.split(":");
      return { name: items[0], score: items[1] };
    });
  };

  $scope.compare = function(a,b) {
    if (a.score < b.score)
      return -1;
    if (a.score > b.score)
      return 1;
    return 0;
  };

  $scope.predicate = '-score';
}
