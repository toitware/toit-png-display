// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import binary show BIG_ENDIAN LITTLE_ENDIAN
import bitmap show *
import bytes show Buffer
import crypto.crc32 show *
import monitor show Latch
import pixel_display show *
import pixel_display.true_color show *
import server.file show *
import zlib show *

class PngDriver extends AbstractDriver:
  width/int ::= ?
  height/int ::= ?
  flags ::= FLAG_TRUE_COLOR | FLAG_PARTIAL_UPDATES
  buffer_/ByteArray ::= ?
  

  constructor .width .height:
    buffer_ = ByteArray width * height * 3

  draw_true_color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    bottom = min bottom height
    canvas_width := right - left
    canvas_height := bottom - top

    // Pack 3 pixels in three consecutive bytes.  Since we receive the data in
    // three one-byte-per-pixel buffers we have to shuffle the bytes.  Some
    // duplication to keep the performance-critical inner loop as simple as
    // possible.
    canvas_height.repeat: | y |
      idx := y * canvas_width
      i := (left + (y + top) * width) * 3
      canvas_width.repeat:
        j := idx + it
        buffer_[i++] = red[j]
        buffer_[i++] = green[j]
        buffer_[i++] = blue[j]

  static HEADER ::= #[0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n']

  write filename/string -> none:
    stream := Stream.for_write filename

    stream.write HEADER

    ihdr := #[
      0, 0, 0, 13,  // Length of section.
      'I', 'H', 'D', 'R',
      0, 0, 0, 0,   // Width.
      0, 0, 0, 0,   // Height.
      8,            // Bits per pixel.
      2,            // Color type, 2 = true color.
      0, 0, 0,
    ]
    BIG_ENDIAN.put_uint32 ihdr 8 width
    BIG_ENDIAN.put_uint32 ihdr 12 height

    stream.write ihdr
    stream.write
      byte_swap
        crc32 ihdr[4..]  // Don't checksum length of section.

    idat ::= #[
      0, 0, 0, 0,  // Length of section.
      'I', 'D', 'A', 'T'
    ]

    compressor := RunLengthZlibEncoder
    done := Latch
    compressed := Buffer

    task::
      while buf := compressor.read:
        compressed.write buf
      done.set null

    height.repeat: | y |
      compressor.write #[0]  // Adaptive scheme.
      index := y * width * 3
      compressor.write buffer_[index..index + width * 3]
    compressor.close

    done.get

    output := compressed.take
    BIG_ENDIAN.put_uint32 idat 0 output.size

    stream.write idat
    stream.write output

    crc := Crc32
    crc.add idat[4..]
    crc.add output
    stream.write
      byte_swap
        crc.get

    iend := #[0, 0, 0, 0, 'I', 'E', 'N', 'D']
    stream.write iend
    stream.write
      byte_swap
        crc32 iend[4..]

    stream.close

byte_swap ba/ByteArray -> ByteArray:
  result := ByteArray 4
  BIG_ENDIAN.put_uint32 result 0
    LITTLE_ENDIAN.uint32 ba 0
  return result
