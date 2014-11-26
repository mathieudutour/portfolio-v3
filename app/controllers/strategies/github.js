/*jshint node: true*/
var db = require('.../models/').db;
var config = require('.../config/').config;
var passport = require('passport');
var Cron = require('cron').CronJob;

exports.strategy = new (require('passport-github').Strategy)({
  clientID: config.github.clientID,
  clientSecret: config.github.clientSecret,
  callbackURL: config.siteURL + '/admin/auth/github/callback',
  passReqToCallback: true
  },
  function(req, accessToken, refreshToken, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.github = {
        name: 'github',
        accessToken: accessToken,
        refreshToken: refreshToken,
        link: profile._json.html_url
      };
      db.users.update({_id: req.user._id}, {$set : {'providers.github': req.user.providers.github}}, {}, function() {
        done(null, req.user);
      });
    }
  }
);
passport.use('github', exports.strategy);
