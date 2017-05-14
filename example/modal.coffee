$ = jQuery
_CONST = require "./default-arguments.coffee"



getAction = (actions, name)->
	for action in actions
		return action if action.name is name
	return null



Mario "wap-modal", {
	"root":
		constantValue: true
		construct: ->
			return $ _CONST.ROOT_EL


	"content":
		deps: "root"
		setter: (value, root)->
			return root.find(".#{_CONST.CONTENT_CLASS_NAME}").html value


	"container":
		deps: "root"
		setter: (cnt, root)->
			$cnt = $ cnt
			$cnt.prepend root
			return $cnt


	"overlay":
		deps: "root"
		value: ".#{_CONST.OVERLAY_CLASS_NAME}"
		depsInGetter: true
		constantValue: true
		getter: (className, root)->
			return root.find className


	"message":
		deps: "root"
		value: ".#{_CONST.MESSAGE_CLASS_NAME}"
		depsInGetter: true
		constantValue: true
		getter: (className, root)->
			return root.find className


	"transform":
		deps: "root"
		value: ".#{_CONST.TRANSFORM_CLASS_NAME}"
		depsInGetter: true
		constantValue: true
		getter: (className, root)->
			return root.find className


	"footer":
		deps: "root"
		value: ".#{_CONST.FOOTER_CLASS_NAME}"
		depsInGetter: true
		constantValue: true
		getter: (className, root)->
			return root.find className


	"closeClassName":
		value: null
		constantValue: true


	"colCount":
		deps: "message"
		value: 4
		prepare: Mario.transforms("toNumber")
		setter: (colCount, message, oldColCount)->
			colWidth = $(document.body).width() / 5
			if colWidth
				message.css "width", colCount*colWidth
				return colCount
			return oldColCount


	"blurContainer":
		setter: (cnt)->
			return if cnt then $(cnt) else null


	"position":
		value: "center-center"
		prepare: Mario.filters("anyMatch", [
			"top-center"
			"top-right"
			"center-left"
			"center-center"
			"center-right"
			"bottom-left"
			"bottom-center"
			"bottom-right"
			"auto"
		])


	"showState":
		deps: ["root", "blurContainer", "closeClassName", "blur"] 
		value: false
		prepare: Mario.transforms("toBoolean")
		setter:(state, root, blurContainer, closeClassName, blur)->
			if !state
				root.fadeOut()
				root.addClass closeClassName
				if blurContainer && blur
					blurContainer.removeClass _CONST.BLUR_CLASS_NAME
			else
				root.fadeIn()
				root.removeClass @_closeClassName
				if blurContainer && blur
					blurContainer.addClass _CONST.BLUR_CLASS_NAME
			return state


	"callerButton":
		prepare: Mario.filters("isObject")
		value: null


	"updatePosition":
		react:
			fields: ["position", "showState", "callerButton", "colCount"]
			compute: (modalPosition, showState, btn)->
				return if !showState || !btn || !btn.length
				transform = @get "transform"
				modalWrap = panel = @get "root"
				modal = @get "message"

				panelWidth = panel.width()
				panelHeight = panel.height()
				panelIndent = 22
				windowHeight = $(window).height()
				modalHeight = modal.height()
				modalWidth = modal.width()
				scrollTop = $(document.body).scrollTop()
				btnOffset = btn.offset()
				btnHeight = btn.outerHeight()
				btnWidth = btn.outerWidth()

				if scrollTop > panelIndent
					top = scrollTop - panelIndent
				else
					top = 0

				if scrollTop < panelIndent
					windowHeight = windowHeight + scrollTop - panelIndent
				else if scrollTop + windowHeight > panelHeight + panelIndent
					windowHeight = panelIndent + panelHeight - scrollTop

				#Modal Position
				switch modalPosition
					when "top-center"
						modalLeft = (panelWidth - modalWidth) / 2
						modalTop = top
						break
					when "top-right"
						modalLeft = panelWidth - modalWidth
						modalTop = top
						break
					when "center-left"
						modalLeft = 0
						modalTop = top + ((windowHeight - modalHeight) / 2)
						break
					when "center-center"
						modalLeft = (panelWidth - modalWidth) / 2
						modalTop = top + ((windowHeight - modalHeight) / 2)
						break
					when "center-right"
						modalLeft = panelWidth - modalWidth
						modalTop = top + ((windowHeight - modalHeight) / 2)
						break
					when "bottom-left"
						modalLeft = 0
						modalTop = top + windowHeight - modalHeight
						break
					when "bottom-center"
						modalLeft = (panelWidth - modalWidth) / 2
						modalTop = top + windowHeight - modalHeight
						break
					when "bottom-right"
						modalLeft = panelWidth - modalWidth
						modalTop = top + windowHeight - modalHeight
						break
					when "auto"
						modalLeft = btnOffset.left - panelIndent
						modalTop = btnOffset.top - panelIndent
						beforeHeight = modalTop - top - panelIndent
						afterHeight = top + $(window).height() - modalTop - btnHeight - panelIndent

						#Horizontal align
						if modalLeft + modalWidth >= panelWidth
							modalLeft = panelWidth - modalWidth

						#Vertical align
						if beforeHeight >= modalHeight
							modalTop = modalTop - modalHeight - panelIndent
						else if afterHeight >= modalHeight
							modalTop = modalTop + panelIndent + btnHeight
						else if beforeHeight >= afterHeight
							modal.css "height", beforeHeight
							modalTop = modalTop - beforeHeight - panelIndent
						else
							modal.css "height", afterHeight
							modalTop = modalTop + panelIndent + btnHeight
						break
					else
						modal.css "top", top
						break


				modal.css {
					left : modalLeft
					top  : modalTop
				}

				transform.css({
					"background": btn.data "hoverColor"
					"height"	: btnHeight
					"width"		: btnWidth
					"left"		: btnOffset.left - panelIndent
					"top"		: btnOffset.top - panelIndent
				}).data {
					"background": btn.data "hoverColor"
					"height"	: btnHeight
					"width"		: btnWidth
					"left"		: btnOffset.left - panelIndent
					"top"		: btnOffset.top - panelIndent
					"btn"		: btn
				}

				setTimeout ->
					transform.css({
						"background": "#fff"
						"height"	: modal.height()
						"width"		: modal.width()
						"left"		: modalLeft
						"top"		: modalTop
					}).addClass "transform"

					setTimeout ->
						modalWrap.addClass "active"
					, 200
				, 100

				modal.find(".circle").css {
					height : 0
					width : 0
				}
				return


	"actionsStorage":
		constantValue: true
		value: []


	"actions":
		deps: ["footer", "actionsStorage"]
		prepare: [
			Mario.filters("anyFilterMatch", [
				Mario.filters("isString")
				Mario.filters("isArray")
			])
		]
		value: [
			{
				"controller": _CONST.ACTION_HANDLER
				"title"		: "Cancel"
				"name"		: "cancel"
				"box"		: _CONST.BUTTONS.DEFAULT
			}
			{
				"controller": _CONST.ACTION_HANDLER
				"title" 	: "Save"
				"name"		: "save"
				"box"		: _CONST.BUTTONS.SUCCESS
			}
		]

		setter: (newActions, footer, actionsStorage)->
			_.isArray(newActions) || (newActions = [newActions])
			for action in newActions
				continue if getAction(actionsStorage, action.name)
				$box = $ action.box
				continue if !$box.length
				title = action.title || ""
				$box.addClass _CONST.ACTION_CLASS_NAME 
				$box.find("." + _CONST.ACTION_TITLE_CLASS_NAME).text title
				footer.append $box
				actionsStorage.push $box[0].wapModalAction = {
					"controller": action.controller
					"freeze"	: action.freeze
					"title" 	: title
					"name"		: action.name
					"box"		: $box
				}
			return


	"overlayHandler":
		prepare: Mario.filters("isFunction")
		value: _CONST.ACTION_HANDLER


	"overlayColor":
		value: "#000"


	"blur":
		value: true
		prepare: Mario.transforms("toBoolean")


	"result": null
}