/*jshint node: true*/
var db = require('../../models/').db;
var passport = require('passport');

passport.serializeUser(function (user, done) {
  done(null, user._id);
});

passport.deserializeUser(function (id, done) {
  db.users.findOne({ _id: id }, function(err, user) {
    done(err, user);
  });
});

exports.ensureAuthenticated = function ensureAuthenticated(req, res, next) {
  if (req.isAuthenticated()) {
    return next();
  }
  res.redirect('/login');
};

exports.facebookStrategy = require('./facebook').strategy;
exports.githubStrategy = require('./github').strategy;
exports.linkedinStrategy = require('./linkedin').strategy;
exports.localStrategy = require('./local').strategy;
exports.movesStrategy = require('./moves').strategy;
exports.rescuetimeStrategy = require('./rescuetime').strategy;
exports.stravaStrategy = require('./strava').strategy;
exports.twitterStrategy = require('./twitter').strategy;
