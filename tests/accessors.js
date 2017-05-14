+function(){
	QUnit.module("accessors");
	Mario.destroyAll();



	Mario("accessors2", {
		"r1": {
			react: {
				staticValue: false,
				fields: ["a", "b"],
				compute: function(a, b){
					return a*b;
				}
			}
		},
		"a": 2,
		"b": 3
	});
	var m2 = Mario.mixin("accessors2");


	Mario("accessors", {
		simple: "sv",
		general: {
			value: "gv"
		},
		constantValue: {
			constantValue: true,
			value: "cv"
		},
		computeValue: {
			react:{
				fields: ["simple", "general"],
				compute: function(simple, general){
					return simple + general;
				}
			}
		},
		notStatiComputeValue: {
			react:{
				staticValue: true,
				fields: ["simple", "general"],
				compute: function(simple, general){
					return "staticComputeValue";
				}
			}
		},
		tConstruct:{
			value: "init",
			construct: function(){
				return "construct";
			}
		},
		tnrConstruct:{
			value: "init",
			construct: function(){
			}
		},
		tdConstruct:{
			deps: ["tConstruct", "ugConstant"],
			value: "init",
			construct: function(tConstruct, ugConstant){
				return tConstruct + ugConstant;
			}
		},
		usGeneral:{
			value: "default",
			setter: function(newValue, oldValue){
				return newValue + "," + oldValue;
			}
		},
		ugGeneral:{
			value: "default",
			setter: function(newValue, oldValue){
				return newValue + " " + oldValue;
			},
			getter: function(value){
				return value + value;
			}
		},
		usConstant:{
			constantValue: true,
			value: "cv",
			setter: function(newValue, oldValue){
				return newValue;
			}
		},
		ugConstant:{
			constantValue: true,
			value: "cv",
			getter: function(value){
				return "cnv";
			}
		},
		usStatic:{
			react:{
				fields: ["usConstant"],
				compute: function(usConstant, simple){
					return usConstant;
				}
			},
			setter: function(newValue, oldValue){
				return "cnv";
			}
		},
		ugStatic:{
			react:{
				fields: ["ugConstant"],
				compute: function(ugConstant){
					return ugConstant;
				}
			},
			getter: function(value){
				return "cnv";
			}
		},
		dValue: {
			deps: ["dValue0"],
			value: 0,
			setter: function(newValue, dValue0){
				return dValue0;
			}
		},
		dValue1:{
			value: 2
		},
		dValue0: {
			value: 1,
			deps: ["dValue1"],
			depsInGetter: true,
			getter: function(value, dValue1){
				return dValue1;
			}
		},
		"cfv1": 1,
		cft: {
			react: {
				fields: ["cfvc", "cfv1", "cfv2", "cf3", "cf30", [m2, "r1"]],
				compute: function(){
					var args = Array.prototype.slice.call(arguments, 0, -1);
					return args.join(",");
				}
			}
		},
		cfv2: {
			value: 5,
			construct: function(value){
				return value*value;
			}
		},
		cf3: {
			react:{
				fields: "cf30",
				compute: function(cf30){
					return "0" + cf30;
				}
			}
		},
		cf30: {
			value: 7,
			setter: function(newValue){
				return newValue;
			}
		},
		"cfvc": {
			constantValue: true,
			value: 9
		}
	});


	QUnit.test("getter", function (assert) {
		var m = Mario.mixin("accessors");
		assert.equal(m.get("simple"), "sv", "not object notation properties");
		assert.equal(m.get("general"), "gv", "object notation properties");
		assert.equal(m.get("constantValue"), "cv", "constant value");
		assert.equal(m.get("computeValue"), "svgv", "compute field'");

	});


	QUnit.test("setter", function (assert) {
		var m = Mario.mixin("accessors");
		assert.equal(m.set("simple", "nsv").get("simple"), "nsv", "not object notation properties");
		assert.equal(m.set("general", "newGeneralValue").get("general"), "newGeneralValue", "object notation properties");
		assert.notEqual(m.set("constantValue", "ncv").get("cv"), "ncv", "constant value");
		assert.equal(m.set("computeValue", "ncv").get("computeValue"), "ncv", "compute field'");
	});



	QUnit.test("userDefine", function (assert) {
		var m = Mario.mixin("accessors");
		assert.equal(m.set("usGeneral", "newValue").get("usGeneral"), "newValue,default,undefined", "user setter");
		assert.equal(m.get("ugGeneral"), "default undefineddefault undefined", "user getter (before-set)");
		assert.equal(m.set("ugGeneral", " ").get("ugGeneral"), "  default undefined  default undefined", "user getter (after-set)");
		assert.notEqual(m.set("usConstant", 23).get("usConstant"), 23, "userSetter in constant");
		assert.equal(m.get("ugConstant"), "cnv", "userGetter in constant");
		assert.notEqual(m.set("usStatic", "test").get("usStatic"), "test", "userSetter in static");
		assert.equal(m.get("ugConstant"), "cnv", "userGetter in static");
	});



	QUnit.test("construct", function(assert) {
		var m = Mario.mixin("accessors");
		assert.ok(true, "");
		assert.equal(m.get("tConstruct"), "construct", "construct return value");
		assert.equal(m.get("tnrConstruct"), void 0, "construct not return value");
		assert.equal(m.get("tdConstruct"), "constructcnv", "construct depenedents");
	});


	QUnit.test("computeField", function(assert) {
		var m = Mario.mixin("accessors");
		assert.equal(m.get("cft"), "9,1,25,07,7,6", "first get");
		m.set("cf30", 8);
		assert.equal(m.get("cft"), "9,1,25,08,8,6", "change dependent computeField");
		m2.set("b", 10);
		assert.equal(m.get("cft"), "9,1,25,08,8,20", "change dependent computeField (outside)");
		m.set("cfv2", 4);
		assert.equal(m.get("cft"), "9,1,4,08,8,20", "set dependent value");
		m2.set("r1", 10);
		assert.equal(m.get("cft"), "9,1,4,08,8,10", "set dependent staticComputeValue");
	});


	QUnit.test("depenedents", function(assert){
		var m = Mario.mixin("accessors");
		assert.equal(m.set("dValue", 14).get("dValue"), 2, "depenedents in getter");
		assert.equal(m.get("dValue0"), 2, "depenedents in getter");
	});
}();