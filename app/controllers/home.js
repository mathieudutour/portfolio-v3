/*jshint node: true*/
var db = require('../models/').db;

var controller = function (req, res, next) {
  db.providers.find({}, function(err, docs) {
    if(err) {return next(err);}
    if(docs && docs.length > 0) {
      var data = {basic:null, facebook: null, twitter: null, github: null, linkedin: null, strava: null};
      for(var i = 0; i < docs.length; i++) {
        data[docs[i].name] = docs[i];
      }
      //console.log(data);
      res.render('index.html', data);
    } else {
      res.redirect('/admin');
    }
  });
};

exports.controller = controller;
