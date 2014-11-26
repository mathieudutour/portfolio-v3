/*jshint node: true*/
var router = require('express').Router();
var passport = require('passport');
var db = require('../models/').db;
var strategies = require('./strategies/');

var controller = function (req, res) {
  res.render('admin.html', req.user);
};

var projectsPost = function (req, res) {
  var projects = {
    first_project: {
      name: req.body.first_project,
      icon: req.body.first_project_icon,
      description: req.body.first_project_description,
      url: req.body.first_project_url
    },
    second_project: {
      name: req.body.second_project,
      icon: req.body.second_project_icon,
      description: req.body.second_project_description,
      url: req.body.second_project_url
    },
    third_project: {
      name: req.body.third_project,
      icon: req.body.third_project_icon,
      description: req.body.third_project_description,
      url: req.body.third_project_url
    },
    last_project: {
      name: req.body.last_project,
      icon: req.body.last_project_icon,
      description: req.body.last_project_description,
      url: req.body.last_project_url
    }
  };
  db.users.update({_id: req.user._id}, {$set: {'providers.projects': projects}}, function() {
    return res.redirect('/admin');
  });
};

var otherSportPost = function (req, res) {
  var other = {
    name: req.body.name,
    image: req.body.image,
    data: [],
    value: 0,
    value_name: req.body.value_name
  };
  db.users.update({_id: req.user._id}, {$set: {'providers.other_sport': other}}, function() {
    return res.redirect('/admin');
  });
};

var otherSportDataPost = function (req, res) {
  if(!isNaN(req.body.value)) {
    var point = {
      value: parseFloat(req.body.value),
      timestamp: req.body.timestamp !== "" ? new Date(req.body.timestamp) : new Date()
    };
    db.users.update({_id: req.user._id}, {$push: {'providers.other_sport.data': point}, $inc: {'providers.other_sport.value': point.value}}, function() {
      return res.redirect('/admin');
    });
  } else {
    console.log('not a number');
    return res.redirect('/admin');
  }
};

var otherLastPost = function (req, res) {
  var other = {
    name: req.body.name,
    image: req.body.image,
    data: [],
    last: new Date()
  };
  db.users.update({_id: req.user._id}, {$set: {'providers.other_last': other}}, function() {
    return res.redirect('/admin');
  });
};

var otherLastDataPost = function (req, res) {
  var point = {
    timestamp: req.body.timestamp && req.body.timestamp !== "" ? new Date(req.body.timestamp) : new Date()
  };
  db.users.update({_id: req.user._id}, {$push: {'providers.other_last.data': point}, $set: {'providers.other_last.last':point.timestamp}}, function() {
    return res.redirect('/admin');
  });
};

var diplomasPost = function (req, res) {
  var diplomas = {
    first_diploma: {
      name: req.body.first_diploma,
      icon: req.body.first_diploma_icon,
      description: req.body.first_diploma_description,
      url: req.body.first_diploma_url
    },
    second_diploma: {
      name: req.body.second_diploma,
      icon: req.body.second_diploma_icon,
      description: req.body.second_diploma_description,
      url: req.body.second_diploma_url
    }
  };
  db.users.update({_id: req.user._id}, {$set: {'providers.diplomas': diplomas}}, function() {
    return res.redirect('/admin');
  });
};

router.get('/', controller);
router.get('/auth/facebook', passport.authenticate('facebook', { session: false }));
router.get('/auth/facebook/callback', passport.authenticate('facebook', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));
router.get('/auth/strava', passport.authenticate('strava', { session: false }));
router.get('/auth/strava/callback', passport.authenticate('strava', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));
router.get('/auth/twitter', passport.authenticate('twitter', { session: false }));
router.get('/auth/twitter/callback', passport.authenticate('twitter', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));
router.get('/auth/github', passport.authenticate('github', { session: false , scope: ['user', 'repo'] }));
router.get('/auth/github/callback', passport.authenticate('strava', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));
router.get('/auth/linkedin', passport.authenticate('linkedin', { session: false }));
router.get('/auth/linkedin/callback', passport.authenticate('linkedin', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));
router.get('/auth/moves', passport.authenticate('moves', { session: false }));
router.get('/auth/moves/callback', passport.authenticate('moves', { session: false , successRedirect: '/admin',failureRedirect: '/admin' }));

router.post('/rescuetime', strategies.rescuetimeStrategy);
router.post('/projects', projectsPost);
router.post('/diplomas', diplomasPost);
router.post('/other_sport', otherSportPost);
router.post('/other_sport_data', otherSportDataPost);
router.post('/other_last', otherLastPost);
router.post('/other_last_data', otherLastDataPost);

exports.router = router;
