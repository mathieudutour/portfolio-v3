/*jshint node: true*/
var router = require('express').Router();
var passport = require('passport');
var gravatar = require('gravatar');
var Cron = require('cron').CronJob;
var sha1 = require('sha1');
var db = require('../models/').db;


// Rescue Time : B63P6JWu25f2wNujn_9KGrrmzukFTii1656Aelms

var controller = function (req, res, next) {
  db.providers.findOne({name:'basic'}, function(err, doc) {
    if(err) {return next(err);}
    if(doc) {
      res.render('admin.html');
    } else {
      res.render('adminInscription.html');
    }
  });
};

var inscription = function (req, res) {
  if(req.body.firstname && req.body.lastname && req.body.email && req.body.password) {
    db.providers.insert({name:'basic', firstname: req.body.firstname, lastname: req.body.lastname, email: req.body.email, avatar: gravatar.url(req.body.email, {s:500}), password: sha1(req.body.password)}, function () {
      res.redirect('/admin');
    });
  } else {
    res.redirect('/admin');
  }
};

var facebookStrategy = new (require('passport-facebook').Strategy)({
  clientID: '346040448909652',
  clientSecret: 'bd815c44db5cff3437d71af27c8bc69f',
  callbackURL: 'http://localhost:3000/admin/auth/facebook/callback'
  },
  function(accessToken, refreshToken, profile, done) {
    db.providers.update({name: profile.provider}, {name: profile.provider, accessToken: accessToken, refreshToken: refreshToken, link: profile._json.link, _raw: profile._json}, {upsert: true}, function() {
      done(null, profile);
    });
  }
);

var stravaStrategy = new (require('passport-strava').Strategy)({
  clientID: '3439',
  clientSecret: '8b60bd2e5797d8e327fc8ed1055e9c990c64b46b',
  callbackURL: 'http://localhost:3000/admin/auth/strava/callback'
  },
  function(accessToken, refreshToken, profile, done) {
    db.providers.update({name: profile.provider}, {name: profile.provider, accessToken: accessToken, refreshToken: refreshToken, link: "http://www.strava.com/athletes/" + profile.id, _raw: profile._json}, {upsert: true}, function() {
      done(null, profile);
    });
  }
);

var twitterStrategy = new (require('passport-twitter').Strategy)({
  consumerKey: 'lgiadg6aHE9hp5ga75TrKhil2',
  consumerSecret: 'S6Wtwc6dONJ24VaM518BqLZmLBIAaTIqMVemKgjqN8iiPG09J3',
  callbackURL: 'http://localhost:3000/admin/auth/twitter/callback'
  },
  function(token, tokenSecret, profile, done) {
    db.providers.update({name: profile.provider}, {name: profile.provider, accessToken: token, tokenSecret: tokenSecret, link: "https://twitter.com/" + profile._json.screen_name, _raw: profile._json}, {upsert: true}, function() {
      twitterStrategy._oauth.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=1', token, tokenSecret, function(err, data) {
          if(err) {return console.log(err);}
          data = JSON.parse(data);
          db.providers.update({name: "twitter"}, {$set: {lastTweet: data[0].text}}, function() {});
        });
      done(null, profile);
    });
  }
);

var githubStrategy = new (require('passport-github').Strategy)({
  clientID: 'bde1aa08409be679edd9',
  clientSecret: 'af7b325388f315b48999f2560f39f312d43fb474',
  callbackURL: 'http://localhost:3000/admin/auth/github/callback'
  },
  function(accessToken, refreshToken, profile, done) {
    db.providers.update({name: profile.provider}, {name: profile.provider, accessToken: accessToken, refreshToken: refreshToken, link: profile._json.html_url, _raw: profile._json}, {upsert: true}, function() {
      done(null, profile);
    });
  }
);

var linkedinStrategy = new (require('passport-linkedin').Strategy)({
  consumerKey: '75jl1oy2kd1jzp',
  consumerSecret: 'iybnchpVIC10SfU9',
  callbackURL: 'http://localhost:3000/admin/auth/linkedin/callback'
  },
  function(token, tokenSecret, profile, done) {
    db.providers.update({name: profile.provider}, {name: profile.provider, accessToken: token, tokenSecret: tokenSecret, link: "http://www.linkedin.com/profile/view?id=" + profile.id, _raw: profile._json}, {upsert: true}, function() {
      done(null, profile);
    });
  }
);

passport.use('facebook', facebookStrategy);
passport.use('strava',stravaStrategy);
passport.use('twitter',twitterStrategy);
passport.use('github',githubStrategy);
passport.use('linkedin',linkedinStrategy);

new Cron({
  cronTime: '00 * * * * *',
  onTick: function() {
    db.providers.findOne({name:'twitter'}, function(err, doc) {
      if(err) {return console.log(err);}
      if(doc) {
        twitterStrategy._oauth.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=1', doc.accessToken, doc.tokenSecret, function(err, data) {
          if(err) {return console.log(err);}
          data = JSON.parse(data);
          db.providers.update({name: "twitter"}, {$set: {lastTweet: data[0].text}}, function() {});
        });
      } else {
        return console.log("Twitter not configured yet");
      }
    });
  },
  start: true
});

router.get('/', controller);
router.post('/', inscription);
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

exports.router = router;
