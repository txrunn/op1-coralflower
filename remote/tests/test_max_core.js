// SPDX-License-Identifier: GPL-3.0-only
// Runs ../max/coralop-core.js under a small stand-in for Max's [js] globals: node test_max_core.js
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm"), assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "max", "coralop-core.js"), "utf8");
const out = [[], []];
const ctx = {
    inlets: 0, outlets: 0, inlet: 0, messagename: "",
    outlet: (n, ...a) => out[n].push(a),
    arrayfromargs: (args) => Array.prototype.slice.call(args),
    post: () => {},
    Math, String,
};
vm.createContext(ctx);
vm.runInContext(src, ctx);
assert.strictEqual(ctx.inlets, 2);
assert.strictEqual(ctx.outlets, 2);

function msg(sel, ...args) {           // a message into inlet 0
    ctx.inlet = 0;
    ctx.messagename = sel;
    vm.runInContext("anything.apply(null, __a)", Object.assign(ctx, { __a: args }));
}
function dev(val, cc, ch = 16) {        // a [ctlin] list into inlet 1
    ctx.inlet = 1;
    vm.runInContext("list.apply(null, __a)", Object.assign(ctx, { __a: [val, cc, ch] }));
}
function take(n) { const r = out[n].splice(0); return r; }
let checks = 0;
function eq(a, b) { checks++; assert.deepStrictEqual(a, b); }

// out: parameters with their wire encodings
msg("enable", 1); msg("enable", 0); msg("tonic", 3); msg("boct", -2); msg("bass", 1); msg("vel", 300);
eq(take(0), [["ctl", 127, 20], ["ctl", 0, 20], ["ctl", 3, 22], ["ctl", 62, 27], ["ctl", 127, 26], ["ctl", 127, 102]]);
// keys, HOLD, kslider, sync, panic
msg("press", 7, 1); msg("press", 7, 0); msg("press", 30, 1); msg("hold", 1); msg("hold", 0);
msg("kslider", 73, 64); msg("kslider", 73, 0); msg("kslider", 40, 64); msg("sync"); msg("panic");
eq(take(0), [["note", 60, 100], ["note", 60, 0], ["note", 78, 100], ["note", 78, 0], ["note", 73, 100],
             ["note", 73, 0], ["ctl", 0, 110], ["ctl", 0, 109]]);
msg("nonsense", 1);
eq(take(0), []);

// in: other channels ignored; parameters decoded
dev(5, 23, 1);
eq(take(1), []);
dev(127, 20); dev(0, 26); dev(63, 27); dev(4, 23);
eq(take(1), [["enable", 1], ["bass", 0], ["boct", -1], ["scale", 4]]);
// buttons: M (button 8) lit in Top -> "btn 7 0", "btn 8 1"... and "lit M"
dev(0, 112); take(1);
dev(2, 113);
const t = take(1);
eq(t.filter((m) => m[0] === "btn"), [["btn", 7, 0], ["btn", 8, 1], ["btn", 9, 0], ["btn", 10, 0]]);
eq(t.find((m) => m[0] === "lit"), ["lit", "M"]);
dev(3, 24); dev(3, 112); dev(0, 113);           // Side: M and m lit
eq(take(1).filter((m) => m[0] === "lit").pop(), ["lit", "M m"]);
dev(0, 24);                                     // back to Top Lock: the same bits are M6 M7
eq(take(1), [["layout", 0], ["lit", "M6 M7"]]);
// status
dev(127, 114); dev(127, 115); dev(9, 115); dev(127, 116);
eq(take(1), [["holding", 1], ["root", -1], ["root", 9], ["sounding", 1]]);
// the name: 117 length, then 118 per character; a new 117 restarts; 0 = "-"
dev(5, 117); [67, 35, 109, 55, 98].forEach((c) => dev(c, 118));
eq(take(1), [["chord", "C#m7b"]]);
dev(3, 117); dev(69, 118);
dev(2, 117); dev(68, 118); dev(98, 118);
eq(take(1), [["chord", "Db"]]);
dev(0, 117);
eq(take(1), [["chord", "-"]]);
dev(66, 118);                                   // a stray character: nothing
eq(take(1), []);
console.log(`max core: ${checks} checks, 0 failures`);
