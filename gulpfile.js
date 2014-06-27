var gulp = require('gulp');
var join = require('path').join;
var gulpShared = require('connected-boiler-shared/gulpfile.js');
var config = require(join(__dirname, '/test/gulpLocalConfig.js'));

gulp = gulpShared.runner(gulp, config.options);

// add any extra gulp tasks in test/gulpLocalConfig.js

config.addCustomTasks(gulp);
