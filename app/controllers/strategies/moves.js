/*jshint node: true*/
var db = require('../../models/').db;
var config = require('../../config/').config;
var passport = require('passport');
var Cron = require('cron').CronJob;

exports.strategy = new (require('./passport-moves').Strategy)({
  clientID: config.moves.clientID,
  clientSecret: config.moves.clientSecret,
  callbackURL: config.siteURL + '/admin/auth/moves/callback',
  passReqToCallback: true
  },
  function(req, accessToken, refreshToken, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.moves = {
        name: 'moves',
        accessToken: accessToken,
        refreshToken: refreshToken,
        steps: 0
      };
      db.users.update({email: req.user.email}, {$set : { 'providers.moves': req.user.providers.moves}}, {}, function() {
        exports.strategy._oauth2.get('https://api.moves-app.com/api/1.1/user/summary/daily?pastDays=2', accessToken, function(err, data) {
          if(err) {return done(err);}
          data = JSON.parse(data)[0].summary;
          var steps = 0;
          data.forEach(function(activity) {
            if(activity.steps) {
              steps += activity.steps;
            }
          });
          db.users.update({_id: req.user._id}, {$set: {'providers.moves.steps': steps}}, function() {done(null, req.user);});
        });
      });
    }
  }
);
passport.use('moves', exports.strategy);

// Moves Cron
new Cron({
  cronTime: '00 00 */2 * * *',
  onTick: function() {
    db.users.find({'providers.moves.accessToken':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          exports.strategy._oauth2.get('https://api.moves-app.com/api/1.1/user/summary/daily?pastDays=2', user.providers.moves.accessToken, function(err, data) {
          if(err) {return console.log(err);}
          data = JSON.parse(data)[0].summary;
          var steps = 0;
          if(data) {
            data.forEach(function(activity) {
              if(activity.steps) {
                steps += activity.steps;
              }
            });
          }
          db.users.update({_id: user._id}, {$set: {'providers.moves.steps': steps}}, function() {});
        });
        });
      } else {
        return console.log("Twitter not configured yet");
      }
    });
  },
  start: true
});
