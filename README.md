# luvit-firebase
Allows you to make requests to Google's Firebase Database service

# Installation
``lit install Tigerism/luvit-firebase``

# Usage
First, you need to pass the root and auth key as constructors when requiring the module.

To do this, follow this example:

```lua
local firebase = require("luvit-firebase")
local db = firebase("ROOT","AUTH")
```

Now, you'll be able to use some functions of the script. To get the results, you'll need to pass a callback.

Examples:
```lua
db:set("test",{test1 = "answer1", test2 = "answer2"},function(err,res)
	p(err,res)
end)

db:get("test",function(err,res)
	p(err,res)
end)

db:update("test",{test1 = "answer100"},function(err,res)
	p(err,res)
end)

db:delete("test",function(err,res)
	p(err,res)
end)


```

``set`` will overwrite the data in the node with either a key-value table or a JSON string.

``update`` will update values. **THIS IS RECOMMENDED INSTEAD OF USING SET SO YOUR DATA DOESN'T GET WIPED**

``delete`` will remove an entire node

``get`` will return the JSON for that node.]
