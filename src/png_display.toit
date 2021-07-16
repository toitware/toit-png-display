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

class TwoColorPngDriver extends PngDriver_:
  flags ::= FLAG_2_COLOR | FLAG_PARTIAL_UPDATES
  constructor width height: super width height
  width_to_byte_width w: return w >> 3

class ThreeColorPngDriver extends PngDriver_:
  flags ::= FLAG_3_COLOR | FLAG_PARTIAL_UPDATES
  constructor width height: super width height
  width_to_byte_width w: return w >> 2

class FourGrayPngDriver extends PngDriver_:
  flags ::= FLAG_4_COLOR | FLAG_PARTIAL_UPDATES
  constructor width height: super width height
  width_to_byte_width w: return w >> 2

class TrueColorPngDriver extends PngDriver_:
  flags ::= FLAG_TRUE_COLOR | FLAG_PARTIAL_UPDATES
  constructor width height: super width height
  width_to_byte_width w: return w * 3

abstract class PngDriver_ extends AbstractDriver:
  width/int ::= ?
  height/int ::= ?
  buffer_/ByteArray? := null
  abstract width_to_byte_width w/int -> int

  constructor .width .height:
    buffer_ = ByteArray height * (width_to_byte_width width)

  draw_true_color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    bottom = min bottom height
    patch_width := right - left
    patch_height := bottom - top

    // Pack 3 pixels in three consecutive bytes.  Since we receive the data in
    // three one-byte-per-pixel buffers we have to shuffle the bytes.  Some
    // duplication to keep the performance-critical inner loop as simple as
    // possible.
    patch_height.repeat: | y |
      idx := y * patch_width
      i := width_to_byte_width (left + (y + top) * width)
      patch_width.repeat:
        j := idx + it
        buffer_[i++] = red[j]
        buffer_[i++] = green[j]
        buffer_[i++] = blue[j]

  draw_two_color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    draw_bits_ left top right bottom pixels null

  draw_two_bit left/int top/int right/int bottom/int plane_0/ByteArray plane_1/ByteArray -> none:
    draw_bits_ left top right bottom plane_0 plane_1

  draw_bits_ left/int top/int right/int bottom/int plane_0/ByteArray plane_1/ByteArray? -> none:
    one_bit := plane_1 == null
    patch_width := right - left
    patch_height := bottom - top

    byte_width := width_to_byte_width width

    // Writes part of the patch to the buffer.  The patch is arranged as
    // height/8 strips of width bytes, where each byte represents 8 vertically
    // stacked pixels.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom.
    byte_x := width_to_byte_width left
    row := 0
    ppb := one_bit ? 8 : 4  // Pixels per byte.
    for y := 0; y < patch_height; y += 8:
      for in_bit := 0; in_bit < 8 and y + top + in_bit < height; in_bit++:
        out_index := (y + in_bit + top) * byte_width + byte_x
        for x := 0; x < patch_width; x += ppb:
          out := 0
          byte_pos := row + x + ppb - 1
          for out_bit := ppb - 1; out_bit >= 0; out_bit--:
            if one_bit:
              out |= ((plane_0[byte_pos - out_bit] >> in_bit) & 1) << out_bit
            else:
              out |= ((plane_0[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2)
              out |= ((plane_1[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2 + 1)
          buffer_[out_index + (width_to_byte_width x)] = one_bit ? (out ^ 0xff) : out
      row += width

  static HEADER ::= #[0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n']

  static write_chunk stream name/String data/ByteArray -> none:
    length := ByteArray 4
    if name.size != 4: throw "invalid name"
    BIG_ENDIAN.put_uint32 length 0 data.size
    stream.write length
    stream.write name
    stream.write data
    crc := Crc32
    crc.add name
    crc.add data
    stream.write
      byte_swap_
        crc.get

  write filename/string -> none:
    true_color := flags & FLAG_TRUE_COLOR != 0
    gray := flags & FLAG_4_COLOR != 0
    three_color := flags & FLAG_3_COLOR != 0

    stream := Stream.for_write filename

    stream.write HEADER

    bits_per_pixel := ?
    color_type := ?
    if true_color:
      bits_per_pixel = 8
      color_type = 2  // True color.
    else if three_color:
      bits_per_pixel = 2
      color_type = 3  // Palette.
    else if gray:
      bits_per_pixel = 2
      color_type = 0  // Grayscale.
    else:
      bits_per_pixel = 1
      color_type = 0  // Grayscale

    ihdr := #[
      0, 0, 0, 0,          // Width.
      0, 0, 0, 0,          // Height.
      bits_per_pixel,
      color_type,
      0, 0, 0,
    ]
    BIG_ENDIAN.put_uint32 ihdr 0 width
    BIG_ENDIAN.put_uint32 ihdr 4 height
    write_chunk stream "IHDR" ihdr

    if three_color:
      write_chunk stream "PLTE" #[  // Palette.
          0xff, 0xff, 0xff,         // 0 is white.
          0, 0, 0,                  // 1 is black.
          0xff, 0, 0,               // 2 is red.
        ]

    compressor := RunLengthZlibEncoder
    done := Latch
    compressed := Buffer

    task::
      while data := compressor.read:
        compressed.write data
      done.set null

    zero_byte := #[0]
    height.repeat: | y |
      compressor.write zero_byte  // Adaptive scheme.
      line_size := width_to_byte_width width
      index := y * line_size
      line := buffer_[index..index + line_size]
      if gray:
        line = ByteArray line.size: line[it] ^ 0xff
      compressor.write line
    compressor.close

    // Wait for the reader task to finish.
    done.get

    write_chunk stream "IDAT" compressed.take  // Compressed pixel data.

    write_chunk stream "IEND" #[]  // End chunk.

    stream.close

byte_swap_ ba/ByteArray -> ByteArray:
  result := ByteArray 4
  BIG_ENDIAN.put_uint32 result 0
    LITTLE_ENDIAN.uint32 ba 0
  return result
