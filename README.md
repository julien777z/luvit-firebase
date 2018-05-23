# luvit-firebase
Allows you to make requests to Google's Firebase Database service

Rewrite by @truemedian

# Installation
``lit install Tigerism/luvit-firebase``

# Synchronous Execution
This wrapper does NOT support synchronous methods, if called outside of a coroutine, all methods will return an error

## Usage
First, you need to pass the root and auth key as constructors when requiring the module.

To do this, follow this example:

```lua
local firebase = require('luvit-firebase')

coroutine.wrap(function()
	local db = firebase('ROOT', 'WEB API KEY', { email = 'example@example.com', password = 'password' })
end)()
```

The root is ONLY the database root. (ex. ROOT for `https://mydb.firebaseio.com/` is `mydb`)  
Your WEB API KEY can be found on your project settings.  
Email and Password must be set up in Authentication by **ADD USER**, be aware, once you create the account, you will not be able to view the password, so write it down.

Callbacks are not required but are supported as the last parameter to methods

### Methods:
`set` will overwrite the data in the node with either a lua table or a JSON string.  
`update` will update values in the specific node with the payload provided. **THIS IS RECOMMENDED INSTEAD OF USING SET SO YOUR DATA DOESN'T GET WIPED**  
`delete` will remove an entire node from the database.  
`get` will return the table for that node.

# Examples:
```lua
local firebase = require('luvit-firebase')

coroutine.wrap(function()
	local db = firebase('ROOT', 'WEB API KEY', { email = 'example@example.com', password = 'password' })

	p(db:set('test', { test1 = 'answer1', test2 = 'answer2' })
	p(db:get('test')
	p(db:update('test', { test1 = 'answer100' })
	p(db:delete('test')
end)()
```
