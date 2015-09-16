#!/usr/bin/env node

require('coffee-script/register');
module.exports = require(__dirname+'/src/http-tail.coffee');
