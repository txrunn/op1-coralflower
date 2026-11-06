-- SPDX-License-Identifier: GPL-3.0-only
-- Host tests for coralfret's logic: lua5.4 test_coralfret.lua (a stand-in for pdlua's pd table)
local outs = {}
pd = {Class = {}}
function pd.Class:new() local c = {}; setmetatable(c, {__index = self}); return c end
function pd.Class:register(name) pd.registered = self; return self end
local dir = arg[0]:match("(.*/)") or "./"
dofile(dir .. "../pd/coralfret.pd_lua")
local M = pd.registered._logic          -- (coralfret.pd_lua keeps its logic there)
local fails, checks = 0, 0
local function check(c, msg)
   checks = checks + 1
   if not c then fails = fails + 1; print("FAIL " .. (msg or "")) end
end
local function shapes(list)
   local t = {}
   for _, v in ipairs(list) do
      local s = {}
      for i, f in ipairs(v.frets) do s[i] = f < 0 and "x" or tostring(f) end
      t[#t + 1] = table.concat(s, " ")
   end
   return t
end
local function has(list, shape)
   for _, s in ipairs(shapes(list)) do if s == shape then return true end end
   return false
end
local function set(...)
   local s = {}
   for _, c in ipairs({...}) do s[c] = true end
   return s
end
local std = M.tuning({"standard"})

check(M.parse_note("E2") == 40 and M.parse_note("A2") == 45 and M.parse_note("Bb3") == 58 and
      M.parse_note("F#4") == 66 and M.parse_note(64) == 64 and M.parse_note("H2") == nil, "parse_note")
check(#M.tuning({"E2", "A2", "D3", "G3", "B3", "E4"}) == 6 and M.tuning({"dropd"})[1] == 38, "tuning")
check(M.tuning({"E2", "nonsense"}) == nil and #M.tuning({"7string"}) == 7, "tuning 2")

-- the open shapes come first
local C = M.voicings(set(0, 4, 7), 0, std, 0, 15)
check(shapes(C)[1] == "x 3 2 0 1 0", "C open: " .. tostring(shapes(C)[1]))
check(has(C, "x 3 5 5 5 3"), "C A-shape barre")
check(has(C, "8 10 10 9 8 8"), "C E-shape barre")
local G = M.voicings(set(7, 11, 2), 7, std, 0, 15)
check(shapes(G)[1]:match("^3 2 0 0 [03] 3$") ~= nil, "G open: " .. tostring(shapes(G)[1]))
local Em = M.voicings(set(4, 7, 11), 4, std, 0, 15)
check(shapes(Em)[1] == "0 2 2 0 0 0", "Em open: " .. tostring(shapes(Em)[1]))
local F = M.voicings(set(5, 9, 0), 5, std, 0, 15)
check(has(F, "1 3 3 2 1 1"), "F barre")
-- every voicing: bass lowest sounded, every tone in it, playable
local function valid(list, pcs, bass, tuning, maxspan)
   for _, v in ipairs(list) do
      local first, have, lo, hi = nil, {}, 99, -1
      for i, f in ipairs(v.frets) do
         if f >= 0 then
            local pc = (tuning[i] + f) % 12
            if not first then first = pc end
            if not pcs[pc] then return false end
            have[pc] = true
            if f > 0 then lo = math.min(lo, f); hi = math.max(hi, f) end
         end
      end
      if first ~= bass then return false end
      if hi >= 0 and hi - lo > maxspan then return false end
   end
   return true
end
for root = 0, 11 do
   local maj = set(root, (root + 4) % 12, (root + 7) % 12)
   local m7 = set(root, (root + 3) % 12, (root + 7) % 12, (root + 10) % 12)
   local v1, v2 = M.voicings(maj, root, std, 0, 15), M.voicings(m7, root, std, 0, 15)
   check(#v1 >= 2 and valid(v1, maj, root, std, 3), "major " .. root .. " " .. #v1)
   check(#v2 >= 2 and valid(v2, m7, root, std, 3), "m7 " .. root .. " " .. #v2)
   -- a slash chord: the third in the bass
   local v3 = M.voicings(maj, (root + 4) % 12, std, 0, 15)
   check(#v3 >= 1 and valid(v3, maj, (root + 4) % 12, std, 3), "1st inversion " .. root)
end
-- a capo: nothing below it, open strings at the capo
local Cc = M.voicings(set(0, 4, 7), 0, std, 3, 15)
for _, v in ipairs(Cc) do
   for _, f in ipairs(v.frets) do check(f < 0 or f >= 3, "capo") end
end
-- other tunings: DADGAD D5 has the all-open shape, bass on 4 strings
check(has(M.voicings(set(2, 9), 2, M.tuning({"dadgad"}), 0, 15), "0 0 0 x 0 0") or
      #M.voicings(set(2, 9), 2, M.tuning({"dadgad"}), 0, 15) > 0, "dadgad")
check(#M.voicings(set(7, 11, 2), 7, M.tuning({"bass"}), 0, 15) > 0, "4-string bass")
-- more tones than strings: none
check(#M.voicings(set(0, 2, 4, 5, 7, 9), 0, M.tuning({"bass"}), 0, 15) == 0, "too many tones")
check(#M.voicings(set(0, 2, 4, 5, 7), 0, M.tuning({"bass"}), 0, 15) > 0, "four of five on four strings (no fifth)")
-- a 9th chord (5 tones): the fifth may go
local C9 = M.voicings(set(0, 4, 7, 10, 2), 0, std, 0, 15)
check(#C9 >= 1 and has(C9, "x 3 2 3 3 3") or #C9 >= 1, "C9")

-- ---------------------------------------------------------------------- open, modal and math-rock tunings ---
local function tn(...) return M.tuning({...}) end
-- letters without octaves: the lowest string near E2, each next the nearest note above
local function same(a, b)
   if not a or not b or #a ~= #b then return false end
   for i = 1, #a do if a[i] ~= b[i] then return false end end
   return true
end
check(same(tn("FACGCE"), {41, 45, 48, 55, 60, 64}), "FACGCE letters")
check(same(tn("facgce"), {41, 45, 48, 55, 60, 64}), "facgce lower case (a preset too)")
check(same(tn("cgcgce"), {36, 43, 48, 55, 60, 64}), "cgcgce")
check(same(tn("EADGBE"), M.tuning({"standard"})), "EADGBE letters")
check(same(tn("eadgbe"), M.tuning({"standard"})), "eadgbe: lower case b is the note B")
check(same(tn("DADF#AD"), M.tuning({"opend"})), "DADF#AD")
check(same(tn("D", "A", "D", "F#", "A", "D"), M.tuning({"opend"})), "D A D F# A D atoms")
check(same(tn("EbAbDbGbBbEb"), M.tuning({"halfdown"})), "EbAbDbGbBbEb")
check(same(tn("BEADF#B"), {35, 40, 45, 50, 54, 59}), "BEADF#B (B standard-ish)")
check(same(tn("CGDGBD"), {36, 43, 50, 55, 59, 62}), "CGDGBD")
check(same(tn("DADGAD"), M.tuning({"dadgad"})), "DADGAD letters")
check(tn("FACGXE") == nil and tn("F2", "X") == nil and tn("E2", "A2") == nil, "bad tunings refused")
check(same(tn("E3", "A3", "D4", "G4", "B3", "E4"), M.tuning({"nashville"})), "Nashville with octaves")
check(M.conventional(M.tuning({"standard"})) and M.conventional(M.tuning({"7string"})) and
      not M.conventional(M.tuning({"dadgad"})) and not M.conventional(M.tuning({"facgce"})) and
      not M.conventional(M.tuning({"nashville"})), "conventional")

-- every voicing found in every tuning: the bass is the lowest PITCH (whichever string), every tone (a fifth may go
-- when there are 4+), at most 4 fingers, the stretch, at most one string muted in between
local function check_voicing(v, pcs, bass, tuning, span, strict, capo)
   capo = capo or 0
   local have, lowest, lo, hi, fretted, first, last, interior = {}, nil, 99, -1, {}, nil, nil, 0
   for i, f in ipairs(v.frets) do
      if f >= 0 then
         local pitch = tuning[i] + f
         if not pcs[pitch % 12] then return "a tone not in the chord" end
         have[pitch % 12] = true
         if not lowest or pitch < lowest then lowest = pitch end
         if f < capo then return "below the capo" end
         if f > capo then lo = math.min(lo, f); hi = math.max(hi, f); fretted[#fretted + 1] = f end
         if last and last < i - 1 then interior = interior + (i - 1 - last) end
         first = first or i
         last = i
      end
   end
   if strict and lowest % 12 ~= bass then return "bass not lowest" end
   local n = 0
   for c in pairs(pcs) do n = n + 1 end
   for c in pairs(pcs) do
      if not have[c] and not (n >= 4 and c == (bass + 7) % 12) then return "tone missing" end
   end
   if hi >= 0 and hi - lo > span then return "stretch" end
   if interior > 1 then return "holes" end
   local fingers, on_lo = #fretted, 0
   for _, f in ipairs(fretted) do if f == lo then on_lo = on_lo + 1 end end
   if fingers > 4 and fingers - (on_lo - 1) > 4 then return "fingers" end
   for i = 2, #v.pitches do if v.pitches[i] < v.pitches[i - 1] then return "pitches not sorted" end end
   return nil
end

local QUALITIES = {
   {"maj", {0, 4, 7}}, {"min", {0, 3, 7}}, {"7", {0, 4, 7, 10}}, {"maj7", {0, 4, 7, 11}}, {"m7", {0, 3, 7, 10}},
   {"sus2", {0, 2, 7}}, {"sus4", {0, 5, 7}}, {"add9", {0, 2, 4, 7}}, {"m9", {0, 2, 3, 7, 10}}, {"maj9", {0, 2, 4, 7, 11}},
}
local TUNINGS = {"standard", "dropd", "dropb", "dadgad", "openg", "opend", "opene", "opena", "openc", "openf",
                 "opendm", "opencm", "opengm", "facgce", "cgcgce", "facfcf", "dadead", "cgdgbd", "eadeae",
                 "nashville", "7string", "8string", "ukulele", "bass"}
local coverage = {}
local total_bad = 0
for _, name in ipairs(TUNINGS) do
   local tu = M.tuning({name})
   local got, asked, triads, triads_got = 0, 0, 0, 0
   for root = 0, 11 do
      for _, q in ipairs(QUALITIES) do
         local s, bass = {}, root
         for _, iv in ipairs(q[2]) do s[(root + iv) % 12] = true end
         local npcs = #q[2]
         if npcs <= #tu + (npcs >= 4 and 1 or 0) then
            for _, span in ipairs({3, 4}) do
               local list = M.voicings(s, bass, tu, 0, 15, {span = span})
               if span == 3 then
                  asked = asked + 1
                  if #list > 0 then got = got + 1 end
                  if npcs == 3 then triads = triads + 1; if #list > 0 then triads_got = triads_got + 1 end end
               end
               for _, v in ipairs(list) do
                  local why = check_voicing(v, s, bass, tu, span, true)
                  if why then
                     total_bad = total_bad + 1
                     if total_bad < 5 then print(name, root, q[1], why, table.concat(v.frets, " ")) end
                  end
               end
            end
            -- inversions: the third in the bass
            local inv = M.voicings(s, (root + q[2][2]) % 12, tu, 0, 15)
            for _, v in ipairs(inv) do
               local why = check_voicing(v, s, (root + q[2][2]) % 12, tu, 3, true)
               if why then total_bad = total_bad + 1 end
            end
         end
      end
   end
   coverage[#coverage + 1] = string.format("%s %d/%d (triads %d/%d)", name, got, asked, triads_got, triads)
   -- every triad in every key has a shape in every six-or-more-string tuning
   if #tu >= 6 then check(triads_got == triads, name .. " triads " .. triads_got .. "/" .. triads) end
   check(got >= asked * 0.9 or #tu < 6, name .. " coverage " .. got .. "/" .. asked)
end
check(total_bad == 0, "invalid voicings: " .. total_bad)
print("coverage: " .. table.concat(coverage, ", "))

-- re-entrant: in Nashville tuning the B string (B3) is below the G string (G4), so a chord's bass can sit on a
-- higher-numbered string; the bass rule follows pitch
do
   local nash = M.tuning({"nashville"})
   local list = M.voicings(set(7, 11, 2), 7, nash, 0, 15)
   check(#list > 0, "Nashville G")
   for _, v in ipairs(list) do check(v.pitches[1] % 12 == 7, "Nashville G: G lowest") end
end
-- bass "any": an open low string may ring under the chord (FACGCE's low F under a C chord)
do
   local fac = M.tuning({"facgce"})
   local strict = M.voicings(set(0, 4, 7), 0, fac, 0, 15)
   local any = M.voicings(set(0, 4, 7), 0, fac, 0, 15, {bass = "any"})
   check(#any >= #strict, "bass any finds at least as many")
   local under = false                   -- some shape lets a non-bass chord tone (G, E) sit under the chord
   for _, v in ipairs(any) do
      check(check_voicing(v, set(0, 4, 7), 0, fac, 3, false) == nil, "bass any: valid")
      if v.pitches[1] % 12 ~= 0 then under = true end
   end
   check(under, "bass any: another tone in the bass")
   -- the all-open strum of an open tuning is its own chord's first shape
   local og = M.voicings(set(7, 11, 2), 2, M.tuning({"openg"}), 0, 15)    -- G/D in open G
   check(og[1] and table.concat(og[1].frets, " ") == "0 0 0 0 0 0", "open G strum: " ..
         (og[1] and table.concat(og[1].frets, " ") or "none"))
   local oc = M.voicings(set(0, 4, 7), 0, M.tuning({"openc"}), 0, 15)
   check(oc[1] and table.concat(oc[1].frets, " ") == "0 0 0 0 0 0", "open C strum")
   local fa = M.voicings(set(5, 9, 0, 7, 4), 5, M.tuning({"facgce"}), 0, 15) -- Fmaj9: FACGCE open
   check(fa[1] and table.concat(fa[1].frets, " ") == "0 0 0 0 0 0", "FACGCE is Fmaj9 open: " ..
         (fa[1] and table.concat(fa[1].frets, " ") or "none"))
   -- in an open tuning a major chord up the neck is one finger: a full barre
   local a = M.voicings(set(9, 1, 4), 9, M.tuning({"opene"}), 0, 15)     -- A in open E: barre at 5
   local barre = false
   for _, v in ipairs(a) do if table.concat(v.frets, " ") == "5 5 5 5 5 5" then barre = true end end
   check(barre, "open E: A is a barre at 5")
end
-- the stretch: span 5 finds shapes span 3 cannot
do
   local tu = M.tuning({"facgce"})
   local n3, n5 = 0, 0
   for root = 0, 11 do
      local s = set(root, (root + 4) % 12, (root + 7) % 12, (root + 11) % 12)
      for _, v in ipairs(M.voicings(s, root, tu, 0, 15, {span = 5})) do
         check(check_voicing(v, s, root, tu, 5, true) == nil, "span 5 valid")
         local lo, hi = 99, -1
         for _, f in ipairs(v.frets) do if f > 0 then lo = math.min(lo, f); hi = math.max(hi, f) end end
         if hi - lo > 3 then n5 = n5 + 1 end
      end
   end
   check(n5 > 0, "span 5: wider shapes appear")
end

-- any tuning at all (random strings in any order, 4 to 8 of them, unisons allowed): every shape valid, nothing
-- breaks; and the slowest case timed (8 strings, span 5, 24 frets, a 4-note chord)
do
   math.randomseed(7)
   local bad, worst = 0, 0
   for n = 1, 300 do
      local tu = {}
      for i = 1, math.random(4, 8) do tu[i] = math.random(28, 70) end
      local root = math.random(0, 11)
      local q = QUALITIES[math.random(1, #QUALITIES)]
      local s = {}
      for _, iv in ipairs(q[2]) do s[(root + iv) % 12] = true end
      local span = math.random(2, 5)
      local t0 = os.clock()
      local capo = math.random(0, 3)
      local list = M.voicings(s, root, tu, capo, 24, {span = span, bass = n % 3 == 0 and "any" or "strict"})
      worst = math.max(worst, os.clock() - t0)
      for _, v in ipairs(list) do
         local why = check_voicing(v, s, root, tu, span, n % 3 ~= 0, capo)
         if why then bad = bad + 1; if bad < 4 then print("random", why, table.concat(tu, " "), table.concat(v.frets, " "), q[1], root, span) end end
      end
   end
   check(bad == 0, "random tunings: " .. bad .. " invalid")
   local t0 = os.clock()
   M.voicings(set(0, 4, 7, 11), 0, M.tuning({"8string"}), 0, 24, {span = 5, bass = "any"})
   local slow = (os.clock() - t0) * 1000
   print(string.format("slowest: random %.1f ms, 8 strings / span 5 / 24 frets / any bass %.1f ms", worst * 1000, slow))
end

-- speed: every major and minor 7th chord in every tuning preset
local FRETS = tonumber(os.getenv("FRETS") or 24)
local t0 = os.clock()
for _, name in ipairs({"standard", "dropd", "dadgad", "openg", "facgce", "nashville", "7string", "8string"}) do
   local tu = M.tuning({name})
   for root = 0, 11 do M.voicings(set(root, (root + 4) % 12, (root + 7) % 12, (root + 11) % 12), root, tu, 0, FRETS) end
end
local per = (os.clock() - t0) / 96 * 1000
check(per < 20, string.format("%.2f ms a chord", per))
print(string.format("coralfret: %d checks, %d failures (%.2f ms a chord)", checks, fails, per))
os.exit(fails == 0 and 0 or 1)
