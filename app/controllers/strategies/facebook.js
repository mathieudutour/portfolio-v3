/*jshint node: true*/
var db = require('.../models/').db;
var config = require('.../config/').config;
var passport = require('passport');

exports.strategy = new (require('passport-facebook').Strategy)({
  clientID: config.facebook.clientID,
  clientSecret: config.facebook.clientSecret,
  callbackURL: config.siteURL + '/admin/auth/facebook/callback',
  passReqToCallback: true
  },
  function(req, accessToken, refreshToken, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.facebook = {
        name: 'facebook',
        accessToken: accessToken,
        refreshToken: refreshToken,
        link: profile._json.link
      };
      db.users.update({_id: req.user._id}, {$set : {'providers.facebook': req.user.providers.facebook}}, {}, function() {
        done(null, req.user);
      });
    }
  }
);
passport.use('facebook', exports.strategy);
