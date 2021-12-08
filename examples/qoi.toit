// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.true_color show *
import font show *
import server.file

QOI_PARROT ::= file.read_content "third_party/creativetail/parrot.qoi"

main:
  driver := TrueColorPngDriver 320 240
  display := TrueColorPixelDisplay driver

  context := display.context --landscape --color=(get_rgb 255 128 128) --font=(Font.get "sans10")
  blue := context.with --color=(get_rgb 30 40 255)

  qoi := QoiTexture 25 25 context.transform QOI_PARROT

  display.add qoi

  display.text context 5 20 "Toit with Quite OK Image format support"
  display.draw

  print "Writing qoi-output.png"
  driver.write "qoi-output.png"
