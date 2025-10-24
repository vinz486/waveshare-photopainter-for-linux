# Waveshare PhotoPainter for Linux

A Linux-compatible image conversion tool for Waveshare e-paper displays that supports 7-color PhotoPainter devices.

## What it does

This tool converts JPEG images to the specific format required by Waveshare PhotoPainter e-paper displays:

- Converts images to 480x800 (portrait) or 800x480 (landscape) resolution
- Applies color palette mapping using either a custom `colors.act` file or a default 7-color palette
- Outputs uncompressed 24-bit BMP files compatible with PhotoPainter devices
- Uses Floyd-Steinberg dithering for better image quality
- Ensures proper color format (DirectClass/TrueColor) to avoid palette issues

## Dependencies

### System Requirements

- **ImageMagick**: For image processing and conversion
- **Python 3**: For palette processing
- **Pillow**: Python imaging library for ACT file handling

### Installation

**Ubuntu/Debian:**
```bash
sudo apt install imagemagick python3 python3-pip
python3 -m pip install --user pillow
```

**Other Linux distributions:**
Install ImageMagick and Python 3 using your package manager, then install Pillow:
```bash
python3 -m pip install --user pillow
```

## Usage

### Basic Usage

Convert all JPEG files in the current directory (portrait mode):
```bash
./convert.sh
```

Convert specific files:
```bash
./convert.sh image1.jpg image2.jpeg
```

Convert to landscape mode (800x480):
```bash
./convert.sh --landscape
./convert.sh --landscape image1.jpg image2.jpeg
```

### Custom Color Palette

Place a `colors.act` file in the same directory as the script to use a custom color palette. The script supports:
- Standard 768-byte ACT files (256 colors)
- Extended 772-byte ACT files (with color count and transparency info)
- Custom ACT files with any number of colors (must be multiple of 3 bytes)

If no `colors.act` file is found, the script uses a default 7-color palette: black, white, green, blue, red, yellow, and orange.

### Output

Converted images are saved in the `./pic/` directory as uncompressed 24-bit BMP files, ready for use with PhotoPainter devices.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.