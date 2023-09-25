// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import binary show BIG_ENDIAN byte_swap_32
import bitmap show *
import bytes show Buffer
import crypto.crc show *
import monitor show Latch
import pixel_display show *
import zlib show *

class TwoColorPngDriver extends PngDriver_:
  flags ::= FLAG_2_COLOR
  constructor width height: super width height
  width_to_byte_width w: return w >> 3

class ThreeColorPngDriver extends PngDriver_:
  flags ::= FLAG_3_COLOR
  constructor width height: super width height
  width_to_byte_width w: return w >> 2

class FourGrayPngDriver extends PngDriver_:
  flags ::= FLAG_4_COLOR
  constructor width height: super width height
  width_to_byte_width w: return w >> 2

class TrueColorPngDriver extends PngDriver_:
  flags ::= FLAG_TRUE_COLOR
  constructor width height: super width height
  width_to_byte_width w: return w * 3

class GrayScalePngDriver extends PngDriver_:
  flags ::= FLAG_GRAY_SCALE
  constructor width height: super width height
  width_to_byte_width w: return w

class SeveralColorPngDriver extends PngDriver_:
  flags ::= FLAG_SEVERAL_COLOR
  constructor width height: super width height
  width_to_byte_width w: return w

abstract class PngDriver_ extends AbstractDriver:
  width /int ::= ?
  height /int ::= ?
  rounded_width_ /int := 0
  buffer_ /ByteArray := #[]
  temp_buffer_ /ByteArray := #[]
  temps_ := List 8
  abstract width_to_byte_width w/int -> int

  // Used while writing:
  compressor_ /RunLengthZlibEncoder? := null
  done_ /Latch? := null
  compressed_ /Buffer? := null
  writeable_ := null
  y_ /int := 0

  static INVERT_ := ByteArray 0x100: 0xff - it

  constructor .width .height:
    w := width
    if flags & (FLAG_TRUE_COLOR | FLAG_GRAY_SCALE | FLAG_SEVERAL_COLOR) == 0:
      w = round_up width 8
    rounded_width_ = w

  get_buffer_ left top right bottom -> ByteArray:
    assert: right >= width
    assert: left == 0
    patch_height := bottom - top
    buffer_size := (width_to_byte_width width) * (bottom - top)
    if buffer_.size < buffer_size:
      buffer_ = ByteArray buffer_size
    return buffer_[..buffer_size]

  draw_true_color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    buffer := get_buffer_ left top right bottom

    // Pack 3 pixels in three consecutive bytes.  Since we receive the data in
    // three one-byte-per-pixel buffers we have to shuffle the bytes.
    patch_width := right - left
    blit red   buffer      patch_width --destination_pixel_stride=3 --destination_line_stride=width*3
    blit green buffer[1..] patch_width --destination_pixel_stride=3 --destination_line_stride=width*3
    blit blue  buffer[2..] patch_width --destination_pixel_stride=3 --destination_line_stride=width*3
    patch_height := bottom - top
    write_buffer_ patch_height buffer

  draw_gray_scale left/int top/int right/int bottom/int pixels/ByteArray -> none:
    patch_height := bottom - top
    write_buffer_ patch_height pixels

  draw_several_color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    patch_height := bottom - top
    write_buffer_ patch_height pixels

  draw_two_color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    if temp_buffer_.size < pixels.size:
      temp_buffer_ = ByteArray pixels.size
      8.repeat:
        temps_[it] = temp_buffer_[it..]

    patch_width := right - left
    assert: patch_width == rounded_width_
    patch_height := bottom - top
    assert: patch_height == (round_up patch_height 8)
    // Writes the patch to the compressor.  The patch is arranged as height/8
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

    buffer := get_buffer_ left top right bottom

    // Now we need to spread the 8x8 blocks out over the lines they belong on.
    // First line is bytes 0, 8, 16..., next line is bytes 1, 9, 17... etc.
    8.repeat:
      index := (rounded_width_ * (7 - it)) >> 3
      blit temps_[it] buffer[index..] (patch_width >> 3) --source_pixel_stride=8 --destination_line_stride=rounded_width_ --lookup_table=INVERT_
    write_buffer_ patch_height buffer

  draw_two_bit left/int top/int right/int bottom/int plane_0/ByteArray plane_1/ByteArray -> none:
    patch_width := right - left
    assert: patch_width == rounded_width_
    patch_height := bottom - top
    assert: patch_height == (round_up patch_height 8)

    byte_width := width_to_byte_width rounded_width_

    buffer := get_buffer_ left top right bottom

    // Writes part of the patch to the compressor.  The patch is arranged as
    // height/8 strips of width bytes, where each byte represents 8 vertically
    // stacked pixels.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom, msbit on
    // the left.
    // This implementation is not as optimized as the two-color version.
    row := 0
    ppb := 4  // Pixels per byte.
    for y := 0; y < patch_height; y += 8:
      for in_bit := 0; in_bit < 8 and y + top + in_bit < height; in_bit++:
        out_index := (y + in_bit) * byte_width
        for x := 0; x < patch_width; x += ppb:
          out := 0
          byte_pos := row + x + ppb - 1
          for out_bit := ppb - 1; out_bit >= 0; out_bit--:
            out |= ((plane_0[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2)
            out |= ((plane_1[byte_pos - out_bit] >> in_bit) & 1) << (out_bit * 2 + 1)
          buffer[out_index + (width_to_byte_width x)] = out
      row += rounded_width_
    write_buffer_ patch_height buffer

  static HEADER ::= #[0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n']

  static write_chunk stream name/string data/ByteArray -> none:
    length := ByteArray 4
    if name.size != 4: throw "invalid name"
    BIG_ENDIAN.put_uint32 length 0 data.size
    write_ stream length
    write_ stream name
    write_ stream data
    crc := Crc32
    crc.add name
    crc.add data
    write_ stream
      byte_swap_
        crc.get

  static write_ stream byte_array -> none:
    done := 0
    while done != byte_array.size:
      done += stream.write byte_array[done..]

  write_header_ writeable --reproducible/bool -> none:
    true_color := flags & FLAG_TRUE_COLOR != 0
    gray := flags & FLAG_4_COLOR != 0
    three_color := flags & FLAG_3_COLOR != 0
    gray_scale := flags & FLAG_GRAY_SCALE != 0
    several_color := flags & FLAG_SEVERAL_COLOR != 0

    write_ writeable HEADER

    bits_per_pixel := ?
    color_type := ?
    if true_color:
      bits_per_pixel = 8
      color_type = 2  // True color.
    else if gray_scale:
      bits_per_pixel = 8
      color_type = 0  // Gray scale.
    else if three_color:
      bits_per_pixel = 2
      color_type = 3  // Palette.
    else if several_color:
      bits_per_pixel = 8
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
    write_chunk writeable "IHDR" ihdr

    if three_color:
      write_chunk writeable "PLTE" #[  // Palette.
          0xff, 0xff, 0xff,         // 0 is white.
          0, 0, 0,                  // 1 is black.
          0xff, 0, 0,               // 2 is red.
        ]
    else if several_color:
      // Use color palette of 7-color epaper display.
      write_chunk writeable "PLTE" #[  // Palette.
          0xff, 0xff, 0xff,         // 0 is white.
          0, 0, 0,                  // 1 is black.
          0xff, 0, 0,               // 2 is red.
          0, 0xff, 0,               // 3 is green
          0, 0, 0xff,               // 4 is blue
          0xff, 0xff, 0,            // 5 is yellow
          0xff, 0xc0, 0,            // 6 is orange
        ]

    compressor_ = RunLengthZlibEncoder
    done_ = Latch
    compressed_ = Buffer
    writeable_ = writeable
    y_ = 0

    task::
      while data := compressor_.reader.read:
        compressed_.write data
        if (not reproducible) and compressed_.size > 1900:
          write_chunk writeable_ "IDAT" compressed_.bytes  // Flush compressed pixel data.
          compressed_ = Buffer
      done_.set null

  write_buffer_ height/int buffer/ByteArray -> none:
    zero_byte := #[0]
    gray := flags & FLAG_4_COLOR != 0
    several_color := flags & FLAG_SEVERAL_COLOR != 0
    height.repeat: | y |
      if y_ >= this.height: return
      compressor_.write zero_byte  // Adaptive scheme.
      line_size := width_to_byte_width width
      index := y * line_size
      line := buffer[index..index + line_size]
      if gray:
        line = ByteArray line.size: line[it] ^ 0xff
      else if several_color:
        line = ByteArray line.size: min 6 line[it]
      compressor_.write line
      y_++

  write_footer_:
    compressor_.close

    // Wait for the reader task to finish.
    done_.get

    if compressed_.size != 0:
      write_chunk writeable_ "IDAT" compressed_.bytes  // Compressed pixel data.

    compressed_ = null
    compressor_ = null
    done_ = null
    y_ = 0

    write_chunk writeable_ "IEND" #[]  // End chunk.

byte_swap_ ba/ByteArray -> ByteArray:
  result := ba.copy
  byte_swap_32 result
  return result

/**
Writes a PNG file to an object with a write method.
Can be used to write a PNG to an HTTP socket.
Only light compression is used, basically just run-length encoding
  of equal pixels.  This is fast and reduces memory use.
If $reproducible is true the whole PNG is buffered up before writing.
  This uses more memory, but ensures that the whole image is in one IDAT chunk,
  which makes it easier to compare output files.
If $reproducible is false the PNG is written incrementally, which
  uses less memory, but the image is split into several IDAT chunks, which
  makes it harder to compare output files.
*/
write_to writeable --reproducible/bool=false driver/PngDriver_ display/PixelDisplay:
  driver.write_header_ writeable --reproducible=reproducible
  display.draw
  driver.write_footer_
  writeable.close
