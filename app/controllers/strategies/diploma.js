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
  db.users.update({_id: req.user._id, 'providers.diplomas.index': req.body.index}, {$set: {"providers.diplomas.$": diploma}}, function() {
    return res.redirect('/admin');
  });
};
