// SPDX-License-Identifier: GPL-3.0-only
// CoralOP remote core for Max's [js] object: CoralFlower on the OP-1 over MIDI channel 16 (../README.md).
//
// inlet 0  messages from the panel or your patch:
//            enable quant tonic scale layout retrig bass boct octaver chordch bassch local vel sel type add inv bdeg <v>
//            press <key 0..23> <0/1>    hold <0/1>    sync    panic    kslider <pitch> <velocity>
// inlet 1  "val cc ch" lists from [ctlin] (anything not on channel 16 is ignored)
// outlet 0 "ctl val cc" and "note pitch vel" for channel 16 ([route ctl note] -> [ctlout 0 16] / [noteout 16])
// outlet 1 the OP-1's state: "<param> v", "btn i b", "holding b", "root pc" (-1: none), "sounding b",
//          "chord name" ("-": none), "lit <labels of the lit chord buttons>"
// Max's classic [js] is ES5: no let / const / arrow functions here.

inlets = 2;
outlets = 2;

var PARAMS = [
    ["enable", 20, "tgl"], ["quant", 21, ""], ["tonic", 22, ""], ["scale", 23, ""], ["layout", 24, ""],
    ["retrig", 25, ""], ["bass", 26, "tgl"], ["boct", 27, "boct"], ["octaver", 28, "tgl"], ["chordch", 29, ""],
    ["bassch", 30, ""], ["local", 31, "tgl"], ["vel", 102, ""], ["sel", 104, ""], ["type", 105, ""],
    ["add", 106, ""], ["inv", 107, ""], ["bdeg", 108, ""]
];
var BUTTONS_TOP = ["M6", "M7", "M9", "s2", "s4", "m6", "m7", "m9", "M", "m", "HOLD"];
var BUTTONS_SIDE = ["M", "m", "dim", "s2", "s4", "7", "9"];
var CTRL_CH = 16, KEY0 = 53, HOLD_NOTE = 78;

var byName = {}, byCC = {};
for (var i = 0; i < PARAMS.length; i++) {
    byName[PARAMS[i][0]] = PARAMS[i];
    byCC[PARAMS[i][1]] = PARAMS[i];
}

var nameLen = 0, nameBuf = [], btnLo = 0, btnHi = 0, layout = 0;

function clip(v) {
    v = Math.round(v);
    return v < 0 ? 0 : v > 127 ? 127 : v;
}

function send(name, v) {                                // a parameter to the OP-1
    var p = byName[name];
    if (!p) return false;
    if (p[2] === "tgl") v = v ? 127 : 0;
    else if (p[2] === "boct") v = v + 64;
    outlet(0, "ctl", clip(v), p[1]);
    return true;
}

function press(key, down) {
    outlet(0, "note", KEY0 + key, down ? 100 : 0);
}

function handle(sel, args) {
    if (inlet === 1) return;
    if (send(sel, args.length ? args[0] : 0)) return;
    if (sel === "press" && args.length >= 2) {
        if (args[0] >= 0 && args[0] < 24) press(args[0], args[1]);
    } else if (sel === "hold") {
        outlet(0, "note", HOLD_NOTE, args.length && args[0] ? 100 : 0);
    } else if (sel === "kslider" && args.length >= 2) {   // [kslider] pitch velocity, any octave
        var k = args[0] - KEY0;
        if (k >= 0 && k < 24) press(k, args[1] > 0);
        else if (args[0] === HOLD_NOTE) outlet(0, "note", HOLD_NOTE, args[1] > 0 ? 100 : 0);
    } else if (sel === "sync") {
        outlet(0, "ctl", 0, 110);
    } else if (sel === "panic") {
        outlet(0, "ctl", 0, 109);
    }
}

function litLabels() {
    var bits = btnLo | (btnHi << 7), names = layout >= 2 ? BUTTONS_SIDE : BUTTONS_TOP, out = [];
    for (var b = 0; b < names.length; b++)
        if (bits >> b & 1) out.push(names[b]);
    return out.length ? out.join(" ") : "-";
}

function fromDevice(val, cc, ch) {
    var p = byCC[cc], b;
    if (ch !== CTRL_CH) return;
    if (p) {
        var v = p[2] === "tgl" ? (val >= 64 ? 1 : 0) : p[2] === "boct" ? val - 64 : val;
        outlet(1, p[0], v);
        if (p[0] === "layout") {
            layout = v;
            outlet(1, "lit", litLabels());          // (the same bits, other names)
        }
        return;
    }
    switch (cc) {
    case 112:
    case 113:
        if (cc === 112) btnLo = val; else btnHi = val;
        for (b = 0; b < (cc === 112 ? 7 : 4); b++)
            outlet(1, "btn", (cc === 112 ? 0 : 7) + b, val >> b & 1);
        outlet(1, "lit", litLabels());
        break;
    case 114: outlet(1, "holding", val >= 64 ? 1 : 0); break;
    case 115: outlet(1, "root", val === 127 ? -1 : val); break;
    case 116: outlet(1, "sounding", val >= 64 ? 1 : 0); break;
    case 117:
        nameLen = val;
        nameBuf = [];
        if (!val) outlet(1, "chord", "-");
        break;
    case 118:
        if (nameBuf.length < nameLen) {
            nameBuf.push(String.fromCharCode(val));
            if (nameBuf.length === nameLen) outlet(1, "chord", nameBuf.join(""));
        }
        break;
    }
}

function list() {
    var a = arrayfromargs(arguments);
    if (inlet === 1) {
        if (a.length >= 3) fromDevice(a[0], a[1], a[2]);
        else if (a.length === 2) fromDevice(a[0], a[1], CTRL_CH);
    }
}

function anything() {
    handle(messagename, arrayfromargs(arguments));
}

function bang() {
    handle("sync", []);
}

function loadbang() {
    outlet(0, "ctl", 0, 110);                           // ask the OP-1 for its state
}
