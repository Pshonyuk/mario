+function(){
	QUnit.module("events");
	// Mario.destroyAll();


	Mario("events", {
		"e": "sv",
		'cv': {
			constantValue: true,
			value: 5
		},
		"cf":{
			react:{
				fields: "cv",
				compute: function(){
					return "cf";
				}
			}
		},
		"cfns":{
			react:{
				fields: "cv",
				staticValue: false,
				compute: function(){
					return "cfns";
				}
			}
		}
	});



	QUnit.test("change", function(assert){
		var m = Mario.mixin("events");

		m.one("change:e", function(newValue, oldValue){
			assert.equal(newValue, "nv", "onChage after set");
		});
		m.set("e", "nv");

		var count = 0, r;
		m.on("change:e", r = function(newValue, oldValue){
			count++;
		});
		m.off("change : e", r);
		m.trigger("change:e", "nv");
		assert.equal(count, 0, "offChage && trigger");

		m.on("change:e", r = function(newValue, oldValue){
			assert.ok(newValue === 25 && !count, "offChage && set");
		});
		m.set("e", 25);

		var mCount = 0;
		m.on("change:cv", function(){
			mCount++;
		});
		m.set("cv", 666);
		assert.equal(mCount, 0, "change constant");

		var fCount = 0;
		m.one("change:cf", function(){
			fCount++;
		});
		m.set("cv", 666);
		assert.equal(fCount, 0, "change constant static compute field");

		fCount = 0;
		m.one("change:cfns", function(){
			fCount++;
		});
		m.set("cfns", 666);
		assert.equal(fCount, 1, "change constant compute field");
	});


	// QUnit.test("set", function(assert){
	// 	var m = Mario.mixin("events");

	// 	m.set("e", 5)
	// 	m.one("set:e", function(newValue, oldValue, arg){
	// 		assert.ok(newValue === "nv" && oldValue === 5 && arg === 45, "onSet in general");
	// 	});
	// 	m.set("e", "nv", 45);

	// 	var mCount = 0;
	// 	m.on("set:cv", function(){
	// 		mCount++;
	// 	});
	// 	m.set("cv", 666);
	// 	assert.equal(mCount, 0, "set constant");

	// 	var fCount = 0;
	// 	m.one("set:cf", function(){
	// 		fCount++;
	// 	});
	// 	m.set("cv", 666);
	// 	assert.equal(fCount, 0, "set constant static compute field");

	// 	fCount = 0;
	// 	m.one("set:cfns", function(){
	// 		fCount++;
	// 	});
	// 	m.set("cfns", 666);
	// 	assert.equal(fCount, 1, "set constant compute field");
	// });


	// QUnit.test("get", function(assert){
	// 	var m = Mario.mixin("events");

	// 	m.one("get:e", function(value, arg){
	// 		assert.ok(value === "sv" && arg === 5, "onGet in general");
	// 	});
	// 	m.get("e", 5);

	// 	m.one("get:cv", function(value){
	// 		assert.equal(value, 5, "get constant");
	// 	});
	// 	m.get("cv");

	// 	m.one("get:cf", function(value){
	// 		assert.equal(value, "cf", "get static compute field");
	// 	});
	// 	m.get("cf");

	// 	m.one("get:cfns", function(value){
	// 		assert.equal(value, "cfns", "get compute field");
	// 	});
	// 	m.get("cfns");
	// });
}();