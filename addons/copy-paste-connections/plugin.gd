tool
extends EditorPlugin


const undo_redo_methods = preload("undo_redo_methods.tres")

var connection_data:Dictionary
var connection_object:Node
var connection_signal:String

var popup_copy:PopupMenu
var popup_paste:PopupMenu

const copy_item_id = 559
const paste_item_id = 558

onready var undo_redo: = get_undo_redo()

var base:Control = get_editor_interface().get_base_control()
onready var scene_tree_ed:Control = find_child_by_class(base.find_node("Scene", 1, 0), 'SceneTreeEditor')


# since there's no get_edited_object() method
var edited_object:Object
func handles(object:Object):
	edited_object = object


func _enter_tree():
	var selection:EditorSelection = get_editor_interface().get_selection()
	if selection.get_selected_nodes().size()==1:
		edited_object = selection.get_selected_nodes()[0]
	
	undo_redo_methods.init(self)
	
	var signals_control:Control = base.find_node("Signals", true, false)
	# we also can check, if signals_control parent is named "Node"
	
	var tree:Tree = find_child_by_type(signals_control, Tree)
	

	var popups:Array = get_children_by_type(signals_control, PopupMenu)
	

		
	if popups[0].get_item_count() == 3:

		popup_copy = popups[0]
		popup_paste = popups[1]
	else:
		
		popup_copy = popups[1]
		popup_paste = popups[0]


	popup_copy.connect("id_pressed", self, "on_popup_copy_id_pressed", [popup_copy, tree])
	popup_paste.connect("id_pressed", self, "on_popup_paste_id_pressed", [popup_paste, tree])

	popup_copy.add_item("Copy Connection", copy_item_id)
	popup_paste.add_item("Paste Connection", paste_item_id)
		




func on_popup_copy_id_pressed(id:int, popup:PopupMenu, tree:Tree):
	match id:
		copy_item_id:
			if !edited_object is Node:
				push_warning("Something went wrong! !edited_object is Node")
				return
			var sel:TreeItem = tree.get_selected()
			connection_data = sel.get_metadata(0)
			connection_signal = sel.get_parent().get_metadata(0).name
			connection_object = edited_object


static func get_signal_connection_binds_and_flags(
	obj1:Object,
	signal_name:String,
	obj2:Object,
	method:String
	)->Dictionary:
	
	var result:Dictionary
	
	for i in obj1.get_signal_connection_list(signal_name):
		if i.target == obj2 and i.method == method:
			result = {binds = i.binds, flags = i.flags}
			break

	return result


# messy, variable names are bad
func on_popup_paste_id_pressed(id:int, popup:PopupMenu, tree:Tree):
	
	match id:
		paste_item_id:
			var target_node:Node = edited_object
			
			if !target_node:
				return

			var sel:TreeItem = tree.get_selected()
			var target_signal:String = sel.get_metadata(0).name


			var target_node_connection_binds_and_flags: = get_signal_connection_binds_and_flags(
				target_node,
				target_signal,
				connection_data.target,
				connection_data.method
			)


			var binds:Array
			var flags:int
			
			if target_node_connection_binds_and_flags:
				binds = target_node_connection_binds_and_flags.binds
				flags = target_node_connection_binds_and_flags.flags
			
				if binds.hash() == connection_data.binds.hash() and flags == connection_data.flags:
					print("already set!")
					return

			undo_redo.create_action("Paste signal connection")
			
			undo_redo.add_do_method(
				undo_redo_methods,
				'do',
				target_node,
				target_signal,
				connection_data.duplicate()
			)
			
			undo_redo.add_do_method(undo_redo_methods, 'update_connections', target_node)
			

			if not target_node_connection_binds_and_flags:
				undo_redo.add_undo_method(
					undo_redo_methods,
					"undo1",
					target_node,
					target_signal,
					connection_data.target,
					connection_data.method
					
				)

			elif target_node.is_connected(target_signal, connection_data.target, connection_data.method):

				undo_redo.add_undo_method(
					undo_redo_methods,
					"undo",
					target_node,
					target_signal,
					binds,
					flags,
					connection_data.duplicate()
				)

			else:

				undo_redo.add_undo_method(
					undo_redo_methods,
					"undo",
					target_node,
					target_signal,
					connection_data.binds,
					connection_data.flags
				)


			undo_redo.add_undo_method(undo_redo_methods, 'update_connections', target_node)
			undo_redo.commit_action()










func _exit_tree():
	if not popup_copy: return

	popup_copy.remove_item(popup_copy.get_item_index(copy_item_id))
	popup_paste.remove_item(popup_paste.get_item_index(paste_item_id))

	popup_copy.rect_size = Vector2.ZERO
	popup_paste.rect_size = Vector2.ZERO



# ============== Utils ================


static func find_child_by_type(node:Node, type):
	for child in node.get_children():
		if child is type:
			return child


static func get_children_by_type(node:Node, type)->Array:
	var res:=[]
	for n in node.get_children():
		if n is type:
			res.push_back(n)
	return res


static func find_child_by_class(node:Node, cls:String):
	for child in node.get_children():
		if child.get_class() == cls:
			return child

