extends GutTest

# Tests for UIToast component


func test_toast_can_be_instantiated():
	var toast = UIToast.new()
	add_child_autofree(toast)
	await get_tree().process_frame
	assert_not_null(toast, "UIToast should instantiate")
	assert_true(toast.has_method("show_toast"), "Should expose show_toast")
	assert_true(toast.has_method("show_loot"), "Should expose show_loot")
	assert_true(toast.has_method("show_level_up"), "Should expose show_level_up")


func test_show_toast_makes_visible():
	var toast = UIToast.new()
	add_child_autofree(toast)
	await get_tree().process_frame
	toast.show_toast("Test message", UIToast.Kind.INFO, 0.3)
	await get_tree().process_frame
	assert_true(toast.visible, "Toast should be visible while showing")


func test_toast_on_static_helper():
	UIToast.toast_on(self, "Hello", UIToast.Kind.SUCCESS, 0.2)
	await get_tree().process_frame
	var host = get_tree().root.get_node_or_null("UIToastHost")
	assert_not_null(host, "Static toast_on should create UIToastHost on root")
	if host:
		host.queue_free()


func test_kind_enum_values():
	assert_eq(UIToast.Kind.INFO, 0)
	assert_eq(UIToast.Kind.SUCCESS, 1)
	assert_eq(UIToast.Kind.DANGER, 2)
	assert_eq(UIToast.Kind.LOOT, 3)
	assert_eq(UIToast.Kind.LEVEL_UP, 4)
