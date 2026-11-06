-- SPDX-License-Identifier: GPL-3.0-only
-- [coralfret]: CoralOP's chords on a guitar neck (pdlua 0.12+, built into plugdata).
--
-- Shows every chord tone along the neck (root coral, bass blue, the rest green) and a playable voicing: one note a
-- string, at most four fingers (a barre counts as one), within four frets (span) or open strings, the chord's bass
-- the lowest note sounded (whichever string carries it: re-entrant tunings work). Click < > (or send "pos next|prev") to walk the voicings up the neck. The voicing can go out
-- as MIDI (outlet 2), strummed, so a guitar instrument in your DAW plays the chord as a guitarist would.
--
-- inlet 1:
--   list pitch vel ch     notes as from [notein]: the chord channel's and the bass channel's notes are the chord
--   chord <name>          the chord's name (CoralOP's state), shown; "chord -": none
--   root <pc>             the chord's root pitch class (-1: none)
--   tuning <notes...>     low string first: E2 A2 D3 G3 B3 E4, MIDI numbers, letters (FACGCE, DADF#AD, F A C G C E:
--                         the lowest string near E2, each next one the nearest note above; a string lower than the
--                         one below it, as in Nashville tuning, needs octaves), or a preset:
--                         standard halfdown fulldown dropd dropc dropb | openg opend opene opena openc openf opendm
--                         opencm opengm | dadgad facgce cgcgce facfcf dadead cgdgbd eadeae | nashville ukulele |
--                         7string 8string bass bass5
--   capo <fret>  frets <12..24>  lefty <0/1>  channels <chord ch> <bass ch>  spell flat|sharp|auto
--   span <2..5>           how far a hand stretches past its first fret (3: four frets)
--   bass strict|any       strict: the chord's bass is the lowest note; any: any chord tone may be (open low strings
--                         ringing under the chord), the bass preferred
--   pos next|prev|<n>     the voicing shown (1 = lowest on the neck)
--   out <0/1>  outch <1..16>  strum <ms>  vel <1..127>    the voicing as MIDI (outlet 2: "note pitch vel delay_ms")
--   clear                 forget the chord
-- outlet 1: "shape f1 f2 ..." (low string first, -1 muted), "voicing p1 p2 ..." (MIDI pitches), "count n", "pos i"
-- outlet 2: "note pitch vel delay" (vel 0: off, delay in ms from now), "clear" (drop the strum's pending notes:
--           [pipe]'s clear) and "ch n" when the output channel changes

local fret = pd.Class:new():register("coralfret")

local NAMES_SHARP = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local NAMES_FLAT = {"C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"}
local LETTER = {C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11}

local PRESETS = {
   -- standard and down-tuned
   standard = {40, 45, 50, 55, 59, 64}, halfdown = {39, 44, 49, 54, 58, 63}, fulldown = {38, 43, 48, 53, 57, 62},
   dropd = {38, 45, 50, 55, 59, 64}, dropc = {36, 43, 48, 53, 57, 62}, dropb = {35, 42, 47, 52, 56, 61},
   -- open
   openg = {38, 43, 50, 55, 59, 62}, opend = {38, 45, 50, 54, 57, 62}, opene = {40, 47, 52, 56, 59, 64},
   opena = {40, 45, 52, 57, 61, 64}, openc = {36, 43, 48, 55, 60, 64}, openf = {36, 41, 48, 53, 57, 60},
   opendm = {38, 45, 50, 53, 57, 62}, opencm = {36, 43, 48, 55, 60, 63}, opengm = {38, 43, 50, 55, 58, 62},
   -- modal / math rock / emo
   dadgad = {38, 45, 50, 55, 57, 62}, facgce = {41, 45, 48, 55, 60, 64}, cgcgce = {36, 43, 48, 55, 60, 64},
   facfcf = {41, 45, 48, 53, 60, 65}, dadead = {38, 45, 50, 52, 57, 62}, cgdgbd = {36, 43, 50, 55, 59, 62},
   eadeae = {40, 45, 50, 52, 57, 64},
   -- re-entrant (a string lower than the one below it)
   nashville = {52, 57, 62, 67, 59, 64}, ukulele = {67, 60, 64, 69},
   -- more or fewer strings
   ["7string"] = {35, 40, 45, 50, 55, 59, 64}, ["8string"] = {30, 35, 40, 45, 50, 55, 59, 64},
   bass = {28, 33, 38, 43}, bass5 = {23, 28, 33, 38, 43},
}
fret._presets = PRESETS

-- ------------------------------------------------------------------------------------------------ the logic ---
local M = {}
fret._logic = M

-- "E2", "Bb3", "F#4", or a number -> MIDI pitch (nil if neither)
function M.parse_note(a)
   if type(a) == "number" then return math.floor(a) end
   if type(a) ~= "string" then return nil end
   local l, acc, oct = a:match("^([A-Ga-g])([#b]?)(%-?%d)$")
   if not l then return nil end
   local p = LETTER[l:upper()] + (acc == "#" and 1 or acc == "b" and -1 or 0)
   return 12 * (tonumber(oct) + 1) + p
end

-- note names with no octave -> pitch classes: "FACGCE", "EbAbDbGbBbEb", "DADF#AD", or the atoms F A C G C E.
-- With capitals, capitals are notes and b / # follow them; all lower case ("facgce"), every letter is a note.
function M.parse_letters(atoms)
   local s = {}
   for _, a in ipairs(atoms) do
      if type(a) ~= "string" then return nil end
      s[#s + 1] = a
   end
   s = table.concat(s)
   if s == "" then return nil end
   local caps = s:find("%u") ~= nil
   local pcs, i = {}, 1
   while i <= #s do
      local ch = s:sub(i, i)
      local base = caps and ch:match("%u") and LETTER[ch] or (not caps and LETTER[ch:upper()])
      if not base or (caps and not ch:match("%u")) then return nil end
      i = i + 1
      local nx = s:sub(i, i)
      if nx == "#" then base = base + 1; i = i + 1
      elseif caps and nx == "b" then base = base - 1; i = i + 1 end
      pcs[#pcs + 1] = base % 12
   end
   return pcs
end

-- pitch classes, low string first -> pitches: the lowest string between B1 and A#2, each next one the nearest
-- pitch above the one before (a tuning with a string lower than the one below it needs octaves: E3 A3 D4 G4 B3 E4)
function M.place(pcs)
   local t = {}
   for i, c in ipairs(pcs) do
      if i == 1 then
         t[1] = 36 + (c - 36) % 12
         if t[1] < 35 then t[1] = t[1] + 12 end
         if t[1] > 46 then t[1] = t[1] - 12 end
      else
         local p = t[i - 1] + 1
         while p % 12 ~= c do p = p + 1 end
         t[i] = p
      end
   end
   return t
end

function M.tuning(atoms)
   if #atoms == 1 and type(atoms[1]) == "string" and PRESETS[atoms[1]:lower()] then
      local t = {}
      for i, p in ipairs(PRESETS[atoms[1]:lower()]) do t[i] = p end
      return t
   end
   local t = {}
   for i, a in ipairs(atoms) do
      local p = M.parse_note(a)
      if not p then t = nil; break end
      t[i] = p
   end
   if not t then
      local pcs = M.parse_letters(atoms)
      if not pcs then return nil end
      t = M.place(pcs)
   end
   if #t < 3 or #t > 10 then return nil end
   for _, p in ipairs(t) do if p < 12 or p > 100 then return nil end end
   return t
end

-- the pitch-class set (a table pc -> true) and its size
local function pcset(pitches)
   local s, n = {}, 0
   for _, p in ipairs(pitches) do
      local c = p % 12
      if not s[c] then s[c] = true; n = n + 1 end
   end
   return s, n
end

-- a tuning in fourths and a third, rising string to string (standard, half down, 7-string, bass): its open strings
-- ring well only in the first position, so the search keeps them there
function M.conventional(tuning)
   for i = 2, #tuning do
      local d = tuning[i] - tuning[i - 1]
      if d < 3 or d > 5 then return false end
   end
   return true
end

-- voicings of a chord: pcs (pc -> true), bass (pc), tuning (low string first; any order of pitches), capo, nfrets,
-- opts.span (the frets a hand covers beyond the first: 3, 4 or 5), opts.bass ("strict": the chord's bass is the
-- lowest pitch sounded; "any": any chord tone, the bass preferred).
-- Returns a list, up the neck, of {frets = {...}, pitches = {...}, low = <lowest fretted fret>, score, win}
function M.voicings(pcs, bass, tuning, capo, nfrets, opts)
   opts = opts or {}
   local span = math.max(2, math.min(5, opts.span or 3))
   local strict = (opts.bass or "strict") == "strict"
   local ns = #tuning
   local rising = true                   -- each string higher than the one below: the lowest string sounded
   for i = 2, ns do                      -- is the lowest pitch, and the search can stop early on it
      if tuning[i] <= tuning[i - 1] then rising = false end
   end
   local conventional = M.conventional(tuning)
   local npcs = 0
   for c in pairs(pcs) do npcs = npcs + 1 end
   local fifth = (bass + 7) % 12
   local optional_fifth = npcs >= 4 and pcs[fifth] and fifth ~= bass
   if npcs > ns + (optional_fifth and 1 or 0) then return {} end
   local need, fifth_bit = 0, 1 << fifth
   for c in pairs(pcs) do need = need | (1 << c) end
   local function popcount(x)
      local n = 0
      while x ~= 0 do x = x & (x - 1); n = n + 1 end
      return n
   end
   local budget = opts.budget or 2000
   M.nodes_cut = 0
   local found, seen = {}, {}
   for p = capo, math.max(capo, nfrets - span) do
      local kept = {}                    -- the window's two best: {score, frets}
      local frets = {}
      -- each string's choices here, the sounded ones first (good shapes come early, and the bound below then
      -- cuts the rest): the window's frets on chord tones, the open string, last of all mute
      local opts_s, minrest = {}, {}
      for s = 1, ns do
         local o = {}
         for f = p, math.min(p + span, nfrets) do
            if pcs[(tuning[s] + f) % 12] then o[#o + 1] = f end
         end
         if p > capo and pcs[(tuning[s] + capo) % 12] then o[#o + 1] = capo end
         opts_s[s] = o
      end
      minrest[ns + 1] = math.huge        -- the lowest pitch strings s.. could still add
      for s = ns, 1, -1 do
         local m = minrest[s + 1]
         for _, f in ipairs(opts_s[s]) do m = math.min(m, tuning[s] + f) end
         minrest[s] = m
      end
      local function leaf(sounded, first, interior, lo, hi, opens, lowest)
         if not first or sounded < math.min(3, ns) then return end
         local low_ok = lowest % 12 == bass
         if strict and not low_ok then return end
         local fingers = 0
         for i = 1, ns do if frets[i] > capo then fingers = fingers + 1 end end
         if fingers > 4 then             -- a barre on the lowest fretted fret takes one finger for all of it
            local on_lo, b1, b2 = 0, nil, nil
            for i = 1, ns do
               if frets[i] == lo then
                  on_lo = on_lo + 1
                  b1 = b1 or i
                  b2 = i
               end
            end
            fingers = fingers - math.max(0, on_lo - 1)
            if fingers > 4 then return end
            for i = b1, b2 do            -- the barre frets every string under it: none may ring open there
               if frets[i] >= 0 and frets[i] < lo then return end
            end
         end
         if hi >= 0 and hi - lo > span then return end
         local l, h = hi >= 0 and lo or p, hi >= 0 and hi or p
         local o = conventional and (h >= 5 and opens * 2.5 or 0) or -opens * 0.3
         local sc = -sounded * 3 + interior * 6 + (h - l) + fingers * 0.5 + first * 0.2 + o + (low_ok and 0 or 4)
         if #kept == 2 and sc >= kept[2][1] then return end
         local copy = {}
         for i = 1, ns do copy[i] = frets[i] end
         kept[#kept + 1] = {sc, copy}
         table.sort(kept, function(x, y) return x[1] < y[1] end)
         if #kept > 2 then kept[3] = nil end
      end
      -- depth first over the strings, with what is known so far carried along; cut when the tones still missing
      -- outnumber the strings left, when the bass can no longer be lowest, at a second hole, or when even the best
      -- finish could not beat the two shapes kept
      local nodes = 0
      local function walk(s, sounded, first, last, interior, lo, hi, opens, lowest, have)
         nodes = nodes + 1               -- (a budget per place on the neck keeps the worst case short: the
         if nodes > budget then return end   -- good shapes come first, so a cut search still has them)
         local left = ns - s + 1
         local missing = need & ~have
         local nmiss = popcount(missing) - ((optional_fifth and missing & fifth_bit ~= 0) and 1 or 0)
         if nmiss > left then return end
         if strict and lowest and lowest % 12 ~= bass and lowest <= minrest[s] then return end
         if #kept == 2 then
            local bound = -3 * (sounded + left) + interior * 6 + (hi >= 0 and hi - lo or 0) + (first or 1) * 0.2 +
                          (conventional and (hi >= 5 and opens * 2.5 or 0) or -0.3 * (opens + left))
            if bound >= kept[2][1] then return end
         end
         if s > ns then
            leaf(sounded, first, interior, lo, hi, opens, lowest)
            return
         end
         local need_bass = rising and strict and not first
         for _, f in ipairs(opts_s[s]) do
            local pitch = tuning[s] + f
            local pc = pitch % 12
            if not need_bass or pc == bass then
               local hole = (last and last < s - 1) and (s - 1 - last) or 0
               if interior + hole <= 1 then
                  frets[s] = f
                  local fl, fh = lo, hi
                  if f > capo then
                     if f < fl then fl = f end
                     if f > fh then fh = f end
                  end
                  walk(s + 1, sounded + 1, first or s, s, interior + hole, fl, fh, opens + (f == capo and 1 or 0),
                       (lowest and lowest < pitch) and lowest or pitch, have | (1 << pc))
               end
            end
         end
         frets[s] = -1                   -- mute: low down, at the top, or one hole in between
         walk(s + 1, sounded, first, last, interior, lo, hi, opens, lowest, have)
      end
      walk(1, 0, nil, nil, 0, 99, -1, 0, nil, 0)
      if nodes > budget then M.nodes_cut = M.nodes_cut + 1 end
      for _, k in ipairs(kept) do
         local best = k[2]
         local key = table.concat(best, ",")
         if not seen[key] then
            seen[key] = true
            local v = {frets = best, pitches = {}, low = 99, score = k[1], win = p}
            for i = 1, ns do
               if best[i] >= 0 then
                  v.pitches[#v.pitches + 1] = tuning[i] + best[i]
                  if best[i] > capo and best[i] < v.low then v.low = best[i] end
               end
            end
            table.sort(v.pitches)
            if v.low == 99 then v.low = capo end
            found[#found + 1] = v
         end
      end
   end
   table.sort(found, function(a, b)
      if a.win ~= b.win then return a.win < b.win end      -- (up the neck, the better shape first at each place)
      if a.score ~= b.score then return a.score < b.score end
      return table.concat(a.frets, ",") < table.concat(b.frets, ",")
   end)
   return found
end

-- ----------------------------------------------------------------------------------------------- the object ---
function fret:initialize(sel, atoms)
   self.inlets = 1
   self.outlets = 2
   self.tuning = M.tuning({"standard"})
   self.capo, self.nfrets, self.lefty = 0, 15, 0
   self.span, self.bassmode = 3, "strict"
   self.chord_ch, self.bass_ch = 1, 2
   self.held = {}                        -- channel -> {pitch -> true}
   self.pitches, self.bass = {}, nil     -- the chord as heard (or the last one)
   self.sounding = false
   self.name, self.root, self.spell = "-", -1, "auto"
   self.list, self.pos = {}, 1
   self.out, self.outch, self.strum, self.vel = 0, 3, 25, 90
   self.playing = {}                     -- the voicing pitches sent out
   self.W, self.H = 760, 210
   self:set_size(self.W, self.H)
   if #atoms > 0 then                   -- creation arguments: a tuning preset or notes ([coralfret dropd])
      self.tuning = M.tuning(atoms) or self.tuning
   end
   return true
end

function fret:postinitialize()
   self.clock = pd.Clock:new():register(self, "settle")
end

function fret:finalize()
   if self.clock then self.clock:destruct() end
end

-- the notes on the chord / bass channels changed: let a whole chord arrive, then work it out
function fret:in_1_list(atoms)
   local p, v, ch = atoms[1], atoms[2] or 0, atoms[3] or self.chord_ch
   if type(p) ~= "number" then return end
   if ch ~= self.chord_ch and ch ~= self.bass_ch then return end
   self.held[ch] = self.held[ch] or {}
   self.held[ch][p] = v > 0 or nil
   if self.clock then self.clock:delay(8) else self:settle() end
end

function fret:settle()
   local ps, bassp = {}, nil
   for ch, set in pairs(self.held) do
      for p in pairs(set) do
         ps[#ps + 1] = p
         if ch == self.bass_ch and (not bassp or p < bassp) then bassp = p end
      end
   end
   table.sort(ps)
   if #ps == 0 then
      self.sounding = false              -- (the last chord stays, dimmed)
      self:send_voicing(nil)
      self:repaint()
      return
   end
   self.sounding = true
   self.pitches = ps
   self.bass = (bassp or ps[1]) % 12
   self:recompute(true)
end

function fret:recompute(keep_position)
   local set, n = pcset(self.pitches)
   local old = self.list[self.pos]
   if n >= 2 then
      self.list = M.voicings(set, self.bass, self.tuning, self.capo, self.nfrets,
                             {span = self.span, bass = self.bassmode})
   else
      self.list = {}
   end
   -- the new chord's voicing nearest to where the hand was
   local pos = 1
   if keep_position and old and #self.list > 0 then
      local d = 99
      for i, v in ipairs(self.list) do
         if math.abs(v.low - old.low) < d then d = math.abs(v.low - old.low); pos = i end
      end
   end
   self.pos = pos
   self:report()
   if self.sounding then self:send_voicing(self.list[self.pos]) end
   self:repaint()
end

function fret:report()
   local v = self.list[self.pos]
   self:outlet(1, "count", {#self.list})
   if v then
      self:outlet(1, "pos", {self.pos})
      self:outlet(1, "shape", v.frets)
      self:outlet(1, "voicing", v.pitches)
   end
end

-- the voicing out as MIDI: the old notes off, the new strummed low to high
function fret:send_voicing(v)
   if #self.playing > 0 then self:outlet(2, "clear", {}) end   -- (a strum still going: its late notes dropped)
   for _, p in ipairs(self.playing) do self:outlet(2, "note", {p, 0, 0}) end
   self.playing = {}
   if not v or self.out == 0 then return end
   for i, p in ipairs(v.pitches) do
      self:outlet(2, "note", {p, self.vel, (i - 1) * self.strum})
      self.playing[#self.playing + 1] = p
   end
end

function fret:in_1_chord(atoms)
   self.name = atoms[1] ~= nil and tostring(atoms[1]) or "-"
   self:repaint()
end

function fret:in_1_root(atoms)
   self.root = type(atoms[1]) == "number" and atoms[1] or -1
   self:repaint()
end

function fret:in_1_tuning(atoms)
   local t = M.tuning(atoms)
   if not t then
      self:error("coralfret: tuning wants notes (E2 A2 ...), MIDI numbers or a preset")
      return
   end
   self.tuning = t
   self:recompute(true)
end

function fret:in_1_capo(atoms)
   self.capo = math.max(0, math.min(12, math.floor(atoms[1] or 0)))
   self:recompute(true)
end

function fret:in_1_frets(atoms)
   self.nfrets = math.max(12, math.min(24, math.floor(atoms[1] or 15)))
   self:recompute(true)
end

function fret:in_1_span(atoms)
   self.span = math.max(2, math.min(5, math.floor(atoms[1] or 3)))
   self:recompute(true)
end

function fret:in_1_bass(atoms)
   self.bassmode = atoms[1] == "any" and "any" or "strict"
   self:recompute(true)
end

function fret:in_1_lefty(atoms)
   self.lefty = (atoms[1] or 0) ~= 0 and 1 or 0
   self:repaint()
end

function fret:in_1_channels(atoms)
   self.chord_ch, self.bass_ch = atoms[1] or 1, atoms[2] or 2
   self.held = {}
end

function fret:in_1_spell(atoms)
   self.spell = tostring(atoms[1] or "auto")
   self:repaint()
end

function fret:in_1_pos(atoms)
   local n = #self.list
   if n == 0 then return end
   local a = atoms[1]
   if a == "next" then self.pos = self.pos % n + 1
   elseif a == "prev" then self.pos = (self.pos - 2) % n + 1
   elseif type(a) == "number" then self.pos = math.max(1, math.min(n, math.floor(a))) end
   self:report()
   if self.sounding then self:send_voicing(self.list[self.pos]) end
   self:repaint()
end

function fret:in_1_out(atoms)
   self.out = (atoms[1] or 0) ~= 0 and 1 or 0
   if self.out == 0 then self:send_voicing(nil) end
end

function fret:in_1_outch(atoms)
   self:send_voicing(nil)
   self.outch = math.max(1, math.min(16, math.floor(atoms[1] or 3)))
   self:outlet(2, "ch", {self.outch})
end

function fret:in_1_strum(atoms)
   self.strum = math.max(0, math.min(200, atoms[1] or 25))
end

function fret:in_1_vel(atoms)
   self.vel = math.max(1, math.min(127, math.floor(atoms[1] or 90)))
end

function fret:in_1_clear()
   self.held, self.pitches, self.bass, self.list, self.sounding = {}, {}, nil, {}, false
   self:send_voicing(nil)
   self:repaint()
end

function fret:in_1_bang()
   self:report()
end

-- ------------------------------------------------------------------------------------------------ drawing ---
local BG = {28, 26, 32}
local WOOD = {42, 38, 46}
local STR = {150, 146, 160}
local FRETC = {90, 86, 100}
local DIM = {90, 88, 102}
local TXT = {230, 230, 230}
local CORAL = {255, 127, 106}
local ORANGE = {255, 106, 61}
local GREEN = {0, 237, 149}
local BLUE = {105, 142, 255}

local HEAD, LEFT, BOTTOM = 34, 56, 22

function fret:geometry()
   local ns = #self.tuning
   local fw = (self.W - LEFT - 10) / (self.nfrets + 0.5)
   local sh = (self.H - HEAD - BOTTOM) / ns
   return ns, fw, sh
end

-- x of the middle of fret f's space (f = 0: left of the nut), y of string i (1 = lowest, drawn at the bottom)
function fret:fx(f)
   local _, fw = self:geometry()
   local x = f == 0 and LEFT - 18 or LEFT + (f - 0.5) * fw
   if self.lefty == 1 then x = self.W - x end
   return x
end

function fret:sy(i)
   local ns, _, sh = self:geometry()
   return HEAD + (ns - i + 0.5) * sh
end

function fret:pcname(pc)
   local flat = self.spell == "flat" or (self.spell == "auto" and self.name:sub(2, 2) == "b")
   return (flat and NAMES_FLAT or NAMES_SHARP)[pc % 12 + 1]
end

local function col(g, c, a) g:set_color(c[1], c[2], c[3], a or 1) end

function fret:paint(g)
   local ns, fw, sh = self:geometry()
   col(g, BG); g:fill_all()
   -- header: the name, the position, the tuning
   col(g, self.sounding and TXT or DIM)
   g:draw_text(self.name, 8, 6, 200, 20)
   local n = #self.list
   col(g, n > 0 and CORAL or DIM)
   g:draw_text("<", 240, 8, 20, 16)
   g:draw_text(">", 330, 8, 20, 16)
   col(g, TXT)
   local v = self.list[self.pos]
   local where = "no shape"
   if n > 0 then
      local fretted = false
      for _, f in ipairs(v.frets) do if f > self.capo then fretted = true end end
      where = string.format("%d/%d  %s", self.pos, n, fretted and ("fr " .. v.low) or "open")
   end
   g:draw_text(where, 258, 10, 80, 11)
   local tn = {}
   for i, p in ipairs(self.tuning) do tn[i] = self:pcname(p) end
   col(g, DIM)
   g:draw_text("tuning " .. table.concat(tn, " ") .. (self.capo > 0 and ("  capo " .. self.capo) or "") ..
               (self.out == 1 and ("  -> MIDI ch " .. self.outch) or ""), 370, 4, 380, 11)
   local lx = 370                         -- the legend
   for _, it in ipairs({{CORAL, "root"}, {BLUE, "bass"}, {GREEN, "chord tone"}}) do
      col(g, it[1]); g:fill_ellipse(lx, 20, 8, 8)
      col(g, DIM); g:draw_text(it[2], lx + 11, 18, 80, 10)
      lx = lx + 22 + 6 * #it[2]
   end
   -- the neck
   local x0, x1 = self:fx(0.5), self:fx(self.nfrets + 0.5)
   if x0 > x1 then x0, x1 = x1, x0 end
   col(g, WOOD)
   g:fill_rect(x0, HEAD, x1 - x0, ns * sh)
   for f = 1, self.nfrets do              -- markers
      if f % 12 == 3 or f % 12 == 5 or f % 12 == 7 or f % 12 == 9 or f % 12 == 0 then
         col(g, {60, 56, 66})
         local cx, cy = self:fx(f), HEAD + ns * sh / 2
         if f % 12 == 0 then
            g:fill_ellipse(cx - 4, cy - sh - 4, 8, 8); g:fill_ellipse(cx - 4, cy + sh - 4, 8, 8)
         else
            g:fill_ellipse(cx - 4, cy - 4, 8, 8)
         end
      end
      col(g, DIM)
      g:draw_text(tostring(f), self:fx(f) - 5, HEAD + ns * sh + 5, 20, 10)
   end
   for f = 0, self.nfrets do              -- frets (the nut thicker)
      local x = self:fx(f + 0.5)
      col(g, f == self.capo and (self.capo > 0 and ORANGE or STR) or FRETC)
      g:fill_rect(x - (f == self.capo and 2 or 1), HEAD, f == self.capo and 4 or 2, ns * sh)
   end
   for i = 1, ns do                       -- strings, their open notes
      local y = self:sy(i)
      col(g, STR)
      local higher = 0                    -- (thickness follows pitch, not place: re-entrant tunings)
      for j = 1, ns do if self.tuning[j] > self.tuning[i] then higher = higher + 1 end end
      g:fill_rect(x0, y - 0.5, x1 - x0, 1 + higher * 0.25)
      col(g, DIM)
      g:draw_text(self:pcname(self.tuning[i]), self.lefty == 1 and self.W - 18 or 4, y - 6, 20, 10)
   end
   -- the chord: every tone along the neck small, the voicing large
   if #self.pitches == 0 then return end
   local set = pcset(self.pitches)
   local alpha = self.sounding and 1 or 0.45
   local function tone_color(pc)
      if pc == self.bass then return BLUE end
      if self.root >= 0 and pc == self.root then return CORAL end
      return GREEN
   end
   for i = 1, ns do
      for f = self.capo, self.nfrets do
         local pc = (self.tuning[i] + f) % 12
         if set[pc] then
            local on = v and v.frets[i] == f
            local r = on and math.min(sh, fw) * 0.42 or 4
            local cx, cy = self:fx(f), self:sy(i)
            col(g, tone_color(pc), on and alpha or alpha * 0.55)
            g:fill_ellipse(cx - r, cy - r, 2 * r, 2 * r)
            if on then
               col(g, BG)
               g:draw_text(self:pcname(pc), cx - r + 2, cy - 5, 2 * r, 10)
            end
         end
      end
      if v and v.frets[i] < 0 then        -- a muted string
         col(g, DIM)
         g:draw_text("x", self:fx(0) - 3, self:sy(i) - 6, 12, 11)
      end
   end
end

function fret:mouse_down(x, y)
   if y < HEAD then
      if x >= 232 and x < 258 then self:in_1_pos({"prev"})
      elseif x >= 322 and x < 350 then self:in_1_pos({"next"}) end
   end
end
