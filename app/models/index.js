/*jshint node: true*/
var Datastore = require('nedb');
var db = {};

db.users = new Datastore({filename : './app/models/users.db', autoload : true});
db.users.ensureIndex({ fieldName: 'slug_name', unique: true });
db.users.ensureIndex({ fieldName: 'email', unique: true });

exports.db = db;
