// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.histogram show *
import pixel-display.three-color show WHITE BLACK RED
import font show *

import .write-file

main:
  driver := ThreeColorPngDriver 320 240
  display := ThreeColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  red := context.with --color=RED

  plus-histo := ThreeColorHistogram
      --x=50
      --y=40
      --width=220
      --height=80
      --transform=context.transform
      --color=BLACK
  display.add plus-histo

  minus-histo := ThreeColorHistogram
      --x=50
      --y=120
      --width=220
      --height=80
      --transform=context.transform
      --color=RED
      --reflected
  display.add minus-histo

  display.text context 20 20 "Black"
  display.text red 60 20 "Red"

  y := 0
  220.repeat:
    if y > 50: y -= 10
    if y < -50: y += 10
    y += (random 15) - 7
    plus-histo.add y
    minus-histo.add -y

  print "Writing histogram.png"
  write-file "histogram.png" driver display
