/*jshint node: true*/
var db = require('../models/').db;
var config = require('../config/').config;
var passport = require('passport');
var sha1 = require('sha1');

passport.serializeUser(function (user, done) {
  done(null, user._id);
});

passport.deserializeUser(function (id, done) {
  db.users.findOne({ _id: id }, function(err, user) {
    done(err, user);
  });
});

exports.localStrategy = new (require('passport-local').Strategy)(
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
passport.use('local', exports.localStrategy);

exports.facebookStrategy = new (require('passport-facebook').Strategy)({
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
passport.use('facebook', exports.facebookStrategy);

exports.stravaStrategy = new (require('passport-strava').Strategy)({
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
passport.use('strava', exports.stravaStrategy);

exports.twitterStrategy = new (require('passport-twitter').Strategy)({
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
passport.use('twitter', exports.twitterStrategy);

exports.githubStrategy = new (require('passport-github').Strategy)({
  clientID: config.github.clientID,
  clientSecret: config.github.clientSecret,
  callbackURL: config.siteURL + '/admin/auth/github/callback',
  passReqToCallback: true
  },
  function(req, accessToken, refreshToken, profile, done) {
    if (!req.user) {
      return done(null, false, { message: 'Not Logged In' });
    } else {
      console.log(profile);
      req.user.providers.github = {
        name: 'github',
        accessToken: accessToken,
        refreshToken: refreshToken,
        link: profile._json.html_url
      };
      db.users.update({_id: req.user._id}, {$set : {'providers.github': req.user.providers.github}}, {}, function() {
        done(null, req.user);
      });
    }
  }
);
passport.use('github', exports.githubStrategy);

exports.linkedinStrategy = new (require('passport-linkedin').Strategy)({
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
passport.use('linkedin', exports.linkedinStrategy);

exports.movesStrategy = new (require('./passport-moves').Strategy)({
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
        exports.movesStrategy._oauth2.get('https://api.moves-app.com/api/1.1/user/summary/daily?pastDays=2', accessToken, function(err, data) {
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
passport.use('moves', exports.movesStrategy);

exports.ensureAuthenticated = function ensureAuthenticated(req, res, next) {
  if (req.isAuthenticated()) {
    return next();
  }
  res.redirect('/login');
};
