/*jshint node: true*/
var db = require('../../models/').db;
var request = require('request');
var Cron = require('cron').CronJob;

var apiKey = function (req, res) {
  var api_key = req.body.api_key;
  var today = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate();
  request("https://www.rescuetime.com/anapi/data?format=json&key="+api_key+"&restrict_begin=2000-01-01&restrict_end="+today, function (error, response) {
    if (!error && response.statusCode == 200) {
      db.users.findOne({ _id: req.user._id }, function(err, user) {
        var rescuetime = user.providers.rescuetime || {api_key:null,tracks:[]};
        rescuetime.api_key = api_key;
        db.users.update({_id: req.user._id}, {$set: {'providers.rescuetime': rescuetime}}, function() {
          return res.redirect('/admin');
        });
      });
    } else {
      return res.redirect('/admin');
    }
  });
};

var track = function (req, res) {
  var api_key = req.body.api_key;
  var track = {
    index: req.body.index,
    name: req.body.name,
    image: req.body.image,
    count: 0
  };
  var today = new Date().getFullYear() + '-' + (new Date().getMonth() + 1) + '-' + new Date().getDate();
  request("https://www.rescuetime.com/anapi/data?format=json&key="+api_key+"&restrict_begin=2000-01-01&restrict_end="+today, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      body = JSON.parse(body).rows;
      if (body && body.length && body.length > 0) {
        for(var i = 0; i < body.length; i++) {
          if(body[i][3] == track.name) {
            track.count = (body[i][1] / 3600).toFixed(0);
            break;
          }
        }
      }
      db.users.findOne({ _id: req.user._id }, function(err, user) {
        if(user.providers.rescuetime.tracks.length>0) {
          if(track.index == user.providers.rescuetime.tracks.length) {
            db.users.update({_id: req.user._id}, {$push: {"providers.rescuetime.tracks": track}}, function() {
              return res.redirect('/admin');
            });
          } else {
            db.users.update({_id: req.user._id, 'providers.rescuetime.tracks.index': track.index}, {$set: {"providers.rescuetime.tracks.$": track}}, function() {
              return res.redirect('/admin');
            });
          }
        } else {
          track.index = 0;
          db.users.update({_id: req.user._id}, {$push: {"providers.rescuetime.tracks": track}}, function() {
            return res.redirect('/admin');
          });
        }
      });
    } else {
      return res.redirect('/admin');
    }
  });
};

exports.strategy = {
  apiKey: apiKey,
  track: track
};

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
              if (body && body.length && body.length > 0 && user.providers.rescuetime.tracks.length > 0) {
                for(var j = 0; j < user.providers.rescuetime.tracks.length; j++) {
                  for(var i = 0; i < body.length; i++) {
                    if(body[i][3] == user.providers.rescuetime.tracks[j].name) {
                      user.providers.rescuetime.tracks[i].count = (body[i][1] / 3600).toFixed(0);
                      break;
                    }
                  }
                }
              }
              db.users.update({_id: user._id}, {$set: {'providers.rescuetime.tracks': user.providers.rescuetime.tracks}}, function() {});
            }
          });
        });
      } else {
        return console.log("Rescuetime not configured yet");
      }
    });
  },
  start: true
});
