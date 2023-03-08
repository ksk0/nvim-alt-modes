-- ============================================
-- aserts:
--   is     - test is true
--   is_not - test is not true
--   is_nil - test is nil
--   has    - same as is
--
--   equal  - comparing if same object
--   same   - comparing if content of object are same
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
--
print()
describe("Load module:", function ()
  it("[OK]", function ()
    assert.no.errors(function() M = require("alt-modes") end)
  end)
end)

print()
describe("Follow - options:", function ()
  it("Options must be table of options [ERROR]", function ()
    local ok,msg = pcall(M.follow, M, "foo")

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow: Options must be table of options'))
  end)

  it('No events given [ERROR]', function ()
    local ok,msg = pcall(M.follow, M, {})

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow: No events were given!'))
  end)

  it('"once" is string ("foo") [ERROR]', function ()
    local ok,msg = pcall(M.follow, M, {once = "foo", BufEnter = function () end})

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow: "once" option must be boolean'))
  end)

  it('"init" is string ("foo") [ERROR]', function ()
    local ok,msg = pcall(M.follow, M, {init= "foo", BufEnter = function () end})

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow: "init" option must be boolean'))
  end)

  it('"filter" is string ("foo") [ERROR]', function ()
    local ok,msg = pcall(M.follow, M, {once = true, filter = "foo", BufEnter = function () end})

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow: "filter" option must be function'))
  end)
end)

print()
describe('Follow - event:', function ()
  it('"foo" is not valid event [ERROR]', function ()
    local opts = {
      foo = function () end
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[foo%]: is not valid event'))
  end)

  it("Event must be table or function [ERROR]", function ()
    local opts = {BufEnter = "foo"}
    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: must be function or table of options'))
  end)

  it('Invalid option "foo" [ERROR]', function ()
    local opts = {
      BufEnter = {
        foo = true,
        once = true,
        filter = function() end,
      }
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: invalid option%(s%):'))
  end)

  it('"action" must be given [ERROR]', function ()
    local opts = {
      BufEnter = {
        once = true,
        filter = function() end,
      }
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: "action" must be given'))
  end)

  it('"action" is string ("foo") [ERROR]', function ()
    local opts = {
      BufEnter = {
        action = "foo",
        once = true,
        filter = function() end,
      }
    }


    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: "action" must be function'))
  end)

  it('"once" is string ("foo") [ERROR]', function ()
    local opts = {
      BufEnter = {
        action = function() end,
        once = "foo",
        filter = function() end,
      }
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: "once" option must be boolean'))
  end)

  it('"init" is string ("foo") [ERROR]', function ()
    local opts = {
      BufEnter = {
        action = function() end,
        init = "foo",
        filter = function() end,
      }
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: "init" option must be boolean'))
  end)

  it('"filter" is string ("foo") [ERROR]', function ()
    local opts = {
      BufEnter = {
        action = function() end,
        once = true,
        filter = "foo"
      }
    }

    local ok,msg = pcall(M.follow, M, opts)

    assert.is_not_true(ok)
    assert.not_equal(nil, msg:match('follow %[BufEnter%]: "filter" option must be function'))
  end)
end)

