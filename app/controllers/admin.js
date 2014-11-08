/*jshint node: true*/
var router = require('express').Router();
var passport = require('passport');
var Cron = require('cron').CronJob;
var db = require('../models/').db;
var strategies = require('./strategies');
var request = require('request');

var controller = function (req, res) {
  res.render('admin.html', req.user);
};

var rescuetimePost = function (req, res) {
  var rescuetime = {
    api_key: req.body.api_key,
    first_track: {
      name: req.body.first_track,
      image: req.body.image_first_track,
      count: 0
    },
    second_track: {
      name: req.body.second_track,
      image: req.body.image_second_track,
      count: 0
    }
  };
  var today = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate();
  request("https://www.rescuetime.com/anapi/data?format=json&key="+rescuetime.api_key+"&restrict_begin=2000-01-01&restrict_end="+today, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      body = JSON.parse(body).rows;
      if (body && body.length && body.length > 0) {
        var count = 0;
        for(var i = 0; i < body.length; i++) {
          if(body[i][3] == rescuetime.first_track.name) {
            rescuetime.first_track.count = (body[i][1] / 3600).toFixed(0);
            count++;
          } else if (body[i][3] == rescuetime.second_track.name) {
            rescuetime.second_track.count = (body[i][1] / 3600).toFixed(0);
            count++;
          }
          if(count >= 2) {
            break;
          }
        }
      }
      db.users.update({_id: req.user._id}, {$set: {'providers.rescuetime': rescuetime}}, function() {
        return res.redirect('/admin');
      });
    } else {
      return res.redirect('/admin');
    }
  });
};

// Twitter Cron
new Cron({
  cronTime: '00 */15 * * * *',
  onTick: function() {
    db.users.find({'providers.twitter.token':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          strategies.twitterStrategy._oauth.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=1', user.providers.twitter.token, user.providers.twitter.tokenSecret, function(err, data) {
            if(err) {return console.log(err);}
            data = JSON.parse(data);
            db.users.update({_id: user._id}, {$set: {'providers.twitter.last_tweet': data[0].text}}, function() {});
          });
        });
      } else {
        return console.log("Twitter not configured yet");
      }
    });
  },
  start: true
});

// Moves Cron
new Cron({
  cronTime: '00 */15 * * * *',
  onTick: function() {
    db.users.find({'providers.moves.accessToken':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          strategies.movesStrategy._oauth2.get('https://api.moves-app.com/api/1.1/user/summary/daily?pastDays=2', user.providers.moves.accessToken, function(err, data) {
          if(err) {return console.log(err);}
          data = JSON.parse(data)[0].summary;
          var steps = 0;
          data.forEach(function(activity) {
            if(activity.steps) {
              steps += activity.steps;
            }
          });
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

// Rescue Time Cron
new Cron({
  cronTime: '00 */15 * * * *',
  onTick: function() {
    db.users.find({'providers.rescuetime.api_key':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          var today = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate();
          request("https://www.rescuetime.com/anapi/data?format=json&key="+user.providers.rescuetime.api_key+"&restrict_begin=2000-01-01&restrict_end="+today, function (error, response, body) {
            if (!error && response.statusCode == 200) {
              body = JSON.parse(body).rows;
              if (body && body.length && body.length > 0) {
                var count = 0;
                for(var i = 0; i < body.length; i++) {
                  if(body[i][3] == user.providers.rescuetime.first_track.name) {
                    user.providers.rescuetime.first_track.count = (body[i][1] / 3600).toFixed(0);
                    count++;
                  } else if (body[i][3] == user.providers.rescuetime.second_track.name) {
                    user.providers.rescuetime.second_track.count = (body[i][1] / 3600).toFixed(0);
                    count++;
                  }
                  if(count >= 2) {
                    break;
                  }
                }
              }
              db.users.update({_id: user._id}, {$set: {'providers.rescuetime.first_track.count': user.providers.rescuetime.first_track.count, 'providers.rescuetime.second_track.count': user.providers.rescuetime.second_track.count}}, function() {});
            }
          });
        });
      } else {
        return console.log("Twitter not configured yet");
      }
    });
  },
  start: true
});

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

router.post('/rescuetime', rescuetimePost);

exports.router = router;
