// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.two_color show WHITE BLACK
import font show *
import font_clock.three_by_five
import font_clock.three_by_five_fixed
import font_clock.three_by_five_proportional
import font_clock.three_by_seven
import font_clock.three_by_seven_fixed
import font_clock.three_by_eight
import font_clock.three_by_eight_fixed
import font_clock.three_by_eight_proportional


main:
  image "3x5" three_by_five.ASCII three_by_five.LATIN_1_SUPPLEMENT 3 5
  image "3x5fixed" three_by_five_fixed.ASCII three_by_five_fixed.LATIN_1_SUPPLEMENT 3 5
  image "3x5proportional" three_by_five_proportional.ASCII three_by_five_proportional.LATIN_1_SUPPLEMENT 3 5
  image "3x7" three_by_seven.ASCII three_by_seven.LATIN_1_SUPPLEMENT 3 7
  image "3x7fixed" three_by_seven_fixed.ASCII three_by_seven_fixed.LATIN_1_SUPPLEMENT 3 7
  image "3x8" three_by_eight.ASCII three_by_eight.LATIN_1_SUPPLEMENT 3 8
  image "3x8fixed" three_by_eight_fixed.ASCII three_by_eight_fixed.LATIN_1_SUPPLEMENT 3 8
  image "3x8proportional" three_by_eight_proportional.ASCII three_by_eight_proportional.LATIN_1_SUPPLEMENT 3 8


image name/string ascii/ByteArray latin/ByteArray w/int h/int -> none:
  W := 112
  H := h == 5 ? 80 : 104
  driver := TwoColorPngDriver W H
  display := TwoColorPixelDisplay driver
  display.background = WHITE

  font := Font [ascii, latin]

  black := display.context --landscape --color=BLACK --font=font

  y := 16
  display.text black 10 y " !\"#\$%&'()*+,-./"
  y += h + 3
  display.text black 10 y "0123456789:;<=>?"
  y += h + 3
  display.text black 10 y "@ABCDEFGHIJKLMNO"
  y += h + 3
  display.text black 10 y "PQRSTUVWXYZ[\\]^_"
  y += h + 3
  display.text black 10 y "`abcdefghijklmno"
  y += h + 3
  display.text black 10 y "pqrstuvwxyz{|}~ °"
  if not name.contains "fixed":
    y += h + 3
    display.text black 10 y "\u{80}  \u{81}  \u{82}  \u{83}  \u{84}  \u{85}"


  display.draw

  print "Writing $name"
  driver.write "$(name).png"
