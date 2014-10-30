/*jshint node: true*/
var Datastore = require('nedb');
var db = {};

db.providers = new Datastore({filename : './app/models/providers.db', autoload : true});

db.providers.ensureIndex({ fieldName: 'name', unique: true });

exports.db = db;
