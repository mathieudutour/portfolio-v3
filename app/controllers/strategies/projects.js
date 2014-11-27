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
  db.users.update({_id: req.user._id, 'providers.projects.index': req.body.index}, {$set: {"providers.projects.$": project}}, function() {
    return res.redirect('/admin');
  });
};
