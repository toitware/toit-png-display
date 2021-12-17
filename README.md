# toit-png-display

A pseudo-pixel-display that writes PNG files.

This is intended for use in generating PNG files to stream
over HTTP etc.

It has also been used for writing display tutorials.

Since it uses the nano-zlib in Toit the PNG files it produces
are run-length encoded, not fully compressed.  They are
fully compatible with browsers and other PNG tools.

Transparency is not currently supported.

Supported modes:
* True-color
* Several-color (up to 256 colors) (currently with a fixed palette).
* Grayscale
* Three-color (white, black, red)
* Two-color (white, black)
* Four-gray (white, black, light gray, dark gray)
