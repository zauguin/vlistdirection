-- This module was written based on a simple problem:
--   LuaTeX knows only four dimension registers,
--   and all of them use similar syntax.
--   If we keep having such simple interfaces we
--   might end up being intuitive...
-- Of course they are basically undocumented, interact
-- in odd ways with one another and show other problems,
-- but we still need one thing to ensure that LuaTeX remains interesting:
-- Let's add a fifth dimension register, with different syntax which overlaps
-- with the existing ones. I know, I am excited too :)

-- Now I could document it, but that would be way too easy. 

local attribute do
  local t = token.create'vlist@direction@attribute'
  if t.cmdname ~= 'assign_attr' then
    error[[What do you think you are doing?]]
  end
  attribute = t.index
end

local direct = node.direct

local find_attribute = direct.find_attribute
local set_attribute = direct.set_attribute
local getnext = direct.getnext
local getwidth = direct.getwidth
local getshift = direct.getshift
local setshift = direct.setshift
local getleader = direct.getleader
local getid = direct.getid
local getsubtype = direct.getsubtype
local getoffsets = direct.getoffsets
local setoffsets = direct.setoffsets

local tonode = direct.tonode
local todirect = direct.todirect

local traverse = direct.traverse

local function traverse_attr(head, attr, value)
  if value then
    return function(head, last)
      if last then
        last = getnext(last)
      else
        last = head
      end
      while last do
        local v, n = find_attribute(last, attr)
        if not n or v == value then
          return n
        else
          last = getnext(n)
        end
      end
    end, head
  else
    return function(head, last)
      if last then
        last = getnext(last)
      else
        last = head
      end
      local v, n = find_attribute(last, attr)
      return n, v
    end, head
  end
end

local hlist_t = node.id'hlist'
local vlist_t = node.id'vlist'
local unset_t = node.id'unset'
local rule_t  = node.id'rule'
local glue_t  = node.id'glue'
local leader_t = 100

luatexbase.add_to_callback('vpack_filter', function(head, _groupcode, _size, _packtype, _maxdepth, direction, _attrs)
  head = todirect(head)
  direction = direction == 'TRT' and 1 or 0
  local width = 0
  for n, id, sub in traverse(head) do
    if id == hlist_t or id == vlist_t then
      local w = getwidth(n) + getshift(n)
      if w > width then width = w end
    elseif id == unset_t or id == rule_t then
      local w = getwidth(n)
      if w > width then width = w end
    elseif id == glue_t and sub >= leader_t then
      local w = getwidth(getleader(n))
      if w > width then width = w end
    end
  end

  for n in traverse_attr(head, attribute, 1-direction) do
    local id = getid(n)
    if id == hlist_t or id == vlist_t then
      setshift(n, width - getwidth(n) - getshift(n))
    elseif id == rule_t then
      local s1, s2 = getoffsets(n)
      if direction == 1 then
        s1, s2 = s2, s1
      end
      local shift = getwidth(n) == -0x40000000 and 0 or width - getwidth(n)
      s1, s2 = s2 + 2*s1 + shift, -s1 - shift
      if direction == 1 then
        s1, s2 = s2, s1
      end
      setoffsets(n, s1, s2)
    elseif id == glue_t and getsubtype(n) >= leader_t then
      local l = getleader(n)
      local id = getid(l)
      if id == hlist_t or id == vlist_t then
        setshift(l, width - getwidth(l) - getshift(l))
      elseif id == rule_t then
        local s1, s2 = getoffsets(l)
        if direction == 1 then
          s1, s2 = s2, s1
        end
        local shift = getwidth(l) == -0x40000000 and 0 or width - getwidth(l)
        s1, s2 = s2 + 2*s1 + shift, -s1 - shift
        if direction == 1 then
          s1, s2 = s2, s1
        end
        setoffsets(l, s1, s2)
      end
    -- elseif id == whatsit_t then
    --   warning'Not implemented'
    end
    set_attribute(n, direction)
  end
  return true
end, 'vlistdirection.apply')
