-- ============================================
-- aserts:
--   is     - test is true
--   is_not - test is not true
--   has    - same as is
--   equal  - comparing if same object
--   same   - comparing if content of object are eqaul
--
--   no.errors   - run without errors
--   has.errors  - run with errors


--
-- eqaul objects:
--   A = {element = 1}
--   B = A
--
-- same objects:
--   A = {element = 1}
--   B = {element = 1}



-- ============================================
-- disable output of notifications from plugin
---
-- vim.notify = function() end

local M
local maps
local test_mode = {}

-- =============================================
-- to pass some tests (other than keymap tests)
-- keymap has to be deeined
--
local test_keymaps = {
  mode = 'v',
  lhs  = 'Z',
  rhs  = 'lua vim.notify("Key \"J\" was pressed")',
  desc = 'Notify that "J" key has been pressed',
}

-- M = require("alt-modes.mode")
-- print(vim.inspect(M))
--
-- print ("---------------")
-- M:add('test', test_mode)
-- print ("---------------")
--
-- do return end
local reset_test_mode = function()
  test_mode.keymaps = test_keymaps
  test_mode.overlay = {}

  -- test_mode.name = test_mode._name
  -- test_mode._name = nil
  -- test_mode._mode = nil
  -- test_mode._help = nil
  -- test_mode._keymaps = nil
  -- test_mode._timeout = nil
  -- test_mode._overlay = nil
end


print()
describe("Loading module:", function ()
  before_each(reset_test_mode)

  it("mode [OK]", function ()
    assert.no.errors(function() M = require("alt-modes") end)
  end)

  it("native [OK]", function ()
    assert.no.errors(function() maps = require("alt-modes.native") end)
  end)
end)

describe("Config options:", function ()
  before_each(reset_test_mode)

  it("Invalid config option ('foo') [ERORR]", function ()
    test_mode.foo = 'true'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('TEST Invalid config option.*"foo"'))
  end)

  test_mode.foo = nil
end)

describe("Native mode:", function ()
  before_each(reset_test_mode)

  it("Invalid native mode given ('k') [ERORR]", function ()
    test_mode.mode = 'k'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('mode definition.*"k" is not valid native mode'))
  end)

  test_mode.mode = nil
end)

describe("Global:", function ()
  before_each(reset_test_mode)

  it("Global must be a boolean value[ERORR]", function ()
    test_mode.global = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('global option must be boolean'))
  end)

  test_mode.global = nil
  test_mode.mode = nil
end)

describe("Timeout:", function ()
  before_each(reset_test_mode)

  it("Timeout must be a number [ERORR]", function ()
    test_mode.timeout = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('timeout must be a number'))
  end)

  it("Timeout must be a number [OK]", function ()
    test_mode.timeout = 100

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  test_mode.mode = nil
end)

describe("Status:", function ()
  before_each(reset_test_mode)

  it("Status must be function[ERORR]", function ()
    test_mode.status= 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('status must be a function'))
  end)

  test_mode.status = nil
  test_mode.mode = nil
end)


print()
describe("Overlay:", function ()
  before_each(reset_test_mode)

  it("Invalid option given ('foo') [ERORR]", function ()
    test_mode.overlay = {foo = true}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('TEST %(overlay%): Invalid option.*"foo"'))
  end)
end)

describe("Overlay defaults:", function ()
  before_each(reset_test_mode)

  it("Invalid scope given ('foo') [ERORR]", function ()
    test_mode.overlay.default = {foo = true}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('TEST %(overlay defaults%): Invalid scope.*"foo"'))
  end)

  it("Invalid scope value ('bar') [ERORR]", function ()
    test_mode.overlay.default = {buffer = 'bar'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('TEST %(overlay defaults%): Invalid scope value.*bar'))
  end)

  it("Default scope value given ('block') [OK]", function ()
    test_mode.overlay.default = nil

    assert.no.errors(function() M:add('test', test_mode) end)

    local tm = M._altmodes['test']

    assert.is_not_true(tm._overlay.buffer.default)
    assert.is_not_true(tm._overlay.global.default)
    assert.is_not_true(tm._overlay.native.default)
  end)
end)


