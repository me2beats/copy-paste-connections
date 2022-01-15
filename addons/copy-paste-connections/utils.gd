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

