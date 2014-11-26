/*jshint node: true*/
var db = require('.../models/').db;
var config = require('.../config/').config;
var passport = require('passport');

exports.strategy = new (require('passport-linkedin').Strategy)({
  consumerKey: config.linkedin.consumerKey,
  consumerSecret: config.linkedin.consumerSecret,
  callbackURL: config.siteURL + '/admin/auth/linkedin/callback',
  passReqToCallback: true
  },
  function(req, token, tokenSecret, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.linkedin = {
        name: 'linkedin',
        token: token,
        tokenSecret: tokenSecret,
        link: "http://www.linkedin.com/profile/view?id=" + profile.id
      };
      db.users.update({_id: req.user._id}, {$set : {'providers.linkedin': req.user.providers.linkedin}}, {}, function() {
        done(null, req.user);
      });
    }
  }
);
passport.use('linkedin', exports.strategy);
