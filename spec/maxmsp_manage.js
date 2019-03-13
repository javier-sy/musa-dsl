var sub = null;
var objects = {};


function initialize(workspace_name) 
{
	sub = this.patcher.getnamed(workspace_name).subpatcher();
}

function clear()
{
	sub.apply(function(o) { sub.remove(o); });
	objects = {};
}

function create(name, kind)
{
	parameters = arrayfromargs(arguments)
	parameters.shift(); parameters.shift();

	objects[name] = sub.newdefault(0, 0, kind, parameters);
}

function remove(name)
{
	o = objects[name];
	
	if(!(o === undefined))
	{
		sub.remove(o);
		delete objects[name];
	}
}

function connect(source_name, source_port, target_name, target_port)
{
	source = objects[source_name]
	target = objects[target_name]

	if(!(source === undefined) && !(target === undefined))
	{
		sub.connect(source, source_port, target, target_port);
	}
}

function message(name, message) 
{
	object = objects[name];
	
	if(!(object === undefined)) {
		object.message(message);
	}
}

function unknown()
{
	parameters = arrayfromargs(arguments);
	post("ERROR: Unknown command '" + parameters.join() + "'");
}