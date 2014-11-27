/*jshint node: true*/
var config = require('../config/').config;
var Datastore = require('monk')(config.dbURI);
var db = {};

db.users = Datastore.get('users');
db.users.index('slug_name', {unique: true });
db.users.index('email', {unique: true });
db.positions = Datastore.get('positions');
db.positions.index('user');

exports.db = db;
