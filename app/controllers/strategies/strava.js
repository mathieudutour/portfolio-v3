/*jshint node: true*/
var db = require('../../models/').db;
var config = require('../../config/').config;
var passport = require('passport');

exports.strategy = new (require('passport-strava').Strategy)({
  clientID: config.strava.clientID,
  clientSecret: config.strava.clientSecret,
  callbackURL: config.siteURL + '/admin/auth/strava/callback',
  passReqToCallback: true
  },
  function(req, accessToken, refreshToken, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.strava = {
        name: 'strava',
        accessToken: accessToken,
        refreshToken: refreshToken,
        link: "http://www.strava.com/athletes/" + profile.id
      };
      db.users.update({_id: req.user._id}, {$set : {'providers.strava': req.user.providers.strava}}, {}, function() {
        done(null, req.user);
      });
    }
  }
);
passport.use('strava', exports.strategy);
