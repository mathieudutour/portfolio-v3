/*jshint node: true*/
var db = require('../../models/').db;

exports.strategy = function (req, res) {
  var projects = [
    {
      name: req.body.first_project,
      icon: req.body.first_project_icon,
      description: req.body.first_project_description,
      url: req.body.first_project_url
    },
    {
      name: req.body.second_project,
      icon: req.body.second_project_icon,
      description: req.body.second_project_description,
      url: req.body.second_project_url
    },
    {
      name: req.body.third_project,
      icon: req.body.third_project_icon,
      description: req.body.third_project_description,
      url: req.body.third_project_url
    },
    {
      name: req.body.last_project,
      icon: req.body.last_project_icon,
      description: req.body.last_project_description,
      url: req.body.last_project_url
    }
  ];
  db.users.update({_id: req.user._id}, {$set: {'providers.projects': projects}}, function() {
    return res.redirect('/admin');
  });
};
