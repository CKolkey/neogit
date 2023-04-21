-- https://magit.vc/manual/2.11.0/magit/Reverting.html#Reverting
local popup = require("neogit.lib.popup")
local git = require("neogit.lib.git")
local a = require("plenary.async")

local M = {}

function M.create(env)
  local status = require("neogit.status")
  local in_progress = git.sequencer.pick_or_revert_in_progress(status)

  local p = popup
    .builder()
    :name("NeogitRevertPopup")
    :switch_if(not in_progress, "e", "edit", "Edit commit message", { enabled = true, incompatible = { "no-edit" } })
    :switch_if(not in_progress, "E", "no-edit", "Don't edit commit message", { incompatible = { "edit" } })
    :switch_if(not in_progress, "s", "signoff", "Add Signed-off-by lines")
    :option_if(not in_progress, "m", "mainline", "", "Replay merge relative to parent")
    :option_if(not in_progress, "s", "strategy", "", "Strategy", {
      choices = { "resolve", "recursive", "octopus", "ours", "subtree" },
    })
    :option_if(not in_progress, "S", "gpg-sign", "", "Sign using gpg")
    :group_heading("Actions")
    :action_if(not in_progress, "V", "Revert Commit(s)", function(popup)
    end)
    :action_if(not in_progress, "v", "Revert changes", function(popup)
    end)
    :action_if(in_progress, "V", "continue", function()
      git.revert.continue()
      a.util.scheduler()
      status.refresh(true, "revert_continue")
    end)
    :action_if(in_progress, "s", "skip", function()
      git.revert.skip()
      a.util.scheduler()
      status.refresh(true, "revert_skip")
    end)
    :action_if(in_progress, "a", "abort", function()
      git.revert.abort()
      a.util.scheduler()
      status.refresh(true, "revert_abort")
    end)
    :env({ commits = env.commits })
    :build()

  p:show()

  return p
end

return M
