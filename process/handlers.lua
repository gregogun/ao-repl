local handlers = { _version = "0.0.3" }

handlers.utils = require('.handlers-utils')
handlers.list = {}

local function findIndexByProp(array, prop, value)
  for index, object in ipairs(array) do
    if object[prop] == value then
      return index
    end
  end
  return nil
end

function handlers.add(name, pattern, handle)
  assert(type(name) == 'string' and type(pattern) == 'function' and  type(handle) == 'function', 'invalid arguments: handler.add(name : string, pattern : function(msg: Message) : {-1 = break, 0 = skip, 1 = continue}, handle(msg : Message) : void)') 
  assert(type(name) == 'string', 'name MUST be string')
  assert(type(pattern) == 'function', 'pattern MUST be function')
  assert(type(handle) == 'function', 'handle MUST be function')
  
  -- update existing handler by name
  local idx = findIndexByProp(handlers.list, "name", name)
  if idx ~= nil and idx > 0 then
    -- found update
    handlers.list[idx].pattern = pattern
    handlers.list[idx].handle = handle
  else
    -- not found then add    
    table.insert(handlers.list, { pattern = pattern, handle = handle, name = name })

  end
end


function handlers.append(name, pattern, handle)
  assert(type(name) == 'string' and type(pattern) == 'function' and  type(handle) == 'function', 'invalid arguments: handler.append(name : string, pattern : function(msg: Message) : {-1 = break, 0 = skip, 1 = continue}, handle(msg : Message) : void)') 
  assert(type(name) == 'string', 'name MUST be string')
  assert(type(pattern) == 'function', 'pattern MUST be function')
  assert(type(handle) == 'function', 'handle MUST be function')
  
    -- update existing handler by name
  local idx = findIndexByProp(handlers.list, "name", name)
  if idx ~= nil and idx > 0 then
    -- found update
    handlers.list[idx].pattern = pattern
    handlers.list[idx].handle = handle
  else
    table.insert(handlers.list, { pattern = pattern, handle = handle, name = name })
  end

  
end

function handlers.prepend(name, pattern, handle) 
  assert(type(name) == 'string' and type(pattern) == 'function' and  type(handle) == 'function', 'invalid arguments: handler.prepend(name : string, pattern : function(msg: Message) : {-1 = break, 0 = skip, 1 = continue}, handle(msg : Message) : void)') 
  assert(type(name) == 'string', 'name MUST be string')
  assert(type(pattern) == 'function', 'pattern MUST be function')
  assert(type(handle) == 'function', 'handle MUST be function')
  

  -- update existing handler by name
  local idx = findIndexByProp(handlers.list, "name", name)
  if idx ~= nil and idx > 0 then
    -- found update
    handlers.list[idx].pattern = pattern
    handlers.list[idx].handle = handle
  else  
    table.insert(handlers.list, 1, { pattern = pattern, handle = handle, name = name })
  end

  
end

function handlers.before(handleName)
  assert(handleName ~= nil, 'invalid arguments: handlers.before(name : string) : { add = function(name, pattern, handler)}')
  assert(type(handleName) == 'string', 'name MUST be string')

  local idx = findIndexByProp(handlers.list, "name", handleName)
  return {
    add = function (name, pattern, handle) 
      assert(type(name) == 'string' and type(pattern) == 'function' and  type(handle) == 'function', 'invalid arguments: handler.before("foo").add(name : string, pattern : function(msg: Message) : {-1 = break, 0 = skip, 1 = continue}, handle(msg : Message) : void)') 
      assert(type(name) == 'string', 'name MUST be string')
      
      assert(type(pattern) == 'function', 'pattern MUST be function')
      assert(type(handle) == 'function', 'handle MUST be function')
      
      if idx then
        table.insert(handlers.list, idx, { pattern = pattern, handle = handle, name = name })
      end
      
    end
  }
end

function handlers.after(handleName)
  assert(handleName ~= nil, 'invalid arguments: handlers.after(name : string) : { add = function(name, pattern, handler)}')
  assert(type(handleName) == 'string', 'name MUST be string')
  local idx = findIndexByProp(handlers.list, "name", handleName)
  return { 
    add = function (name, pattern, handle)
      assert(type(name) == 'string' and type(pattern) == 'function' and  type(handle) == 'function', 'invalid arguments: handler.after("foo").add(name : string, pattern : function(msg: Message) : {-1 = break, 0 = skip, 1 = continue}, handle(msg : Message) : void)') 

      assert(type(name) == 'string', 'name MUST be string')
      assert(type(pattern) == 'function', 'pattern MUST be function')
      assert(type(handle) == 'function', 'handle MUST be function')
      
      if idx then
        table.insert(handlers.list, idx + 1, { pattern = pattern, handle = handle, name = name })
      end
      
    end
  }

end

function handlers.remove(name)
  assert(type(name) == 'string', 'name MUST be string')
  if #handlers.list == 1 and handlers.list[1].name == name then
    handlers.list = {}
    
  end

  local idx = findIndexByProp(handlers.list, "name", name)
  table.remove(handlers.list, idx)
  
end

--- return 0 to not call handler, -1 to break after handler is called, 1 to continue
function handlers.evaluate(msg, env)
  assert(type(msg) == 'table', 'msg is not valid')
  assert(type(env) == 'table', 'env is not valid')
  
  for i, o in ipairs(handlers.list) do
    local match = o.pattern(msg)
    if match ~= 0 then
      -- each handle function can accept, the msg, env
      o.handle(msg, env)
    end
    if match < 0 then
      return 
    end
  end
end

return handlers