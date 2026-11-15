-- Runs the self-check of Decision Inbox.md against odpWstaw in plain Lua 5.4.
-- Usage: lua5.4 "Library/maciejszulia/tests/test_decision_inbox.lua"
local dir = arg[0]:match("^(.*)/") or "."
local file = assert(io.open(dir .. "/../Decision Inbox.md", "rb"))
local page = file:read("a")
file:close()

local blocks = {}
for code in page:gmatch("```space%-lua\n(.-)\n```") do
  blocks[#blocks + 1] = code
end
assert(#blocks == 2, "expected 2 space-lua blocks, found " .. #blocks)

-- Block 1 defines odpWstaw and odp; block 2 registers the self-check command.
assert(load(blocks[1], "=odpWstaw"))()
assert(type(odpWstaw) == "function", "odpWstaw is not defined")

local message, kind
editor = { flashNotification = function(m, k) message, kind = m, k end }
command = { define = function(spec) spec.run() end }
assert(load(blocks[2], "=self-check"))()

print(message)
assert(message == "Skrypt odpowiedzi: OK" and kind == nil, "self-check failed")

-- A case the self-check lacks: a block with 2 answer fields must stay unchanged.
local twoFields = table.concat({
  "### Z-TWO Two answer fields",
  "* [ ] własnymi słowami:",
  "> _(tu wpisz odpowiedź)_",
  "> second field",
}, "\n")
assert(odpWstaw(twoFields, "Z-TWO", "x") == nil, "a block with 2 answer fields was changed")
print("2 answer fields in 1 block: nil")

print("test_decision_inbox: OK")
