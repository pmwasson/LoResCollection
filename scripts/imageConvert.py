import sys
import os.path
from PIL import Image

# Usage: inputFile outputFile
# FIXME: use a real command line parser

def main():

    apple2_palette = [
        0,   0,   0,         # black
        153, 3,   95,        # red(ish)
        66,  4,   225,       # dark blue
        202, 19,  254,       # purple
        0,   115, 16,        # dark green
        127, 127, 127,       # gray 1
        36,  151, 244,       # medium blue
        170, 162, 255,       # light blue
        79,  81,  1,         # brown
        240, 92,  0,         # orange
        127, 127, 127,       # gray 2
        255, 133, 225,       # pink
        18,  202, 7,         # light green
        206, 212, 19,        # yellow
        81,  245, 149,       # aqua
        255, 255, 255        # white
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

    allData = []
    for y in range(0,im.size[1],2):
        line = []
        for x in range(im.size[0]):
            # combine 2 pixel row into 1 byte row
            evenPixel = hex(im.getpixel((x,y)))
            oddPixel  = hex(im.getpixel((x,y+1)))
            byte = "$" + oddPixel[2:] + evenPixel[2:]
            line.append(byte)
        allData.append(line)

    name = os.path.basename(os.path.splitext(outfile)[0])
    print("{}:".format(name))
    for line in allData:
        print(".byte ",end="")
        print(*line,sep=",")

main()