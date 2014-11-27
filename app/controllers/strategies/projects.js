/*jshint node: true*/
var db = require('../../models/').db;

exports.strategy = function (req, res) {
  var project = {
    index: req.body.index,
    name: req.body.name,
    icon: req.body.icon,
    description: req.body.description,
    url: req.body.url
  };
  db.users.findOne({ _id: req.user._id }, function(err, user) {
    if(user.providers.diplomas.length>0) {
      if(project.index == user.providers.diplomas.length) {
        db.users.update({_id: req.user._id}, {$push: {"providers.projects": project}}, function() {
          return res.redirect('/admin');
        });
      } else {
        db.users.update({_id: req.user._id, 'providers.projects.index': project.index}, {$set: {"providers.projects.$": project}}, function() {
          return res.redirect('/admin');
        });
      }
    } else {
      project.index = 0;
      db.users.update({_id: req.user._id}, {$push: {"providers.projects": project}}, function() {
        return res.redirect('/admin');
      });
    }
  });
};
