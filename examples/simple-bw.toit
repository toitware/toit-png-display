// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.two_color show WHITE BLACK
import font show *

import .write_file

main:
  driver := TwoColorPngDriver 104 50
  display := TwoColorPixelDisplay driver
  display.background = WHITE

  font := Font.get "sans10"

  black := display.context --landscape --color=BLACK --font=font
  white := display.context --landscape --color=WHITE --font=font

  display.filled_rectangle black 15 15 40 30
  display.text white 20 30 "Toit"

  print "Writing simple-bw.png"
  write_file "simple-bw.png" driver display
