/*jshint node: true*/
var express = require('express');
var session = require('express-session');
var bodyParser = require('body-parser')
var passport = require('passport');

var app = express();
var router = require('./controllers');


app.engine('html', require('ejs').renderFile);
app.set('views', './views');
app.set('view engine', 'ejs');

var options = {
  dotfiles: 'ignore',
  etag: false,
  index: false,
  maxAge: '0',
  redirect: false
};

app.use(express.static('public', options));
//app.use(express.cookieParser());
// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));
// parse application/json
app.use(bodyParser.json());
app.use(session({ secret: 'keyboard cat' }));
app.use(passport.initialize());
app.use(passport.session());
app.use(router.router);

var server = app.listen(3000, 'localhost', function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Portfolio app listening at http://%s:%s', host, port);

});