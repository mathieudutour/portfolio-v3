/*jshint node: true*/
var router = require('express').Router();
var passport = require('passport');
var gravatar = require('gravatar');
var sha1 = require('sha1');
var db = require('../models/').db;
var request = require('request');

var getLogin = function (req, res) {
  res.render('login.html', {signup : req.query.signup});
};

var login = function (req, res, next) {
  passport.authenticate('local', function (err, user, info) {
    if (err) {
      req.session.error = err.message;
      return res.redirect('/login');
    }
    if (!user) {
      req.session.error = info.message;
      return res.redirect('/login');
    }
    req.logIn(user, function (err) {
      if (err) {
        return next(err);
      }
      return res.redirect('/admin');
    });
  })(req, res, next);
};

// parse a date in dd/mm/yyyy format
function parseDate(input) {
  var re = /^[0-3][0-9][\/][0-1][0-9][\/][1-2][0-9]{3}$/;
  if(re.test(input)) {
    var parts = input.split('/');
    // new Date(year, month [, day [, hours[, minutes[, seconds[, ms]]]]])
    return new Date(parts[2], parts[1]-1, parts[0]); // Note: months are 0-based
  } else {
    return undefined;
  }
}

function checkSlug(input) {
  var re = /^[a-z0-9\-]*$/;
  return re.test(input);
}

var signup = function (req, res, next) {
  if (req.body.first_name.length < 2) {
    req.session.error = "Your first name must be more than 1 character.";
    return res.redirect('/login?signup=true');
  }
  if (req.body.last_name.length < 2) {
    req.session.error = "Your last name must be more than 1 character.";
    return res.redirect('/login?signup=true');
  }
  if (req.body.password.length < 6) {
    req.session.error = "Your password must be more than 5 character.";
    return res.redirect('/login?signup=true');
  }
  if (req.body.slug_name.length < 2) {
    req.session.error = "Your slug name must be more than 1 character.";
    return res.redirect('/login?signup=true');
  }
  if (!checkSlug(req.body.slug_name)) {
    req.session.error = "Your slug name is not sluggish.";
    return res.redirect('/login?signup=true');
  }
  var date = parseDate(req.body.birthday.trim());
  if(!date) {
    req.session.error = "Wrong format for your birthday.";
    return res.redirect('/login?signup=true');
  }
  var grav = gravatar.url(req.body.email, {s:500, d: '404'});
  request(grav, function (error, response) {
    var user;
    if (!error && response.statusCode == 200) {
      user = {
        email : req.body.email,
        password : sha1(req.body.password),
        slug_name : req.body.slug_name,
        providers : {
          basic : {
            first_name : req.body.first_name,
            last_name : req.body.last_name,
            birthday : date,
            email : req.body.email,
            avatar_provider : 'gravatar',
            avatar : gravatar.url(req.body.email, {s:500})
          },
          gravatar : {
            image : gravatar.url(req.body.email, {s:500})
          },
          linkedin : null,
          facebook : null,
          twitter : null,
          github : null,
          strava : null,
          moves : null,
          other_sport : null,
          other_last : null,
          projects : null,
          diplomas : null,
          sleep : null,
          heartrate : null,
          rescuetime : null
        }
      };
    } else {
      user = {
        email : req.body.email,
        password : sha1(req.body.password),
        slug_name : req.body.slug_name,
        providers : {
          basic : {
            first_name : req.body.first_name,
            last_name : req.body.last_name,
            birthday : date,
            email : req.body.email,
            avatar_provider : null,
            avatar : gravatar.url(req.body.email, {s:500})
          },
          gravatar : {
            image : gravatar.url(req.body.email, {s:500})
          },
          linkedin : null,
          facebook : null,
          twitter : null,
          github : null,
          strava : null,
          moves : null,
          other_sport : null,
          other_last : null,
          projects : null,
          diplomas : null,
          sleep : null,
          heartrate : null,
          rescuetime : null
        }
      };
    }
    db.users.insert(user, function (err, result) {
      if (err) {
        console.log(err);
        req.session.error = err.message;
        return res.redirect('/login?signup=true');
      } else {
        req.logIn(result, function (err) {
          if (err) {
            return next(err);
          }
          return res.redirect('/admin');
        });
      }
    });
  });
};

router.get('/login', getLogin);
router.post('/login', login);
router.post('/signup', signup);

exports.router = router;
