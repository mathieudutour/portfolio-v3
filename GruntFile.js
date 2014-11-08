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
		},

        uglify: {
            dist: {
                files: {
                  '<%= config.dist %>/scripts/script.min.js': ['<%= config.dist %>/scripts/script.js']
                }
            }
        }

	});

	// Tasks.
	grunt.registerTask('default', ['dist']);

	grunt.registerTask('dist', [
        'less:dist',
		'coffee:dist',
        'uglify:dist',
		'watch'
	]);

	grunt.registerTask('dev', [
			'less:dev',
			'coffee:dev',
			'watch'
    ]);

};
