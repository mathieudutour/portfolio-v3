/*jshint node: true*/
var db = require('../../models/').db;

exports.strategy = function (req, res) {
  var diploma = {
    index: req.body.index,
    name: req.body.name,
    icon: req.body.icon,
    description: req.body.description,
    url: req.body.url
  };
  db.users.findOne({ _id: req.user._id }, function(err, user) {
    if(user.providers.diplomas.length>0) {
      if(diploma.index == user.providers.diplomas.length) {
        db.users.update({_id: req.user._id}, {$push: {"providers.diplomas": diploma}}, function() {
          return res.redirect('/admin');
        });
      } else {
        db.users.update({_id: req.user._id, 'providers.diplomas.index': diploma.index}, {$set: {"providers.diplomas.$": diploma}}, function() {
          return res.redirect('/admin');
        });
      }
    } else {
      diploma.index = 0;
      db.users.update({_id: req.user._id}, {$push: {"providers.diplomas": diploma}}, function() {
        return res.redirect('/admin');
      });
    }
  });

};
