// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.three_color show WHITE BLACK RED
import font show *

main:
  driver := ThreeColorPngDriver 104 50
  display := ThreeColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  red := context.with --color=RED

  display.text context 20 30 "Toit"
  display.text red 60 30 "Red"
  display.draw

  print "Writing simple-3-color.png"
  driver.write "simple-3-color.png"
