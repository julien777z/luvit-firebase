
local http = require('coro-http')
local json = require('json')

local toolkit_reasons = {
	keyInvalid = 'API Key Invalid'
}

local toolkit_domains = {
	usageLimits = 'Usage Limit'
}

local toolkit_errors = {
	EMAIL_NOT_FOUND  = 'Invalid Email',
	INVALID_PASSWORD = 'Invalid Password'
}

local function identify(appstr, payload, key)
	local uri = string.format('https://www.googleapis.com/identitytoolkit/v3/relyingparty/%s?key=%s', appstr, key)
	local datastring = json.stringify(payload)

	local res, body = http.request('POST', uri, { { 'Content-Type', 'application/json' }, { 'Content-Length', #datastring } }, datastring)
	body = json.parse(body)

	local error = body.error and body.error.errors and body.error.errors[1]

	if error then
		error.message = toolkit_errors[error.message] or error.message
		error.reason  = toolkit_reasons[error.reason] or error.reason
		print(string.format('%s | \27[1;33m[WARNING]\27[0m | %s', os.date('%F %T'), 'Identification Error | ' .. (body.code or res.code) ..  ' | ' .. error.domain .. ' / ' .. error.reason .. ' | ' .. error.message))
		return process:exit(22)
	end

	return res.code == 200 and body, body
end

local function emailauth(email, password, key)
	return identify('verifyPassword', { email = email, password = password, returnSecureToken = true }, key)
end

local securetoken_errors = {
	INVALID_REFRESH_TOKEN = 'Invalid Refresh Token'
}

local function refresh(rtoken, key)
	if not rtoken or not key then
		return false, print('Could not Reauthenticate with the Google API')
	end

	local uri = string.format('https://securetoken.googleapis.com/v1/token?key=%s', key)
	local datastring = 'grant_type=refresh_token&refresh_token=' .. rtoken

	local res, body = http.request('POST', uri, { { 'Content-Type', 'application/x-www-form-urlencoded' } }, datastring)
	body = json.parse(body)

	local error = body.error and body.error.message

	if error then
		error = securetoken_errors[error] or error

		print(string.format('%s | \27[1;33m[WARNING]\27[0m | %s', os.date('%F %T'), 'Reauthentication Error: ' .. (body.code or res.code) ..  ' ' .. error))
		return process:exit(22)
	end

	return res.code == 200 and body, body
end

return {
	email = emailauth,
	refresh = refresh
}
