exports.options = {
  docker: {
    imageName: 'couchbase'
  },
  files:  [
    '.'
  ]
};

exports.addCustomTasks = function(gulp) {
  var shell = require('gulp-shell'),
    watch = require('gulp-watch');

  gulp.task('example:shell', function() {
    return gulp.src('', {read: false})
      .pipe(shell([
        ['echo This is a shell command']
      ]));
  });

  gulp.task('example:watch', function() {
    gulp.src('**/*.js')
      .pipe(watch(function(files) {
        return files.pipe(shell('echo This runs on watch'));
      }));
  });
};
