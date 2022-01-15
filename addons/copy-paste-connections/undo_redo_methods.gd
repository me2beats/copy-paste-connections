tool
extends Resource

var ed_interface:EditorInterface
var scene_tree_ed:Control



func init(plugin:EditorPlugin):
	ed_interface = plugin.get_editor_interface()

	var base = plugin.get_editor_interface().get_base_control()
	scene_tree_ed = preload("utils.gd").find_child_by_class(base.find_node("Scene", 1, 0), 'SceneTreeEditor')


func do(
	target_node:Node,
	target_signal:String,
	conn_data
	):

	if target_node.is_connected(target_signal,conn_data.target,conn_data.method):
		target_node.disconnect(target_signal,conn_data.target,conn_data.method)
	
	target_node.connect(
		target_signal,
		conn_data.target,
		conn_data.method,
		conn_data.binds,
		conn_data.flags
	)


func undo(
	target_node:Node,
	target_signal:String,
	binds:Array,
	flags:int,
	conn_data
	):

	if target_node.is_connected(target_signal,conn_data.target,conn_data.method):
		target_node.disconnect(target_signal,conn_data.target,conn_data.method)

	target_node.connect(
		target_signal,
		conn_data.target,
		conn_data.method,
		binds,
		flags
	)


# just disconnect
func undo1(
	target_node:Node,
	target_signal:String,
	connection_data_target,
	connection_data_method
	):

	if target_node.is_connected(target_signal,connection_data_target,connection_data_method):
		target_node.disconnect(target_signal,connection_data_target,connection_data_method)



func update_connections(target_node:Node):
	ed_interface.edit_node(target_node) # force update connections dock
	scene_tree_ed.update_tree() # update SceneTreeDock connections buttons
