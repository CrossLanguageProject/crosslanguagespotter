function myservices($scope){
    $scope.services=[
        { title: 'web development', price: 200},
        { title: 'web design', price: 250},
        { title: 'photography', price: 100},
        { title: 'coffee drinking', price: 10}];
    $scope.total=function(){
        var t = 0;
        angular.forEach($scope.services, function(s){
            if(s.selected)
                t+=s.price;
        });
        return t;
    };
}