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
test_mode.keymaps = {
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
do return end

print("")
describe("Module:", function ()
  it("Requiring module [OK]", function ()
    assert.no.errors(function() M = require("alt-modes.mode") end)
  end)

  it("Requiring mappings [OK]", function ()
    assert.no.errors(function() maps = require("alt-modes.mappings") end)
  end)
end)

print("")
describe("Setup -> Run mode:", function ()
  it("Invalid run mode given ('k') [ERORR]", function ()
    test_mode.mode = 'k'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('mode definition.*"k" is not valid native mode'))
  end)

  test_mode.mode = nil
end)

describe("Setup -> Mappings:", function ()

  it("Invalid shadow level given ('foo') [ERORR]", function ()
    test_mode.shadow = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('Invalid shadow level.*"foo"'))
  end)

  it("Invalid shadow content (1) - cant be number [ERORR]", function ()
    test_mode.shadow = {buffer = 2}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('shadow "buffer" should have value of: boolean, string'))
  end)

  it("Invalid shadow content (2) - empty list [ERORR]", function ()
    test_mode.shadow = {buffer = {}}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('shadow "buffer" should have value of: boolean, string'))
  end)

  it("Valid shadow content (1) - boolean [OK]", function ()
    test_mode.shadow = {buffer = true}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (2) - string [OK]", function ()
    test_mode.shadow = {buffer = "<C-X>"}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (3) - list [OK]", function ()
    test_mode.shadow = {buffer = {"X", "Y"}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (4) - nested list [OK]", function ()
    test_mode.shadow = {buffer = {"X", "Y", {"a", "b"}}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (5) - nested list [OK]", function ()
    test_mode.shadow = {buffer = {"X", "Y", {jedab = "a", pet = "b"}}}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (6) - mappings.normal [OK]", function ()
    test_mode.shadow = {native = maps.normal}

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  it("Valid shadow content (7) - multiple mappings [OK]", function ()
    test_mode.shadow = {
      native = {
        maps.normal.tabs,
        maps.normal.windows,
      }
    }

    assert.no.errors(function() M:add('test', test_mode) end)
  end)

  -- print(vim.inspect(M:get('test')))

  test_mode.shadow  = nil
end)

describe("Setup -> Options:", function ()
  it("Invalid option ('foo') [ERORR]", function ()
    test_mode.options = {'foo'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('mode definition.*Invalid option.*"foo"'))
  end)

  it("Invalid option value (2) - should be booelan [ERORR]", function ()
    test_mode.options = {silent = 2}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('mode definition.*Option.*"silent" should have boolean value'))
  end)

  test_mode.options = nil
end)

test_mode.keymaps = nil

describe("Setup -> Keymap list:", function ()
  it("No keymaps given (nil) [ERORR]", function ()
    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*no keymaps given'))
  end)

  it("No keymaps given (empty table) [ERORR]", function ()
    test_mode.keymaps = {}
    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*no keymaps given'))
  end)

  it("Not valid keymap definition ('foo') [ERORR]", function ()
    test_mode.keymaps = 'foo'

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*is keymap definition or list of former'))
  end)
end)

describe("Setup -> Keymap item:", function ()
  it("Not a valid mode ('k') [ERORR]", function ()
    test_mode.keymaps = {mode = 'k'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"k".*is not valid native mode'))
  end)

  it('"lhs" value must be given [ERORR]', function ()
    test_mode.keymaps = {rhs = 'K'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"lhs" value must be given'))
  end)

  it('"rhs" value must be given [ERORR]', function ()
    test_mode.keymaps = {lhs = 'K'}

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"rhs" value must be given'))
  end)

  it("Invalid option ('foo') [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        options = {'foo'}
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*Invalid option.*"foo"'))
  end)

  it("Invalid option value (as option) - should be boolean [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        options = {silent = 2}
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"silent".*should have boolean value'))
  end)

  it("Invalid option value (as parameter) - should be boolean [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        silent = 2,
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*"silent".*should have boolean value'))
  end)


  it("Invalid parameter ('foo') [ERORR]", function ()
    test_mode.keymaps = {
        lhs = 'K',
        rhs = 'foo',
        foo = true
    }

    local ok, msg = pcall(M.add, M, 'test', test_mode)

    assert.is_not(ok)
    assert.not_equal(nil, msg:match('keymaps definition.*invalid parameter.*"foo"'))
  end)
end)
