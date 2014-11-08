/*jshint node: true*/
var db = require('../models/').db;

var controller = function (req, res, next) {
  var slug_name = req.params.slug || 'mathieu-dutour';
  db.users.findOne({slug_name: slug_name}, function(err, user) {
    if(err) {return next(err);}
    if(user) {
      //console.log(user);
      res.render('index.html', user.providers);
    } else {
      res.redirect('/login');
    }
  });
};

exports.controller = controller;
