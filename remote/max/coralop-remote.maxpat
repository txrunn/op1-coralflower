{
 "patcher": {
  "fileversion": 1,
  "appversion": {
   "major": 8,
   "minor": 6,
   "revision": 0,
   "architecture": "x64",
   "modernui": 1
  },
  "classnamespace": "box",
  "rect": [
   80,
   80,
   780,
   400
  ],
  "openinpresentation": 1,
  "default_fontsize": 12.0,
  "boxes": [
   {
    "box": {
     "id": "obj-1",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      400,
      700,
      138,
      22
     ],
     "text": "js coralop-core.js"
    }
   },
   {
    "box": {
     "id": "obj-2",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      400,
      670,
      40,
      22
     ],
     "text": "t l"
    }
   },
   {
    "box": {
     "id": "obj-3",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "int",
      "int"
     ],
     "patching_rect": [
      700,
      600,
      47,
      22
     ],
     "text": "ctlin"
    }
   },
   {
    "box": {
     "id": "obj-4",
     "maxclass": "newobj",
     "numinlets": 3,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      700,
      640,
      82,
      22
     ],
     "text": "pack 0 0 0"
    }
   },
   {
    "box": {
     "id": "obj-5",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 3,
     "outlettype": [
      "",
      "",
      ""
     ],
     "patching_rect": [
      400,
      740,
      110,
      22
     ],
     "text": "route ctl note"
    }
   },
   {
    "box": {
     "id": "obj-6",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      400,
      770,
      82,
      22
     ],
     "text": "unpack 0 0"
    }
   },
   {
    "box": {
     "id": "obj-7",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      520,
      770,
      82,
      22
     ],
     "text": "unpack 0 0"
    }
   },
   {
    "box": {
     "id": "obj-8",
     "maxclass": "newobj",
     "numinlets": 3,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      400,
      800,
      89,
      22
     ],
     "text": "ctlout 0 16"
    }
   },
   {
    "box": {
     "id": "obj-9",
     "maxclass": "newobj",
     "numinlets": 3,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      520,
      800,
      82,
      22
     ],
     "text": "noteout 16"
    }
   },
   {
    "box": {
     "id": "obj-10",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 25,
     "outlettype": [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      700,
      740,
      900,
      22
     ],
     "text": "route enable quant tonic scale layout retrig bass boct octaver chordch bassch local vel sel type add inv bdeg btn holding root sounding chord lit"
    }
   },
   {
    "box": {
     "id": "obj-11",
     "maxclass": "panel",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      900,
      20,
      760,
      360
     ],
     "presentation": 1,
     "presentation_rect": [
      0,
      0,
      760,
      360
     ],
     "bgcolor": [
      0.11,
      0.1,
      0.125,
      1.0
     ],
     "background": 1
    }
   },
   {
    "box": {
     "id": "obj-12",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      608,
      160,
      30
     ],
     "text": "CORALOP",
     "presentation": 1,
     "presentation_rect": [
      14,
      8,
      160,
      30
     ],
     "fontsize": 22,
     "textcolor": [
      1.0,
      0.5,
      0.42,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-13",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1170,
      618,
      200,
      18
     ],
     "text": "remote - MIDI channel 16",
     "presentation": 1,
     "presentation_rect": [
      170,
      18,
      200,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-14",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1560,
      606,
      190,
      40
     ],
     "text": "-",
     "presentation": 1,
     "presentation_rect": [
      560,
      6,
      190,
      40
     ],
     "fontsize": 26,
     "textcolor": [
      0.9,
      0.9,
      0.9,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-15",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1200,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-16",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1560,
      646,
      190,
      18
     ],
     "text": "-",
     "presentation": 1,
     "presentation_rect": [
      560,
      46,
      190,
      18
     ],
     "fontsize": 11,
     "textcolor": [
      0.0,
      0.93,
      0.58,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-17",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1300,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-18",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      20,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      380,
      12,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-19",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      20,
      930,
      110,
      22
     ],
     "text": "prepend enable"
    }
   },
   {
    "box": {
     "id": "obj-20",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      20,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-21",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1408,
      616,
      30,
      18
     ],
     "text": "ON",
     "presentation": 1,
     "presentation_rect": [
      408,
      16,
      30,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-22",
     "maxclass": "button",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      1400,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      440,
      12,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-23",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1466,
      616,
      40,
      18
     ],
     "text": "SYNC",
     "presentation": 1,
     "presentation_rect": [
      466,
      16,
      40,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-24",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1400,
      900,
      40,
      22
     ],
     "text": "sync"
    }
   },
   {
    "box": {
     "id": "obj-25",
     "maxclass": "button",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      1460,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      12,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-26",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1526,
      616,
      40,
      18
     ],
     "text": "PANIC",
     "presentation": 1,
     "presentation_rect": [
      526,
      16,
      40,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-27",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1460,
      900,
      47,
      22
     ],
     "text": "panic"
    }
   },
   {
    "box": {
     "id": "obj-28",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      650,
      200,
      20
     ],
     "text": "PLAY",
     "presentation": 1,
     "presentation_rect": [
      14,
      50,
      200,
      20
     ],
     "fontsize": 13,
     "textcolor": [
      0.41,
      0.56,
      1.0,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-29",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      672,
      120,
      18
     ],
     "text": "quantize",
     "presentation": 1,
     "presentation_rect": [
      14,
      72,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-30",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      130,
      860,
      110,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      14,
      88,
      110,
      22
     ],
     "items": [
      "Off",
      ",",
      "Basic",
      ",",
      "Full"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-31",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      130,
      930,
      103,
      22
     ],
     "text": "prepend quant"
    }
   },
   {
    "box": {
     "id": "obj-32",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      130,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-33",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1134,
      672,
      120,
      18
     ],
     "text": "key",
     "presentation": 1,
     "presentation_rect": [
      134,
      72,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-34",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      240,
      860,
      70,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      134,
      88,
      70,
      22
     ],
     "items": [
      "C",
      ",",
      "Db",
      ",",
      "D",
      ",",
      "Eb",
      ",",
      "E",
      ",",
      "F",
      ",",
      "Gb",
      ",",
      "G",
      ",",
      "Ab",
      ",",
      "A",
      ",",
      "Bb",
      ",",
      "B"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-35",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      240,
      930,
      103,
      22
     ],
     "text": "prepend tonic"
    }
   },
   {
    "box": {
     "id": "obj-36",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      240,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-37",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      716,
      120,
      18
     ],
     "text": "scale",
     "presentation": 1,
     "presentation_rect": [
      14,
      116,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-38",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      350,
      860,
      190,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      14,
      132,
      190,
      22
     ],
     "items": [
      "Major",
      ",",
      "Natural",
      "Minor",
      ",",
      "Major",
      "Pentatonic",
      ",",
      "Minor",
      "Pentatonic",
      ",",
      "Dorian",
      ",",
      "Mixolydian",
      ",",
      "Lydian",
      ",",
      "Phrygian",
      ",",
      "Locrian",
      ",",
      "Harmonic",
      "Minor",
      ",",
      "Melodic",
      "Minor",
      ",",
      "Blues",
      ",",
      "Major",
      "Blues",
      ",",
      "Harmonic",
      "Major",
      ",",
      "Phrygian",
      "Dominant",
      ",",
      "Lydian",
      "Dominant",
      ",",
      "Altered",
      ",",
      "Whole",
      "Tone",
      ",",
      "Diminished",
      "W-H",
      ",",
      "Diminished",
      "H-W",
      ",",
      "Hungarian",
      "Minor",
      ",",
      "Double",
      "Harmonic",
      ",",
      "Hirajoshi",
      ",",
      "In",
      "Sen",
      ",",
      "Iwato",
      ",",
      "Kumoi",
      ",",
      "Chromatic"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-39",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      350,
      930,
      103,
      22
     ],
     "text": "prepend scale"
    }
   },
   {
    "box": {
     "id": "obj-40",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      350,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-41",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      760,
      120,
      18
     ],
     "text": "layout",
     "presentation": 1,
     "presentation_rect": [
      14,
      160,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-42",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      460,
      860,
      190,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      14,
      176,
      190,
      22
     ],
     "items": [
      "Top",
      "Lock",
      ",",
      "Top",
      ",",
      "Side",
      "Lock",
      ",",
      "Side"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-43",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      460,
      930,
      110,
      22
     ],
     "text": "prepend layout"
    }
   },
   {
    "box": {
     "id": "obj-44",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      460,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-45",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1230,
      650,
      200,
      20
     ],
     "text": "CHORD BUTTON",
     "presentation": 1,
     "presentation_rect": [
      230,
      50,
      200,
      20
     ],
     "fontsize": 13,
     "textcolor": [
      0.0,
      0.93,
      0.58,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-46",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1230,
      672,
      250,
      18
     ],
     "text": "edit button (or press it on the OP-1)",
     "presentation": 1,
     "presentation_rect": [
      230,
      72,
      250,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-47",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      570,
      860,
      110,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      230,
      88,
      110,
      22
     ],
     "items": [
      "M6",
      ",",
      "M7",
      ",",
      "M9",
      ",",
      "s2",
      ",",
      "s4",
      ",",
      "m6",
      ",",
      "m7",
      ",",
      "m9",
      ",",
      "M",
      ",",
      "m",
      ",",
      "HOLD"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-48",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      570,
      930,
      89,
      22
     ],
     "text": "prepend sel"
    }
   },
   {
    "box": {
     "id": "obj-49",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      570,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-50",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1230,
      716,
      120,
      18
     ],
     "text": "type",
     "presentation": 1,
     "presentation_rect": [
      230,
      116,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-51",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      680,
      860,
      110,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      230,
      132,
      110,
      22
     ],
     "items": [
      "None",
      ",",
      "Major",
      ",",
      "Minor",
      ",",
      "Diminished",
      ",",
      "Augmented",
      ",",
      "Sus2",
      ",",
      "Sus4",
      ",",
      "Power"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-52",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      680,
      930,
      96,
      22
     ],
     "text": "prepend type"
    }
   },
   {
    "box": {
     "id": "obj-53",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      680,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-54",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1350,
      716,
      120,
      18
     ],
     "text": "add",
     "presentation": 1,
     "presentation_rect": [
      350,
      116,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-55",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      790,
      860,
      120,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      350,
      132,
      120,
      22
     ],
     "items": [
      "None",
      ",",
      7,
      ",",
      "Maj7",
      ",",
      6,
      ",",
      "Add9",
      ",",
      9,
      ",",
      "Maj9",
      ",",
      "6/9",
      ",",
      "Add2",
      ",",
      "Add4",
      ",",
      11,
      ",",
      13,
      ",",
      7,
      "Add11",
      ",",
      "Maj7#11",
      ",",
      "7b9",
      ",",
      "7#9",
      ",",
      "Add11",
      ",",
      "Dim7",
      ",",
      "Maj13"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-56",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      790,
      930,
      89,
      22
     ],
     "text": "prepend add"
    }
   },
   {
    "box": {
     "id": "obj-57",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      790,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-58",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1230,
      760,
      120,
      18
     ],
     "text": "inversion",
     "presentation": 1,
     "presentation_rect": [
      230,
      160,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-59",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      900,
      860,
      110,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      230,
      176,
      110,
      22
     ],
     "items": [
      "Auto",
      ",",
      0,
      ",",
      1,
      ",",
      2,
      ",",
      3
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-60",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      900,
      930,
      89,
      22
     ],
     "text": "prepend inv"
    }
   },
   {
    "box": {
     "id": "obj-61",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      900,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-62",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1350,
      760,
      140,
      18
     ],
     "text": "bass degree (0 = root)",
     "presentation": 1,
     "presentation_rect": [
      350,
      160,
      140,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-63",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "bang"
     ],
     "patching_rect": [
      1010,
      860,
      50,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      350,
      176,
      50,
      22
     ],
     "minimum": 0,
     "maximum": 11,
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-64",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1010,
      930,
      96,
      22
     ],
     "text": "prepend bdeg"
    }
   },
   {
    "box": {
     "id": "obj-65",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1010,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-66",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1500,
      672,
      200,
      20
     ],
     "text": "BASS / MIDI",
     "presentation": 1,
     "presentation_rect": [
      500,
      72,
      200,
      20
     ],
     "fontsize": 13,
     "textcolor": [
      1.0,
      0.42,
      0.24,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-67",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      1120,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      96,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-68",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1120,
      930,
      96,
      22
     ],
     "text": "prepend bass"
    }
   },
   {
    "box": {
     "id": "obj-69",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1120,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-70",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1528,
      700,
      40,
      18
     ],
     "text": "bass",
     "presentation": 1,
     "presentation_rect": [
      528,
      100,
      40,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-71",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      1230,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      580,
      96,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-72",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1230,
      930,
      117,
      22
     ],
     "text": "prepend octaver"
    }
   },
   {
    "box": {
     "id": "obj-73",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1230,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-74",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1608,
      700,
      60,
      18
     ],
     "text": "octaver",
     "presentation": 1,
     "presentation_rect": [
      608,
      100,
      60,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-75",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1500,
      724,
      120,
      18
     ],
     "text": "bass octave",
     "presentation": 1,
     "presentation_rect": [
      500,
      124,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-76",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      1340,
      860,
      70,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      140,
      70,
      22
     ],
     "items": [
      -2,
      ",",
      -1,
      ",",
      0,
      ",",
      "+1",
      ",",
      "+2"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-77",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1340,
      900,
      40,
      22
     ],
     "text": "- 2"
    }
   },
   {
    "box": {
     "id": "obj-78",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1340,
      930,
      96,
      22
     ],
     "text": "prepend boct"
    }
   },
   {
    "box": {
     "id": "obj-79",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1340,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-80",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1340,
      960,
      40,
      22
     ],
     "text": "+ 2"
    }
   },
   {
    "box": {
     "id": "obj-81",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1590,
      724,
      120,
      18
     ],
     "text": "retrig",
     "presentation": 1,
     "presentation_rect": [
      590,
      124,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-82",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      1450,
      860,
      90,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      590,
      140,
      90,
      22
     ],
     "items": [
      "Wait",
      ",",
      "Notes",
      ",",
      "Chord"
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-83",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1450,
      930,
      110,
      22
     ],
     "text": "prepend retrig"
    }
   },
   {
    "box": {
     "id": "obj-84",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1450,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-85",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1500,
      768,
      120,
      18
     ],
     "text": "chord ch (0 = off)",
     "presentation": 1,
     "presentation_rect": [
      500,
      168,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-86",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "bang"
     ],
     "patching_rect": [
      1560,
      860,
      50,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      184,
      50,
      22
     ],
     "minimum": 0,
     "maximum": 16,
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-87",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1560,
      930,
      117,
      22
     ],
     "text": "prepend chordch"
    }
   },
   {
    "box": {
     "id": "obj-88",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1560,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-89",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1620,
      768,
      120,
      18
     ],
     "text": "bass ch",
     "presentation": 1,
     "presentation_rect": [
      620,
      168,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-90",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "bang"
     ],
     "patching_rect": [
      1670,
      860,
      50,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      620,
      184,
      50,
      22
     ],
     "minimum": 0,
     "maximum": 16,
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-91",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1670,
      930,
      110,
      22
     ],
     "text": "prepend bassch"
    }
   },
   {
    "box": {
     "id": "obj-92",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1670,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-93",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      1780,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      216,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-94",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1780,
      930,
      103,
      22
     ],
     "text": "prepend local"
    }
   },
   {
    "box": {
     "id": "obj-95",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1780,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-96",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1528,
      820,
      120,
      18
     ],
     "text": "local (OP-1 sound)",
     "presentation": 1,
     "presentation_rect": [
      528,
      220,
      120,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-97",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1660,
      816,
      60,
      18
     ],
     "text": "velocity",
     "presentation": 1,
     "presentation_rect": [
      660,
      216,
      60,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-98",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "bang"
     ],
     "patching_rect": [
      1890,
      860,
      50,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      690,
      232,
      50,
      22
     ],
     "minimum": 1,
     "maximum": 127,
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-99",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1890,
      930,
      89,
      22
     ],
     "text": "prepend vel"
    }
   },
   {
    "box": {
     "id": "obj-100",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1890,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-101",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1014,
      814,
      200,
      20
     ],
     "text": "KEYS",
     "presentation": 1,
     "presentation_rect": [
      14,
      214,
      200,
      20
     ],
     "fontsize": 13,
     "textcolor": [
      1.0,
      0.5,
      0.42,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-102",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1060,
      816,
      440,
      18
     ],
     "text": "F3-E5 = the OP-1's keys (white roots, black chord buttons), F#5 = HOLD. Click holds, click again lets go.",
     "presentation": 1,
     "presentation_rect": [
      60,
      216,
      440,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-103",
     "maxclass": "kslider",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      1400,
      940,
      336,
      53
     ],
     "presentation": 1,
     "presentation_rect": [
      14,
      236,
      470,
      80
     ],
     "mode": 1,
     "offset": 48,
     "range": 36,
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-104",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1400,
      1010,
      68,
      22
     ],
     "text": "pack 0 0"
    }
   },
   {
    "box": {
     "id": "obj-105",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1400,
      1040,
      117,
      22
     ],
     "text": "prepend kslider"
    }
   },
   {
    "box": {
     "id": "obj-106",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      1500,
      860,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      500,
      262,
      24,
      24
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-107",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1528,
      866,
      40,
      18
     ],
     "text": "HOLD",
     "presentation": 1,
     "presentation_rect": [
      528,
      266,
      40,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-108",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1500,
      900,
      40,
      22
     ],
     "text": "t b"
    }
   },
   {
    "box": {
     "id": "obj-109",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1500,
      930,
      110,
      22
     ],
     "text": "hold 1, hold 0"
    }
   },
   {
    "box": {
     "id": "obj-110",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1500,
      990,
      89,
      22
     ],
     "text": "prepend set"
    }
   },
   {
    "box": {
     "id": "obj-111",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1600,
      640,
      100,
      18
     ],
     "text": "chord buttons lit:",
     "presentation": 1,
     "presentation_rect": [
      500,
      46,
      60,
      18
     ],
     "fontsize": 10,
     "textcolor": [
      0.55,
      0.54,
      0.6,
      1.0
     ]
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "obj-2",
      0
     ],
     "destination": [
      "obj-1",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-3",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-3",
      1
     ],
     "destination": [
      "obj-4",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-3",
      2
     ],
     "destination": [
      "obj-4",
      2
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-4",
      0
     ],
     "destination": [
      "obj-1",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-1",
      0
     ],
     "destination": [
      "obj-5",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-5",
      0
     ],
     "destination": [
      "obj-6",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-5",
      1
     ],
     "destination": [
      "obj-7",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-6",
      0
     ],
     "destination": [
      "obj-8",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-6",
      1
     ],
     "destination": [
      "obj-8",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-7",
      0
     ],
     "destination": [
      "obj-9",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-7",
      1
     ],
     "destination": [
      "obj-9",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-1",
      1
     ],
     "destination": [
      "obj-10",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      22
     ],
     "destination": [
      "obj-15",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-15",
      0
     ],
     "destination": [
      "obj-14",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      23
     ],
     "destination": [
      "obj-17",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-17",
      0
     ],
     "destination": [
      "obj-16",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-18",
      0
     ],
     "destination": [
      "obj-19",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-19",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      0
     ],
     "destination": [
      "obj-20",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-20",
      0
     ],
     "destination": [
      "obj-18",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-22",
      0
     ],
     "destination": [
      "obj-24",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-24",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-25",
      0
     ],
     "destination": [
      "obj-27",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-27",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-30",
      0
     ],
     "destination": [
      "obj-31",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-31",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      1
     ],
     "destination": [
      "obj-32",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-32",
      0
     ],
     "destination": [
      "obj-30",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-34",
      0
     ],
     "destination": [
      "obj-35",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-35",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      2
     ],
     "destination": [
      "obj-36",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-36",
      0
     ],
     "destination": [
      "obj-34",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-38",
      0
     ],
     "destination": [
      "obj-39",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-39",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      3
     ],
     "destination": [
      "obj-40",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-40",
      0
     ],
     "destination": [
      "obj-38",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-42",
      0
     ],
     "destination": [
      "obj-43",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-43",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      4
     ],
     "destination": [
      "obj-44",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-44",
      0
     ],
     "destination": [
      "obj-42",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-47",
      0
     ],
     "destination": [
      "obj-48",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-48",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      13
     ],
     "destination": [
      "obj-49",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-49",
      0
     ],
     "destination": [
      "obj-47",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-51",
      0
     ],
     "destination": [
      "obj-52",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-52",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      14
     ],
     "destination": [
      "obj-53",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-53",
      0
     ],
     "destination": [
      "obj-51",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-55",
      0
     ],
     "destination": [
      "obj-56",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-56",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      15
     ],
     "destination": [
      "obj-57",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-57",
      0
     ],
     "destination": [
      "obj-55",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-59",
      0
     ],
     "destination": [
      "obj-60",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-60",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      16
     ],
     "destination": [
      "obj-61",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-61",
      0
     ],
     "destination": [
      "obj-59",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-63",
      0
     ],
     "destination": [
      "obj-64",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-64",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      17
     ],
     "destination": [
      "obj-65",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-65",
      0
     ],
     "destination": [
      "obj-63",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-67",
      0
     ],
     "destination": [
      "obj-68",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-68",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      6
     ],
     "destination": [
      "obj-69",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-69",
      0
     ],
     "destination": [
      "obj-67",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-71",
      0
     ],
     "destination": [
      "obj-72",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-72",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      8
     ],
     "destination": [
      "obj-73",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-73",
      0
     ],
     "destination": [
      "obj-71",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-76",
      0
     ],
     "destination": [
      "obj-77",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-77",
      0
     ],
     "destination": [
      "obj-78",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-78",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      7
     ],
     "destination": [
      "obj-80",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-80",
      0
     ],
     "destination": [
      "obj-79",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-79",
      0
     ],
     "destination": [
      "obj-76",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-82",
      0
     ],
     "destination": [
      "obj-83",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-83",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      5
     ],
     "destination": [
      "obj-84",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-84",
      0
     ],
     "destination": [
      "obj-82",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-86",
      0
     ],
     "destination": [
      "obj-87",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-87",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      9
     ],
     "destination": [
      "obj-88",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-88",
      0
     ],
     "destination": [
      "obj-86",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      10
     ],
     "destination": [
      "obj-92",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-92",
      0
     ],
     "destination": [
      "obj-90",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-93",
      0
     ],
     "destination": [
      "obj-94",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-94",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      11
     ],
     "destination": [
      "obj-95",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-95",
      0
     ],
     "destination": [
      "obj-93",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-98",
      0
     ],
     "destination": [
      "obj-99",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-99",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      12
     ],
     "destination": [
      "obj-100",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-100",
      0
     ],
     "destination": [
      "obj-98",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-103",
      0
     ],
     "destination": [
      "obj-104",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-103",
      1
     ],
     "destination": [
      "obj-104",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-104",
      0
     ],
     "destination": [
      "obj-105",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-105",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-106",
      0
     ],
     "destination": [
      "obj-108",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-108",
      0
     ],
     "destination": [
      "obj-109",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-109",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      19
     ],
     "destination": [
      "obj-110",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-110",
      0
     ],
     "destination": [
      "obj-106",
      0
     ]
    }
   }
  ],
  "dependency_cache": [
   {
    "name": "coralop-core.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   }
  ]
 }
}