/*jshint node:true*/

module.exports = function (grunt) {

	'use strict';

	// show elapsed time at the end
	require('time-grunt')(grunt);

	// load all grunt tasks
	require('load-grunt-tasks')(grunt);

	grunt.initConfig({

		config: {
			src: 'app/public/src',
			dist: 'app/public',
			images: 'bin'
		},

		watch: {
			js: {
				files: ['<%= config.src %>/scripts/*.coffee'],
				tasks: ['coffee:dev'],
				options: {
					spawn: false,
					interrupt: true
				},
			},
			less: {
				files: ['<%= config.src %>/styles/*.less'],
				tasks: ['less:dev'],
				options: {
					spawn: false,
					interrupt: true
				},
			}
		},

		imagemin: {
			dist: {
				files: [{
					expand: true,
					cwd: '<%= config.src %>/<%= config.images %>',
					src: '{,*/}*.{gif,jpeg,jpg,png}',
					dest: '<%= config.dist %>/<%= config.images %>'
				}]
			}
		},

		svgmin: {
			dist: {
				files: [{
					expand: true,
					cwd: '<%= config.src %>/<%= config.images %>',
					src: '{,*/}*.svg',
					dest: '<%= config.dist %>/<%= config.images %>'
				}]
			}
		},

		copy: {
			dist: {
				files: [{
					expand: true,
					dot: true,
					cwd: '<%= config.src %>',
					dest: '<%= config.dist %>',
					src: [
						'*.{ico,png,txt,xml}',
						'<%= config.images %>/{,*/}*.{webp,gif}',
						'fonts/{,*/}*.*'
					]
				}]
			}
		},

		coffee: {
          dev: {
            options: {
              sourceMap: true
            },
            files: {
              '<%= config.dist %>/scripts/script.js': ['<%= config.src %>/scripts/*.coffee'] // compile and concat into single file
            }
          },
          dist: {
            files: {
              '<%= config.dist %>/scripts/script.js': ['<%= config.src %>/scripts/*.coffee'] // compile and concat into single file
            }
          },
        },

		less: {
			dev: {
				options: {
					sourceMap: true
				},
				files: {
					'<%= config.dist %>/styles/styles.css': '<%= config.src %>/styles/styles.less'
				}
			},
			dist: {
				options: {
					compress: true,
					report: true
				},
				files: {
					'<%= config.dist %>/styles/styles.css': '<%= config.src %>/styles/styles.less'
				}
			}
		}

	});

	// Tasks.
	grunt.registerTask('default', ['build']);

	grunt.registerTask('build', [
        'less:dist',
		'coffee:dist',
		'copy:dist',
		'watch'
	]);

	grunt.registerTask('serve', function (target) {

		if (target === 'build') {
			return grunt.task.run(['build', 'connect:dist:keepalive']);
		}

		grunt.task.run([
			'less:dev',
			'coffee:dev',
			'watch'
		]);
	});

};
