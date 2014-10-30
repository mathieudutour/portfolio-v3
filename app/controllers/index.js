/*jshint node: true*/
var router = require('express').Router();

router.get('/', require('./home').controller);
router.use('/admin', require('./admin').router);

exports.router = router;
