// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import io show BIG-ENDIAN Buffer ByteOrder
import bitmap show *
import crypto.crc show *
import monitor show Latch
import pixel-display show *
import zlib show *

class TwoColorPngDriver extends PngDriver_:
  flags ::= FLAG-2-COLOR
  constructor width height: super width height
  width-to-byte-width w: return w >> 3

class ThreeColorPngDriver extends PngDriver_:
  flags ::= FLAG-3-COLOR
  constructor width height: super width height
  width-to-byte-width w: return w >> 2

class FourGrayPngDriver extends PngDriver_:
  flags ::= FLAG-4-COLOR
  constructor width height: super width height
  width-to-byte-width w: return w >> 2

class TrueColorPngDriver extends PngDriver_:
  flags ::= FLAG-TRUE-COLOR
  constructor width height: super width height
  width-to-byte-width w: return w * 3

class GrayScalePngDriver extends PngDriver_:
  flags ::= FLAG-GRAY-SCALE
  constructor width height: super width height
  width-to-byte-width w: return w

class SeveralColorPngDriver extends PngDriver_:
  flags ::= FLAG-SEVERAL-COLOR
  constructor width height: super width height
  width-to-byte-width w: return w

abstract class PngDriver_ extends AbstractDriver:
  width /int ::= ?
  height /int ::= ?
  rounded-width_ /int := 0
  buffer_ /ByteArray := #[]
  temp-buffer_ /ByteArray := #[]
  temps_ := List 8
  abstract width-to-byte-width w/int -> int

  // Used while writing:
  compressor_ /RunLengthZlibEncoder? := null
  done_ /Latch? := null
  compressed_ /Buffer? := null
  writeable_ := null
  y_ /int := 0

  static INVERT_ := ByteArray 0x100: 0xff - it

  constructor .width .height:
    w := width
    if flags & (FLAG-TRUE-COLOR | FLAG-GRAY-SCALE | FLAG-SEVERAL-COLOR) == 0:
      w = round-up width 8
    rounded-width_ = w

  get-buffer_ left top right bottom -> ByteArray:
    assert: right >= width
    assert: left == 0
    patch-height := bottom - top
    buffer-size := (width-to-byte-width width) * (bottom - top)
    if buffer_.size < buffer-size:
      buffer_ = ByteArray buffer-size
    return buffer_[..buffer-size]

  draw-true-color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    buffer := get-buffer_ left top right bottom

    // Pack 3 pixels in three consecutive bytes.  Since we receive the data in
    // three one-byte-per-pixel buffers we have to shuffle the bytes.
    patch-width := right - left
    blit red   buffer      patch-width --destination-pixel-stride=3 --destination-line-stride=width*3
    blit green buffer[1..] patch-width --destination-pixel-stride=3 --destination-line-stride=width*3
    blit blue  buffer[2..] patch-width --destination-pixel-stride=3 --destination-line-stride=width*3
    patch-height := bottom - top
    write-buffer_ patch-height buffer

  draw-gray-scale left/int top/int right/int bottom/int pixels/ByteArray -> none:
    patch-height := bottom - top
    write-buffer_ patch-height pixels

  draw-several-color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    patch-height := bottom - top
    write-buffer_ patch-height pixels

  draw-two-color left/int top/int right/int bottom/int pixels/ByteArray -> none:
    if temp-buffer_.size < pixels.size:
      temp-buffer_ = ByteArray pixels.size
      8.repeat:
        temps_[it] = temp-buffer_[it..]

    patch-width := right - left
    assert: patch-width == rounded-width_
    patch-height := bottom - top
    assert: patch-height == (round-up patch-height 8)
    // Writes the patch to the compressor.  The patch is arranged as height/8
    // strips of width bytes, where each byte represents 8 vertically stacked
    // pixels, lsbit at the top.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom, msbit on
    // the left.

    input-bytes := (patch-width * patch-height) >> 3

    pixels-0 := pixels[0..input-bytes]
    pixels-1 := pixels[1..input-bytes]
    pixels-2 := pixels[2..input-bytes]
    pixels-4 := pixels[4..input-bytes]

    // We start by reflecting each 8x8 block.
    // Reflect each 2x2 pixel block.
    blit pixels-0 temps_[0] patch-width/2 --source-pixel-stride=2 --destination-pixel-stride=2 --mask=0xaa
    blit pixels-1 temps_[1] patch-width/2 --source-pixel-stride=2 --destination-pixel-stride=2 --mask=0x55
    blit pixels-0 temps_[1] patch-width/2 --source-pixel-stride=2 --destination-pixel-stride=2 --shift=-1 --mask=0xaa --operation=OR
    blit pixels-1 temps_[0] patch-width/2 --source-pixel-stride=2 --destination-pixel-stride=2 --shift=1 --mask=0x55 --operation=OR
    // Reflect each 4x4 pixel block.  Blit is treating each 4x8 block as a line for this operation.
    blit temps_[0] pixels-0 2 --source-line-stride=4 --destination-line-stride=4 --mask=0xcc
    blit temps_[2] pixels-2 2 --source-line-stride=4 --destination-line-stride=4 --mask=0x33
    blit temps_[0] pixels-2 2 --source-line-stride=4 --destination-line-stride=4 --shift=-2 --mask=0xcc --operation=OR
    blit temps_[2] pixels-0 2 --source-line-stride=4 --destination-line-stride=4 --shift=2 --mask=0x33 --operation=OR
    // Reflect each 8x8 pixel block.  Blit is treating each 8x8 block as a line for this operation.
    blit pixels-0 temps_[0] 4 --source-line-stride=8 --destination-line-stride=8 --mask=0xf0
    blit pixels-4 temps_[4] 4 --source-line-stride=8 --destination-line-stride=8 --mask=0x0f
    blit pixels-0 temps_[4] 4 --source-line-stride=8 --destination-line-stride=8 --shift=-4 --mask=0xf0 --operation=OR
    blit pixels-4 temps_[0] 4 --source-line-stride=8 --destination-line-stride=8 --shift=4 --mask=0x0f --operation=OR

    buffer := get-buffer_ left top right bottom

    // Now we need to spread the 8x8 blocks out over the lines they belong on.
    // First line is bytes 0, 8, 16..., next line is bytes 1, 9, 17... etc.
    8.repeat:
      index := (rounded-width_ * (7 - it)) >> 3
      blit temps_[it] buffer[index..] (patch-width >> 3) --source-pixel-stride=8 --destination-line-stride=rounded-width_ --lookup-table=INVERT_
    write-buffer_ patch-height buffer

  draw-two-bit left/int top/int right/int bottom/int plane-0/ByteArray plane-1/ByteArray -> none:
    patch-width := right - left
    assert: patch-width == rounded-width_
    patch-height := bottom - top
    assert: patch-height == (round-up patch-height 8)

    byte-width := width-to-byte-width rounded-width_

    buffer := get-buffer_ left top right bottom

    // Writes part of the patch to the compressor.  The patch is arranged as
    // height/8 strips of width bytes, where each byte represents 8 vertically
    // stacked pixels.  PNG requires these be transposed so that each
    // line is represented by consecutive bytes, from top to bottom, msbit on
    // the left.
    // This implementation is not as optimized as the two-color version.
    row := 0
    ppb := 4  // Pixels per byte.
    for y := 0; y < patch-height; y += 8:
      for in-bit := 0; in-bit < 8 and y + top + in-bit < height; in-bit++:
        out-index := (y + in-bit) * byte-width
        for x := 0; x < patch-width; x += ppb:
          out := 0
          byte-pos := row + x + ppb - 1
          for out-bit := ppb - 1; out-bit >= 0; out-bit--:
            out |= ((plane-0[byte-pos - out-bit] >> in-bit) & 1) << (out-bit * 2)
            out |= ((plane-1[byte-pos - out-bit] >> in-bit) & 1) << (out-bit * 2 + 1)
          buffer[out-index + (width-to-byte-width x)] = out
      row += rounded-width_
    write-buffer_ patch-height buffer

  static HEADER ::= #[0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n']

  static write-chunk stream name/string data/ByteArray -> none:
    length := ByteArray 4
    if name.size != 4: throw "invalid name"
    BIG-ENDIAN.put-uint32 length 0 data.size
    write_ stream length
    write_ stream name
    write_ stream data
    crc := Crc32
    crc.add name
    crc.add data
    write_ stream
      byte-swap_
        crc.get

  static write_ stream byte-array -> none:
    done := 0
    while done != byte-array.size:
      done += stream.write byte-array[done..]

  write-header_ writeable --reproducible/bool -> none:
    true-color := flags & FLAG-TRUE-COLOR != 0
    gray := flags & FLAG-4-COLOR != 0
    three-color := flags & FLAG-3-COLOR != 0
    gray-scale := flags & FLAG-GRAY-SCALE != 0
    several-color := flags & FLAG-SEVERAL-COLOR != 0

    write_ writeable HEADER

    bits-per-pixel := ?
    color-type := ?
    if true-color:
      bits-per-pixel = 8
      color-type = 2  // True color.
    else if gray-scale:
      bits-per-pixel = 8
      color-type = 0  // Gray scale.
    else if three-color:
      bits-per-pixel = 2
      color-type = 3  // Palette.
    else if several-color:
      bits-per-pixel = 8
      color-type = 3  // Palette.
    else if gray:
      bits-per-pixel = 2
      color-type = 0  // Grayscale.
    else:
      bits-per-pixel = 1
      color-type = 0  // Grayscale

    ihdr := #[
      0, 0, 0, 0,          // Width.
      0, 0, 0, 0,          // Height.
      bits-per-pixel,
      color-type,
      0, 0, 0,
    ]
    BIG-ENDIAN.put-uint32 ihdr 0 width
    BIG-ENDIAN.put-uint32 ihdr 4 height
    write-chunk writeable "IHDR" ihdr

    if three-color:
      write-chunk writeable "PLTE" #[  // Palette.
          0xff, 0xff, 0xff,         // 0 is white.
          0, 0, 0,                  // 1 is black.
          0xff, 0, 0,               // 2 is red.
        ]
    else if several-color:
      // Use color palette of 7-color epaper display.
      write-chunk writeable "PLTE" #[  // Palette.
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
      while data := compressor_.in.read:
        compressed_.write data
        if (not reproducible) and compressed_.size > 1900:
          write-chunk writeable_ "IDAT" compressed_.bytes  // Flush compressed pixel data.
          compressed_ = Buffer
      done_.set null

  write-buffer_ height/int buffer/ByteArray -> none:
    zero-byte := #[0]
    gray := flags & FLAG-4-COLOR != 0
    several-color := flags & FLAG-SEVERAL-COLOR != 0
    height.repeat: | y |
      if y_ >= this.height: return
      compressor_.out.write zero-byte  // Adaptive scheme.
      line-size := width-to-byte-width width
      index := y * line-size
      line := buffer[index..index + line-size]
      if gray:
        line = ByteArray line.size: line[it] ^ 0xff
      else if several-color:
        line = ByteArray line.size: min 6 line[it]
      compressor_.out.write line
      y_++

  write-footer_:
    compressor_.out.close

    // Wait for the reader task to finish.
    done_.get

    if compressed_.size != 0:
      write-chunk writeable_ "IDAT" compressed_.bytes  // Compressed pixel data.

    compressed_ = null
    compressor_ = null
    done_ = null
    y_ = 0

    write-chunk writeable_ "IEND" #[]  // End chunk.

byte-swap_ ba/ByteArray -> ByteArray:
  result := ba.copy
  ByteOrder.swap-32 result
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
write-to writeable --reproducible/bool=false driver/PngDriver_ display/PixelDisplay:
  driver.write-header_ writeable --reproducible=reproducible
  display.draw
  driver.write-footer_
  writeable.close
