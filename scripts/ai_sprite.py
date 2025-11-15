from PIL import Image, ImageDraw

# Sprite and sheet dimensions
frame_width, frame_height = 16, 16
cols, rows = 4, 4  # now 4 rows: running, leaping, climbing, and sword swinging
sheet_width, sheet_height = frame_width * cols, frame_height * rows

# Create a new white image in mode '1' (1-bit pixels, black and white)
sheet = Image.new('1', (sheet_width, sheet_height), 1)
draw = ImageDraw.Draw(sheet)

def draw_stickman(base_x, base_y, head, body, arms, legs):
    """Draw a stickman given coordinate tuples relative to the top-left of the frame.
       head: (cx,cy,r) circle center and radius.
       body: (x1,y1,x2,y2) line.
       arms: list of line segments [(x1,y1,x2,y2), ...].
       legs: list of line segments [(x1,y1,x2,y2), ...].
    """
    cx, cy, r = head
    # Draw head (as a circle)
    draw.ellipse((base_x+cx-r, base_y+cy-r, base_x+cx+r, base_y+cy+r), fill=0)
    # Draw body
    draw.line((base_x+body[0], base_y+body[1], base_x+body[2], base_y+body[3]), fill=0)
    # Draw arms
    for seg in arms:
        draw.line((base_x+seg[0], base_y+seg[1], base_x+seg[2], base_y+seg[3]), fill=0)
    # Draw legs
    for seg in legs:
        draw.line((base_x+seg[0], base_y+seg[1], base_x+seg[2], base_y+seg[3]), fill=0)

def draw_running(frame, variant):
    # Base parameters for a stickman in a 16x16 cell
    head = (8, 3, 2)  # center x,y and radius
    body = (8, 5, 8, 10)
    if variant == 1:
        arms = [(8, 6, 4, 8), (8, 6, 12, 8)]
        legs = [(8, 10, 4, 14), (8, 10, 10, 14)]
    elif variant == 2:
        arms = [(8, 6, 5, 8), (8, 6, 11, 8)]
        legs = [(8, 10, 6, 14), (8, 10, 10, 14)]
    elif variant == 3:
        arms = [(8, 6, 5, 8), (8, 6, 11, 8)]
        legs = [(8, 10, 10, 14), (8, 10, 4, 14)]
    else:  # variant 4 same as variant 2
        arms = [(8, 6, 5, 8), (8, 6, 11, 8)]
        legs = [(8, 10, 6, 14), (8, 10, 10, 14)]
    draw_stickman(frame[0], frame[1], head, body, arms, legs)

def draw_leaping(frame, variant):
    head = (8, 3, 2)
    # slightly shifted body for a leaping posture
    body = (8, 4, 8, 9)
    if variant == 1 or variant == 3:
        arms = [(8, 5, 4, 7), (8, 5, 12, 7)]
        legs = [(8, 9, 5, 13), (8, 9, 11, 13)]
    else:  # variant 2 and 4: a little less extreme
        arms = [(8, 5, 5, 7), (8, 5, 11, 7)]
        legs = [(8, 9, 6, 13), (8, 9, 10, 13)]
    draw_stickman(frame[0], frame[1], head, body, arms, legs)

def draw_climbing(frame, variant):
    # First, draw a simple ladder in the background
    fx, fy = frame
    # Draw ladder verticals
    draw.line((fx+5, fy+2, fx+5, fy+14), fill=0)
    draw.line((fx+11, fy+2, fx+11, fy+14), fill=0)
    # Draw ladder rungs
    for y in [5, 8, 11]:
        draw.line((fx+5, fy+y, fx+11, fy+y), fill=0)
    head = (8, 3, 2)
    body = (8, 4, 8, 9)
    if variant == 1 or variant == 3:
        arms = [(8, 6, 5, 8), (8, 6, 11, 8)]
        legs = [(8, 9, 6, 14), (8, 9, 8, 14)]
    else:
        arms = [(8, 6, 4, 8), (8, 6, 12, 8)]
        legs = [(8, 9, 7, 14), (8, 9, 9, 14)]
    draw_stickman(frame[0], frame[1], head, body, arms, legs)

def draw_swinging(frame, variant):
    """Draw a stickman swinging a sword. The sword is drawn as an extra line extending from the right arm."""
    base_x, base_y = frame
    head = (8, 3, 2)
    body = (8, 5, 8, 10)
    # Standard arms and legs for a base pose
    arms = [(8, 6, 4, 8), (8, 6, 12, 8)]
    legs = [(8, 10, 4, 14), (8, 10, 10, 14)]
    draw_stickman(base_x, base_y, head, body, arms, legs)
    
    # Draw the sword from the right hand (which is at (base_x+12, base_y+8))
    if variant == 1:
        # Sword swung upward: a diagonal line upward-right
        sword_end = (base_x+16, base_y+4)
    else:
        # Sword swung downward: a diagonal line downward-right
        sword_end = (base_x+16, base_y+12)
    draw.line((base_x+12, base_y+8, sword_end[0], sword_end[1]), fill=0)

# Loop through each row (action) and column (frame) and draw the corresponding sprite.
for row in range(rows):
    for col in range(cols):
        # Calculate top-left of current frame cell
        cell_origin = (col * frame_width, row * frame_height)
        if row == 0:
            # Running row: variants 1,2,3,4
            variant = col + 1
            draw_running(cell_origin, variant)
        elif row == 1:
            # Leaping row: alternate between two variants
            variant = 1 if col % 2 == 0 else 2
            draw_leaping(cell_origin, variant)
        elif row == 2:
            # Climbing row: alternate between two variants
            variant = 1 if col % 2 == 0 else 2
            draw_climbing(cell_origin, variant)
        else:
            # Sword swinging row: alternate between two swing variants
            variant = 1 if col % 2 == 0 else 2
            draw_swinging(cell_origin, variant)

# Save the sprite sheet image
sheet.save("sprite_sheet.png")
sheet.show()
