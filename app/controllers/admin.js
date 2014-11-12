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
  cronTime: '00 00 */2 * * *',
  onTick: function() {
    db.users.find({'providers.moves.accessToken':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          strategies.movesStrategy._oauth2.get('https://api.moves-app.com/api/1.1/user/summary/daily?pastDays=2', user.providers.moves.accessToken, function(err, data) {
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

// Rescue Time Cron
new Cron({
  cronTime: '00 00 */2 * * *',
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
router.post('/projects', projectsPost);
router.post('/diplomas', diplomasPost);
router.post('/other_sport', otherSportPost);
router.post('/other_sport_data', otherSportDataPost);
router.post('/other_last', otherLastPost);
router.post('/other_last_data', otherLastDataPost);

exports.router = router;
