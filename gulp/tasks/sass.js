var gulp = require("gulp"),
	debug = require("gulp-debug"),
	gulpIf = require("gulp-if"),
	rename = require("gulp-rename"),
	notify = require("gulp-notify"),
	uglify = require("gulp-uglifycss"),
	combiner = require("stream-combiner2").obj,
	sass = require("gulp-sass");


module.exports = function(args){
	return function (done) {
		var dev = process.env.NODE_ENV !== "production";
		
		combiner(
			gulp.src(args.entryPoint),
			sass(),
			gulp.dest(args.distFolder),
			gulpIf(!dev, combiner(
				uglify({
					"maxLineLen": 80,
					"uglyComments": true
				}),
				debug({title: "Uglify"}),
				rename({suffix: ".min"}),
				debug({title: "RenameUglify"}),
				gulp.dest(args.distFolder),
				debug({title: "DestUglify"})
			))
		).on("error", notify.onError());
		done();
	}
};