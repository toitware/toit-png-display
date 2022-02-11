// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.histogram show *
import pixel_display.three_color show WHITE BLACK RED
import font show *

import .write_file

main:
  driver := ThreeColorPngDriver 320 240
  display := ThreeColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  red := context.with --color=RED

  plus_histo := ThreeColorHistogram
      --x=50
      --y=40
      --width=220
      --height=80
      --transform=context.transform
      --color=BLACK
  display.add plus_histo

  minus_histo := ThreeColorHistogram
      --x=50
      --y=120
      --width=220
      --height=80
      --transform=context.transform
      --color=RED
      --reflected
  display.add minus_histo

  display.text context 20 20 "Black"
  display.text red 60 20 "Red"

  y := 0
  220.repeat:
    if y > 50: y -= 10
    if y < -50: y += 10
    y += (random 15) - 7
    plus_histo.add y
    minus_histo.add -y

  print "Writing histogram.png"
  write_file "histogram.png" driver display
