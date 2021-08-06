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
  rounded_width_/int := 0
  buffer_/ByteArray? := null
  temp_buffer_/ByteArray := #[]
  temps_ := List 8
  abstract width_to_byte_width w/int -> int

  static INVERT_ := ByteArray 0x100: 0xff - it

  constructor .width .height:
    w := round_up width 8
    h := round_up height 8
    if ((flags & FLAG_TRUE_COLOR) != 0):
      w = width
      h = height
    rounded_width_ = w
    buffer_ = ByteArray h * (width_to_byte_width w)

  draw_true_color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    bottom = min bottom height
    patch_width := right - left
    patch_height := bottom - top

    // Pack 3 pixels in three consecutive bytes.  Since we receive the data in
    // three one-byte-per-pixel buffers we have to shuffle the bytes.
    index := (left + top * width) * 3
    blit red   buffer_[index..]     patch_width --destination_pixel_stride=3 --destination_line_stride=width*3
    blit green buffer_[index + 1..] patch_width --destination_pixel_stride=3 --destination_line_stride=width*3
    blit blue  buffer_[index + 2..] patch_width --destination_pixel_stride=3 --destination_line_stride=width*3

  draw_two_color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    if temp_buffer_.size < pixels.size:
      temp_buffer_ = ByteArray pixels.size
      8.repeat:
        temps_[it] = temp_buffer_[it..]

    patch_width := right - left
    patch_height := bottom - top
    // Writes the patch to the buffer.  The patch is arranged as height/8
    // strips of width bytes, where each byte represents 8 vertically stacked
    // pixels, lsbit at the top.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom, msbit on
    // the left.

    input_bytes := (patch_width * patch_height) >> 3

    pixels_0 := pixels[0..input_bytes]
    pixels_1 := pixels[1..input_bytes]
    pixels_2 := pixels[2..input_bytes]
    pixels_4 := pixels[4..input_bytes]

    // We start by reflecting each 8x8 block.
    // Reflect each 2x2 pixel block.
    blit pixels_0 temps_[0] patch_width/2 --source_pixel_stride=2 --destination_pixel_stride=2 --mask=0xaa
    blit pixels_1 temps_[1] patch_width/2 --source_pixel_stride=2 --destination_pixel_stride=2 --mask=0x55
    blit pixels_0 temps_[1] patch_width/2 --source_pixel_stride=2 --destination_pixel_stride=2 --shift=-1 --mask=0xaa --operation=OR
    blit pixels_1 temps_[0] patch_width/2 --source_pixel_stride=2 --destination_pixel_stride=2 --shift=1 --mask=0x55 --operation=OR
    // Reflect each 4x4 pixel block.  Blit is treating each 4x8 block as a line for this operation.
    blit temps_[0] pixels_0 2 --source_line_stride=4 --destination_line_stride=4 --mask=0xcc
    blit temps_[2] pixels_2 2 --source_line_stride=4 --destination_line_stride=4 --mask=0x33
    blit temps_[0] pixels_2 2 --source_line_stride=4 --destination_line_stride=4 --shift=-2 --mask=0xcc --operation=OR
    blit temps_[2] pixels_0 2 --source_line_stride=4 --destination_line_stride=4 --shift=2 --mask=0x33 --operation=OR
    // Reflect each 8x8 pixel block.  Blit is treating each 8x8 block as a line for this operation.
    blit pixels_0 temps_[0] 4 --source_line_stride=8 --destination_line_stride=8 --mask=0xf0
    blit pixels_4 temps_[4] 4 --source_line_stride=8 --destination_line_stride=8 --mask=0x0f
    blit pixels_0 temps_[4] 4 --source_line_stride=8 --destination_line_stride=8 --shift=-4 --mask=0xf0 --operation=OR
    blit pixels_4 temps_[0] 4 --source_line_stride=8 --destination_line_stride=8 --shift=4 --mask=0x0f --operation=OR

    output_area := buffer_[(left + top * rounded_width_) >> 3..((right + (bottom - 1) * rounded_width_)) >> 3]

    // Now we need to spread the 8x8 blocks out over the lines they belong on.
    // First line is bytes 0, 8, 16..., next line is bytes 1, 9, 17... etc.
    8.repeat:
      index := (rounded_width_ * (7 - it)) >> 3
      blit temps_[it] output_area[index..] (patch_width >> 3) --source_pixel_stride=8 --destination_line_stride=rounded_width_ --lookup_table=INVERT_

  draw_two_bit left/int top/int right/int bottom/int plane_0/ByteArray plane_1/ByteArray -> none:
    one_bit := plane_1 == null
    patch_width := right - left
    patch_height := bottom - top

    byte_width := width_to_byte_width rounded_width_

    // Writes part of the patch to the buffer.  The patch is arranged as
    // height/8 strips of width bytes, where each byte represents 8 vertically
    // stacked pixels.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom, msbit on
    // the left.
    byte_x := width_to_byte_width left
    row := 0
    ppb := 4  // Pixels per byte.
    for y := 0; y < patch_height; y += 8:
      for in_bit := 0; in_bit < 8 and y + top + in_bit < height; in_bit++:
        out_index := (y + in_bit + top) * byte_width + byte_x
        for x := 0; x < patch_width; x += ppb:
          out := 0
          byte_pos := row + x + ppb - 1
          for out_bit := ppb - 1; out_bit >= 0; out_bit--:
            out |= ((plane_0[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2)
            out |= ((plane_1[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2 + 1)
          buffer_[out_index + (width_to_byte_width x)] = out
      row += rounded_width_

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
