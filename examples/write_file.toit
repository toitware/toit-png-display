import pixel_display show PixelDisplay
import png_display show *
import server.file show *

/**
Writes a PNG file to the given filename.
Only light compression is used, basically just run-length encoding
  of equal pixels.  This is fast and reduces memory use.
*/
write_file filename/string driver/PngDriver_ display/PixelDisplay:
  write_to
      Stream.for_write filename
      driver
      display

