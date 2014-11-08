/*jshint node: true*/
var router = require('express').Router();
var strategies = require('./strategies');

router.get('/', require('./home').controller);
router.use('/', require('./login').router);
router.use('/admin', strategies.ensureAuthenticated, require('./admin').router);
router.get('/:slug', require('./home').controller);

exports.router = router;
