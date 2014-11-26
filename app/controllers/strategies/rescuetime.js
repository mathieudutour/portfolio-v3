/*jshint node: true*/
var db = require('../../models/').db;
var request = require('request');
var Cron = require('cron').CronJob;

exports.strategy = function (req, res) {
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
