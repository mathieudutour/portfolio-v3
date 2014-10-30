/*jshint node: true*/
var express = require('express');
var session = require('express-session');
var bodyParser = require('body-parser');
var passport = require('passport');

var app = express();
var router = require('./app/controllers');


app.engine('html', require('ejs').renderFile);
app.set('views', './app/views');
app.set('view engine', 'ejs');
app.set('port', (process.env.PORT || 5000));

var options = {
  dotfiles: 'ignore',
  etag: false,
  index: false,
  maxAge: '0',
  redirect: false
};

app.use(express.static('app/public', options));
//app.use(express.cookieParser());
// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));
// parse application/json
app.use(bodyParser.json());
app.use(session({ secret: 'keyboard cat' }));
app.use(passport.initialize());
app.use(passport.session());
app.use(router.router);

var server = app.listen(app.get('port'), function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Portfolio app listening at http://%s:%s', host, port);

});
