// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import png_display show *

main:
  driver := PngDriver 1 1
  print "Writing out.png"
  driver.write "out.png"
