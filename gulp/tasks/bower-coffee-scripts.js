var gulp = require("gulp"),
	coffee = require("gulp-coffee"),
	concat = require("gulp-concat"),
	debug = require("gulp-debug"),
	gulpIf = require("gulp-if"),
	uglify = require("gulp-uglify"),
	rename = require("gulp-rename"),
	notify = require("gulp-notify"),
	source = require("vinyl-source-stream"),
	combiner = require("stream-combiner2").obj,
	sourcemaps = require("gulp-sourcemaps"),
	browserify = require("browserify"),
	vinylBuffer = require("vinyl-buffer");



module.exports = function(args){
	return function(done){
		var dev = process.env.NODE_ENV !== "production";
		var stream = browserify({
			"extensions"	: [".coffee"],
			"transform"		: ["coffeeify"],
			"entries"		: [args.entryPoint],
			"debug"			: true
		})
			.bundle();

		combiner(
			stream,
			source(args.distFile),
			debug({title: "Source"}),
			gulp.dest(args.distFolder),
			gulpIf(!dev, combiner(
				vinylBuffer(),
				uglify(args.distFile),
				debug({title: "Uglify"}),
				rename({suffix: ".min"}),
				debug({title: "RenameUglify"}),
				gulp.dest(args.distFolder),
				debug({title: "DestUglify"})
			))
		).on("error", notify.onError());
		done();
	};
};