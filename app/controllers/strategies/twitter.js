/*jshint node: true*/
var db = require('.../models/').db;
var config = require('.../config/').config;
var passport = require('passport');
var Cron = require('cron').CronJob;

exports.strategy = new (require('passport-twitter').Strategy)({
  consumerKey: config.twitter.consumerKey,
  consumerSecret: config.twitter.consumerSecret,
  callbackURL: config.siteURL + '/admin/auth/twitter/callback',
  passReqToCallback: true
  },
  function(req, token, tokenSecret, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      var avatar_provider = req.user.providers.basic.avatar_provider;
      var avatar = req.user.providers.basic.avatar;
      if(avatar_provider === null) {
        avatar_provider = 'twitter';
        avatar = profile._json.profile_image_url;
        req.user.providers.basic.avatar_provider = avatar_provider;
        req.user.providers.basic.avatar = avatar;
      }
      req.user.providers.twitter = {
        name: 'twitter',
        token: token,
        tokenSecret: tokenSecret,
        link: "https://twitter.com/" + profile._json.screen_name,
        image: profile._json.profile_image_url, // or profile_image_url_https
        last_tweet: null
      };
      db.users.update({email: req.user.email}, {$set : {'providers.basic.avatar_provider': avatar_provider, 'providers.basic.avatar': avatar, 'providers.twitter': req.user.providers.twitter}}, {}, function() {
        exports.twitterStrategy._oauth.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=1', token, tokenSecret, function(err, data) {
          if(err) {return done(err);}
          data = JSON.parse(data);
          db.users.update({_id: req.user._id}, {$set: {'providers.twitter.last_tweet': data[0].text}}, function() {done(null, req.user);});
        });
      });
    }
  }
);
passport.use('twitter', exports.strategy);

// Twitter Cron
new Cron({
  cronTime: '00 */15 * * * *',
  onTick: function() {
    db.users.find({'providers.twitter.token':{$exists: true}}, function(err, users) {
      if(err) {return console.log(err);}
      if(users && users.length > 0) {
        users.forEach(function(user) {
          exports.strategy._oauth.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=1', user.providers.twitter.token, user.providers.twitter.tokenSecret, function(err, data) {
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
