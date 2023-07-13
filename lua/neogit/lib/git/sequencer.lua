local M = {}

-- .git/sequencer/todo does not exist when there is only one commit left.
--
-- And CHERRY_PICK_HEAD does not exist when a conflict happens while picking a series of commits with --no-commit.
-- And REVERT_HEAD does not exist when a conflict happens while reverting a series of commits with --no-commit.
--
function M.pick_or_revert_in_progress()
  local git = require("neogit.lib.git")
  local pick_or_revert_todo = false

  for _, item in ipairs(git.repo.sequencer.items) do
    if item.name:match("^pick") or item.name:match("^revert") then
      pick_or_revert_todo = true
      break
    end
  end

  return git.repo.sequencer.head or pick_or_revert_todo
end

function M.update_sequencer_status(state)
  state.sequencer = { items = {}, head = nil }

  local revert_head = state.git_path("REVERT_HEAD")
  local cherry_head = state.git_path("CHERRY_PICK_HEAD")

  if cherry_head:exists() then
    state.sequencer.head = "CHERRY_PICK_HEAD"
    state.sequencer.cherry_pick = true
  elseif revert_head:exists() then
    state.sequencer.head = "REVERT_HEAD"
    state.sequencer.revert = true
  end

  local todo = state.git_path("sequencer/todo")
  if todo:exists() then
    for line in todo:iter() do
      if not line:match("^#") then
        table.insert(state.sequencer.items, { name = line })
      end
    end
  end
end

M.register = function(meta)
  meta.update_sequencer_status = M.update_sequencer_status
end

return M
