import sys
import os.path
from PIL import Image
from collections import defaultdict

# Usage: inputFile outputFile
# FIXME: use a real command line parser

def main():

    apple2_palette = [
        0,   0,   0,        # black
        153, 3,   95,       # red(ish)
        66,  4,   225,      # dark blue
        202, 19,  254,      # purple
        0,   115, 16,       # dark green
        127, 127, 127,      # gray 1
        36,  151, 244,      # medium blue
        170, 162, 255,      # light blue
        79,  81,  1,        # brown
        240, 92,  0,        # orange
        127, 127, 127,      # gray 2
        255, 133, 225,      # pink
        18,  202, 7,        # light green
        206, 212, 19,       # yellow
        81,  245, 149,      # aqua
        255, 255, 255       # white
    ];

    line_address = [
        0x0000,             # 0
        0x0080,             # 1
        0x0100,             # 2
        0x0180,             # 3
        0x0200,             # 4
        0x0280,             # 5
        0x0300,             # 6
        0x0380,             # 7
        0x0028,             # 8
        0x00A8,             # 9
        0x0128,             # 10
        0x01A8,             # 11
        0x0228,             # 12
        0x02A8,             # 13
        0x0328,             # 14
        0x03A8,             # 15
        0x0050,             # 16
        0x00D0,             # 17
        0x0150,             # 18
        0x01D0,             # 19
        0x0250,             # 20
        0x02D0,             # 21
        0x0350,             # 22
        0x03D0,             # 23
    ];


    # create dummy image with apple2 low res palette
    p_img = Image.new('P', (40, 48))
    p_img.putpalette(apple2_palette * 16)


    print(";","--------------------------------------------------------------------")

    infile = sys.argv[1]
    outfile = sys.argv[2]
    # width = int(sys.argv[3])
    # height = int(sys.argv[4])

    im = Image.open(infile)
    print(";",infile,im.format, im.size, im.mode)
    #im = im.resize((width,height)).quantize(palette=p_img, dither=0)
    im = im.convert('RGB').quantize(palette=p_img, dither=0)
    im.save(outfile)
    print(";",outfile,im.format, im.size, im.mode)

    # assume 0,0 is the backgound color
    background = im.getpixel((0,0))
    print("; assume background = ",background)

    # put bytes into 3 buckets, full, even (low-nibble) or odd (high-nibble)
    fullByte = defaultdict(list)
    evenByte = {}
    oddByte = {}

    for y in range(0,im.size[1],2):
        for x in range(im.size[0]):
            # combine 2 pixel row into 1 byte
            evenPixel = im.getpixel((x,y))
            oddPixel  = im.getpixel((x,y+1))
            address = line_address[y//2]+x;
            value = evenPixel + oddPixel*16

            # print("address:",address)
            # print("value:",value)

            if (evenPixel != background) and (oddPixel != background):
                fullByte[value].append(address)
            elif (evenPixel != background):
                evenByte[address] = evenPixel
            elif (oddPixel != background):
                oddByte[address] = oddPixel*16

    name = os.path.basename(os.path.splitext(outfile)[0])

    for addressOffset in [0x400,0x800]:
        print("{}:".format(name + "_" + hex(addressOffset)))
        print("  ; full bytes")
        for value, addressList in fullByte.items():
            hexValue = hex(int(value))
            print("  lda #${}".format(hexValue[2:]))
            for address in addressList:
                hexAddress = hex(address+addressOffset)
                print("  sta ${}".format(hexAddress[2:]))

        print("  ; even bytes")
        for address, value in evenByte.items():
            hexValue = hex(int(value))
            hexAddress = hex(address+addressOffset)
            print("  lda ${}".format(hexAddress[2:]))
            print("  and #$f0")
            if (value != 0):
                print("  ora #${}".format(hexValue[2:]))
            print("  sta ${}".format(hexAddress[2:]))

        print("  ; odd bytes")
        for address, value in oddByte.items():
            hexValue = hex(int(value))
            hexAddress = hex(address+addressOffset)
            print("  lda ${}".format(hexAddress[2:]))
            print("  and #$0f")
            if (value != 0):
                print("  ora #${}".format(hexValue[2:]))
            print("  sta ${}".format(hexAddress[2:]))

        print("  rts")

main()