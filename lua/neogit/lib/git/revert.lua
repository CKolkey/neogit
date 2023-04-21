local logger = require("neogit.logger")
local cli = require("neogit.lib.git.cli")
local notif = require("neogit.lib.notification")

local M = {}

local a = require("plenary.async")

function M.commits(commits, args)
  -- a.util.scheduler()
  --
  -- local result = cli["cherry-pick"].arg_list({ unpack(args), unpack(commits) }).call()
  -- if result.code ~= 0 then
  --   notif.create("Cherry Pick failed. Resolve conflicts before continuing", vim.log.levels.ERROR)
  -- end
end

function M.changes(commits, args)
  -- a.util.scheduler()
  --
  -- local result = cli["cherry-pick"].no_commit.arg_list({ unpack(args), unpack(commits) }).call()
  -- if result.code ~= 0 then
  --   notif.create("Cherry Pick failed. Resolve conflicts before continuing", vim.log.levels.ERROR)
  -- end
end

function M.continue()
  cli.revert.continue.call_sync()
end

function M.skip()
  cli.revert.skip.call_sync()
end

function M.abort()
  cli.revert.abort.call_sync()
end

return M
