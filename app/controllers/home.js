/*jshint node: true*/
var db = require('../models/').db;
var marked = require('marked');
var moment = require('moment');

function niceTimestamp (timestamp) {
  return moment(timestamp).fromNow();
}

var controller = function (req, res, next) {
  var slug_name = req.params.slug || 'mathieu-dutour';
  db.users.findOne({slug_name: slug_name}, function(err, user) {
    if(err) {return next(err);}
    if(user) {
      var data = user.providers;
      data.marked = marked;
      data.niceTimestamp = niceTimestamp;
      res.render('index.html', data);
    } else {
      res.redirect('/login');
    }
  });
};

exports.controller = controller;
