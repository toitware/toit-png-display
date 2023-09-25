import pixel_display show PixelDisplay
import png_display show *
import host.file show *
import host.pipe

/**
Writes a PNG file to the given filename.
Only light compression is used, basically just run-length encoding
  of equal pixels.  This is fast and reduces memory use.
*/
write_file filename/string driver/PngDriver_ display/PixelDisplay:
  if filename == "-":
    write_to
        pipe.stdout
        driver
        display
  else:
    write_to
        Stream.for_write filename
        driver
        display
