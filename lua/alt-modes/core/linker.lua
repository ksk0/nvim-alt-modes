local loop = vim.loop
local port = 8087

local executor = function(client, err, chunk)
  assert(not err, err)

  if chunk then
    client:write(chunk)
  else
    client:shutdown()
    client:close()
  end
end

local client_talk = function (self)
  while true do
    msg = vim.fn.input('Mesage : ')

    self.client:write(msg)

    if msg == "exit" or msg == "quit" then
      vim.notify('Exiting ...')
      return
    end

  end
end

local client_echo = function (client, err, chunk)
  assert(not err, err)

  if chunk then
    vim.notify("Chunk: " .. chunk)
  else
    client:shutdown()
    client:close()
  end
end

local new_client = function ()
  local client = loop.new_tcp()
  local error

  client:connect(
    "127.0.0.1",
    port,
    function (err)
      error = err or ""
    end
  )

  while true do
    vim.cmd [[ sleep 100m ]]
    if error then break end
  end

  vim.notify("Error: " .. vim.inspect(error))

  if error ~= "" then return end

  client:read_start(function (err, chunk)
    client_echo(client, err, chunk)
  end)

  return client
end

local new_server = function()
  local server = loop.new_tcp()

  server:bind('127.0.0.1', port)

  server:listen(128, function (listen_error)
    assert(not listen_error, listen_error)

    local client = loop.new_tcp()

    server:accept(client)

    client:read_start(function (read_error, chunk)
      executor(client, read_error, chunk)
    end)
  end)

  print("TCP server listening at 127.0.0.1 port " .. tostring(port))

  loop.run() -- an explicit run call is necessary outside of luvit
end

local M = {}

M.server = function()
  new_server()
end

M.client  = function()
  local C = {}

  C.client = new_client()
  if not C.client then return end

  C.talk = client_talk

  return C
end

return M
