// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import expect show *
import fs
import host.os
import host.file
import io
import pixel-display show *
import png-display show *
import system

check-gold driver/PngDriver_ display/PixelDisplay:
  test-path := system.program-path
  test-dir := fs.dirname test-path
  test-name := (fs.basename test-path).trim --right ".toit"
  gold-path := fs.join test-dir "gold" "$(test-name).png"

  stream := io.Buffer
  // Writes a PNG file to the given filename.
  // Only light compression is used, basically just run-length encoding
  //  of equal pixels.  This is fast and reduces memory use.
  write-to stream driver display --reproducible

  actual := stream.bytes
  if not file.is-file gold-path or os.env.get "UPDATE_GOLD":
    print "Updating gold file: $gold-path"
    file.write-contents --path=gold-path actual
  else:
    expected := file.read-contents gold-path
    expect-equals expected actual
