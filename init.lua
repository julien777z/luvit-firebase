
--// Thanks to Tigerism for the base api (https://github.com/Tigerism/luvit-firebase)

local firebase = { }
firebase.__index = firebase

local google = require('./google')
local http = require('coro-http')
local json = require('json')

local refresh_coro = { }

local sleep
local function reauthenticate(db)
    refresh_coro[db.root] = refresh_coro[db.root] or coroutine.wrap(function()
        local success, body = google.refresh(db.refresh, db.key)

        if not success then
            return print(string.format('%s | \27[1;33m[WARNING]\27[0m | %s', os.date('%F %T'), 'Request for Token Reauthentication Failed'))
        end

        db.refresh = body.refresh_token
        db.auth = body.id_token
        expires = os.time() + body.expires_in
    end)

    refresh_coro[db.root]()
end

local function isCoro()
    local _, bool = coroutine.running()
    return not bool
end

setmetatable(firebase, {
    __call = function(this, dbroot, projectkey, authtab)
        assert(isCoro(), 'Running Firebase Synchronously is not Supported at the moment')

        assert(type(dbroot) == 'string', 'bad argument #1 to \'firebase\' (expected string, got ' .. type(dbroot) .. ')')
        assert(type(projectkey) == 'string', 'bad argument #2 to \'firebase\' (expected string, got ' .. type(projectkey) .. ')')

        dbroot = dbroot:gsub('https?://', ''):gsub('%.firebaseio%.com/?', '')

        local db = { }
        db.root = dbroot
        db.key = projectkey

        if type(authtab) == 'table' and (authtab[1] or authtab.email) and (authtab[2] or authtab.password) then
            local success, body = google.email(authtab[1] or authtab.email, authtab[2] or authtab.password, db.key)

            if not success then
                return print(string.format('%s | \27[1;33m[WARNING]\27[0m | %s', os.date('%F %T'), 'Request for Token Authentication Failed'))
            end

            db.email = body.email
            db.auth = body.idToken
            db.refresh = body.refreshToken
            db.expires = os.time() + body.expiresIn

            print(string.format('%s | \27[1;32m[INFO]   \27[0m | %s', os.date('%F %T'), 'Firebase Authenticated: ' .. body.email))
            this._authenticated = true
        end
        
        return setmetatable(db, firebase)
    end
})

local format = string.format
local function formatNonAuth(db, node)
    return format('https://%s.firebaseio.com/%s.json', db.root, node)
end

local function formatAuth(db, node)
    return format('https://%s.firebaseio.com/%s.json?auth=%s', db.root, node, db.auth)
end

--// https://github.com/Tigerism/luvit-firebase/blob/master/firebase.lua#L15-L50
function firebase:request(node, method, callback, content)
    assert(isCoro(), 'Running Firebase Synchronously is not Supported at the moment')

    if not self.key and not self.auth then return end

    if self.auth and self.expires <= os.time() - 30 then
        reauthenticate(self)
    end

    local uri = self.auth and formatAuth(self, node) or formatNonAuth(self, node)
    
    local headers, body = http.request(method, uri, { { 'Content-Type', 'application/json' } }, content)
    body = json.parse(body)

    if type(callback) == 'function' then
        callback(headers.code ~= 200 and body, body)
    end

    return body
end

function firebase:get(node, callback)
	return self:request(node, 'GET', callback)
end

function firebase:set(node, content, callback)
    content = json.stringify(content)
	return self:request(node, 'PUT', callback, content)
end

function firebase:update(node, content, callback)
	content = type(content) == 'table' and json.stringify(content) or content
	return self:request(node, 'PATCH', callback, content)
end

function firebase:push(node, content ,callback)
	content = type(content) == 'table' and json.stringify(content) or content
	return self:request(node, 'POST', callback, content)
end

function firebase:delete(node, callback)
	return self:request(node, 'DELETE', callback)
end

return firebase