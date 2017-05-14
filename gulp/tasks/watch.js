"use strict";
var gulp = require("gulp"),
	cache = require("gulp-cached"),
	remember = require("gulp-remember");


module.exports = function(args){
	return function(){
		gulp.watch(args.src, gulp.series(args.taskName))
			.on('change', function (event) {
				if (event.type === "deleted") {
					delete cache.caches[args.taskName][event.path];
					remember.forget(args.taskName, event.path);
				}
			});
	};
};