print()
describe("Block:", function ()
  before_each(reset_test_mode)

  it("Invalid block level given ('foo') [ERORR]", function ()
    test_mode.overlay.block = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('Invalid block level.*"foo"'))
  end)

  it("Invalid block content (1) - cant be number [ERORR]", function ()
    test_mode.overlay.block = {buffer = 2}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('block "buffer" should have value of: boolean, string'))
  end)

  it("Invalid block content (2) - empty list [ERORR]", function ()
    test_mode.overlay.block = {buffer = {}}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('block "buffer" should have value of: boolean, string'))
  end)

  it("Valid block content (1) - boolean [OK]", function ()
    test_mode.overlay.block = {buffer = true}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (2) - string [OK]", function ()
    test_mode.overlay.block = {buffer = "<C-X>"}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (3) - list [OK]", function ()
    test_mode.overlay.block = {buffer = {"X", "Y"}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (4) - nested list [OK]", function ()
    test_mode.overlay.block = {buffer = {"X", "Y", {"a", "b"}}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (5) - nested list [OK]", function ()
    test_mode.overlay.block = {buffer = {"X", "Y", {jedab = "a", pet = "b"}}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (6) - nested list [OK]", function ()
    test_mode.overlay.block = {buffer = {"X", "Y", something = {jedab = "a", pet = "b"}}}

    assert.no.errors(function() M:add('test', test_mode) end)
    -- print (vim.inspect(M:get('test')))
  end)

  it("Valid block content (7) - native.normal [OK]", function ()
    test_mode.overlay.block = {native = maps.normal}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid block content (8) - multiple native [OK]", function ()
    test_mode.overlay = {
      block = {
        native = {
          maps.normal.tabs,
          maps.normal.windows,
        }
      }
    }

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

end)


print()
describe("Keep:", function ()
  before_each(reset_test_mode)
  local overlay

  it("Conflicting block & keep for buffer (true, true) [ERORR]", function ()
    test_mode.overlay = {
      block = {buffer = true},
      keep   = {buffer = true},
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match("can't simultaniously keep and block buffer keymaps"))
  end)

  it("Conflicting block & keep for global (true, true) [ERORR]", function ()
    test_mode.overlay = {
      block = {global = true},
      keep   = {global = true},
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match("can't simultaniously keep and block global keymaps"))
  end)

  it("Conflicting block & keep for native (true, true) [ERORR]", function ()
    test_mode.overlay = {
      block = {native = true},
      keep   = {native = true},
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match("can't simultaniously keep and block native keymaps"))
  end)

  it("Conflicting block & keep for native (false, nil) [ERORR]", function ()
    test_mode.overlay = {
      block = {native = false},
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match("can't simultaniously keep and block native keymaps"))
  end)

  it("Conflicting block & keep for native (true, nil) [ERORR]", function ()
    test_mode.overlay = {
      default = {native = 'keep'},
      block = {native = true},
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match("can't simultaniously keep and block native keymaps"))
  end)
end)

print()
describe("Keymap options:", function ()
  before_each(reset_test_mode)

  it("Invalid option ('foo') [ERORR]", function ()
    test_mode.options = {'foo'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('mode definition.*Invalid option.*"foo"'))
  end)

  it("Invalid option value (2) - should be booelan [ERORR]", function ()
    test_mode.options = {silent = 2}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('mode definition.*Option.*"silent" should have boolean value'))
  end)

  test_mode.options = nil
end)

test_mode.keymaps = nil


print()
describe("Keymap list:", function ()
  before_each(reset_test_mode)

  it("No keymaps given (nil) [ERORR]", function ()
    test_mode.keymaps = nil
    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*no keymaps given'))
  end)

  it("No keymaps given (empty table) [ERORR]", function ()
    test_mode.keymaps = {}
    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*no keymaps given'))
  end)

  it("Not valid keymap definition ('foo') [ERORR]", function ()
    test_mode.keymaps = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*is keymap definition or list of former'))
  end)
end)


print()
describe("Keymap item:", function ()
  before_each(reset_test_mode)

  it("Not a valid mode ('k') [ERORR]", function ()
    test_mode.keymaps = {mode = 'k'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"k".*is not valid native mode'))
  end)

  it('"lhs" value must be given [ERORR]', function ()
    test_mode.keymaps = {rhs = 'K'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"lhs" value must be given'))
  end)

  it('"rhs" or "fhs" value must be given [ERORR]', function ()
    test_mode.keymaps = {lhs = 'K'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"rhs" or "fhs" must be given'))
  end)

  it('"fhs" must be function [ERORR]', function ()
    test_mode.keymaps = {lhs = 'K', fhs = 'foo'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"fhs" must be function'))
  end)

  it("Invalid option ('foo') [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        options = {'foo'}
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*Invalid option.*"foo"'))
  end)

  it("Invalid option value (as option) - should be boolean [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        options = {silent = 2}
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"silent".*should have boolean value'))
  end)

  it("Invalid option value (as parameter) - should be boolean [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        silent = 2,
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"silent".*should have boolean value'))
  end)


  it("Invalid parameter ('foo') [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        foo = true
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*invalid parameter.*"foo"'))
  end)
end)
