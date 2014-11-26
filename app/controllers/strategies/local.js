/*jshint node: true*/
var db = require('../../models/').db;
var passport = require('passport');
var sha1 = require('sha1');

exports.strategy = new (require('passport-local').Strategy)(
  function(username, password, done) {
    db.users.findOne({ email: username }, function(err, user) {
      if (err) { return done(err); }
      if (!user) {
        return done(null, false, { message: 'Incorrect username.' });
      }
      if (user.password !== sha1(password)) {
        return done(null, false, { message: 'Incorrect password.' });
      }
      return done(null, user);
    });
  }
);
passport.use('local', exports.strategy);
