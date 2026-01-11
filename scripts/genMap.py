import argparse
import sys
import os.path
from PIL import Image

def value4x4(im,x,y,bg=0):
    # Order:
    #   37BF
    #   26AE
    #   159D
    #   048C
    #
    #    .byte   %1111       ; ####
    #    .byte   %0111       ; ###_
    #    .byte   %0011       ; ##__
    #    .byte   %0001       ; #___
    #
    #   .byte %1111,%0111,%0011,%0001

    value = ""
    for dx in range(4):
        if (dx>0):
            value += ","
        value += "%"
        for dy in reversed(range(4)):
            if (im.getpixel((x+dx,y+dy)) == bg):
                value += "0"
            else:
                value += "1"
    return value


def main():
    parser = argparse.ArgumentParser(   prog='genMap',
                                        description='Generate a map for lander from an image')
    parser.add_argument('filename')     # image file
    args = parser.parse_args()

    im = Image.open(args.filename)
    print(f"; {args.filename} {im.format} {im.size} {im.mode}")


    # scan image for tiles and count how many of each
    tileCount = {}
    for y in range(0,im.size[1],4):
        for x in range(0,im.size[0],4):
            value = value4x4(im,x,y)
            if (tileCount.get(value) is None):
                tileCount[value] = 1
            else:
                tileCount[value] += 1

    print(f"MAP_WIDTH = {im.size[0]>>2}")
    print(f"MAP_HEIGHT = {im.size[1]>>2}")
    print(".align 256")
    print("mapTiles:")
    index = 0
    tileIndex = {}
    for (value,count) in sorted(tileCount.items(), key=lambda item: item[1], reverse=True):
        print(f".byte {value} ; ${index:02X} freq={count}")
        tileIndex[value] = index
        index += 4

    print(".align 256")
    print("map:")
    for y in range(0,im.size[1],4):
        print(".byte ",end="")
        for x in range(0,im.size[0],4):
            value = value4x4(im,x,y)
            if (x>0):
                print(",",end="")
            print(f"${tileIndex[value]:02X}",end="")
        print()

main()

