-- https://magit.vc/manual/2.11.0/magit/Rebasing.html#Rebasing
local cli = require("neogit.lib.git.cli")
local branch = require("neogit.lib.git.branch")
local git = require("neogit.lib.git")
local popup = require("neogit.lib.popup")
local CommitSelectViewBuffer = require("neogit.buffers.commit_select_view")
local rebase = require("neogit.lib.git.rebase")
local input = require("neogit.lib.input")

local M = {}
local a = require("plenary.async")

local function in_rebase(status)
  return status and status.repo.rebase.head
end

-- TODO: When in a rebase, hide ALL controls except
-- TODO: When rebasing, pressing <cr> on a commit should open it in commit view
function M.create()
  local status = require("neogit.status")
  local p = popup.builder():name("NeogitRebasePopup")

  if not in_rebase(status) then
    p:switch("k", "keep-empty", "Keep empty commits", false)
      :switch("u", "update-refs", "Update branches", false)
      :switch("d", "committer-date-is-author-date", "Use author date as committer date", false)
      :switch("t", "ignore-date", "Use current time as author date", false)
      :switch("a", "autosquash", "Autosquash fixup and squash commits", false)
      :switch("A", "autostash", "Autostash", false)
      :switch("i", "interactive", "Interactive", false)
      :switch("h", "no-verify", "Disable hooks", false)
      :option("s", "gpg-sign", "", "Sign using gpg", false)
      :option("r", "rebase-merges", "", "Rebase merges", false)
      :group_heading("Rebase " .. (branch.current() and (branch.current() .. " ") or "") .. "onto")
      :action(
        "p",
        "master", -- use pushremote? ((If there is no pushremote, add ", setting that" suffix))
        function(popup)
          rebase.rebase_onto("master", popup:get_arguments())
          a.util.scheduler()
          status.refresh(true, "rebase_master")
        end
      )
      :action(
        "u",
        "upstream", -- use upstream ((If there is no upstream, add ", setting that" suffix))
        false
      )
      :action(
        "e",
        "elsewhere",
        function(popup)
          local branch = git.branch.prompt_for_branch(git.branch.get_all_branches())
          rebase.rebase_onto(branch, popup:get_arguments())
          a.util.scheduler()
          status.refresh(true, "rebase_elsewhere")
        end
      )
      :new_action_group("Rebase")
      :action(
        "i",
        "interactively",
        function(popup)
          local commits = require("neogit.lib.git.log").list()

          local commit = CommitSelectViewBuffer.new(commits):open_async()

          if not commit then
            return
          end

          rebase.rebase_interactive(commit.oid, unpack(popup:get_arguments()))
          a.util.scheduler()
          status.refresh(true, "rebase_interactive")
        end
      )
      :action("s", "a subset", false)
      :new_action_group()
      :action("m", "to modify a commit", false)
      :action("w", "to reword a commit", false)
      :action("k", "to remove a commit", false)
      :action("f", "to autosquash", false)
  else
    p:group_heading("Actions")
      :action("r", "Continue", function()
        rebase.continue()
        a.util.scheduler()
        status.refresh(true, "rebase_continue")
      end)
      :action("s", "Skip", function()
        rebase.skip()
        a.util.scheduler()
        status.refresh(true, "rebase_skip")
      end)
      :action("e", "Edit", false)
      :action("a", "Abort", function()
        if not input.get_confirmation("Abort rebase?", { values = { "&Yes", "&No" }, default = 2 }) then
          return
        end

        cli.rebase.abort.call_sync():trim()
        a.util.scheduler()
        status.refresh(true, "rebase_abort")
      end)
  end

  p:build():show()

  return p
end

return M
