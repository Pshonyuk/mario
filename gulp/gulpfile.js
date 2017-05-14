"use strict";
var gulp = require("gulp"),
	util = require("gulp-util"),
	debug = require("gulp-debug"),
	remember = require("gulp-remember");


var	scriptsTaskCreator = require("./tasks/bower-coffee-scripts.js"),
	watchTaskCreator = require("./tasks/watch.js"),
	scripts = [
		{
			watcherSrc	: "../src/**/*.coffee",
			entryPoint	: "../src/mario.coffee",
			distFolder	: (process.env.DEV_ENV === "katana" ? "/var/www/html/hg_plugin/wp-content/plugins/katana/app/options/js/vendor/libraries/" : null),
			taskName	: "scripts:mario",
			distFile	: "mariojs.js"
		}
	],
	paths = {
		"distJSFolder"	: "../build/"
	};


/*
 *COFFEE-SCRIPT TASKS
 */
gulp.task("scripts", function(done){
	var i, l, task, tasks = [];
	for(i = 0, l = scripts.length; i < l; i++){
		task = scripts[i];
		tasks.push(task.taskName);
		gulp.task(task.taskName, scriptsTaskCreator({
			"distFolder"	: task.distFolder || paths.distJSFolder,
			"entryPoint"	: task.entryPoint,
			"distFile"		: task.distFile
		}));
	}
	return gulp.parallel(tasks)(done);
});


gulp.task("watch:coffee", function(done){
	var i, l, task;
	for(i = 0, l = scripts.length; i < l; i++){
		task = scripts[i];
		watchTaskCreator({
			"taskName"	: task.taskName,
			"src"		: task.watcherSrc
		})();
	}
	done();
});



gulp.task("default", gulp.parallel("scripts"));
gulp.task("dev", gulp.series("scripts", "watch:coffee"));