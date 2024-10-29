import random
import math

def generate_random_point_on_unit_circle(scale):
  """Generates a scale random point from the unit circle.

  Returns:
    A tuple (x, y) representing the coordinates of the random point.
  """

  # Generate a random angle between 0 and 2π
  theta = random.uniform(0, 2 * math.pi)

  # Calculate the x and y coordinates using the angle
  x = scale*math.cos(theta)
  y = scale*math.sin(theta)

  return x, y

def convert_to_apple_hex(value):
  hex_string = str(hex(value))[2:]
  return hex_string

def convert_float_to_fixed_binary(value):
  """Generates a 2-byte fixed binary representation of a float

  Returns:
    A tuple (s, f) representing sign and fraction
  """

  if value >= 0:
    return convert_to_apple_hex(int(value*255)), convert_to_apple_hex(0)
  else:
    return convert_to_apple_hex(int((1+value)*255)), convert_to_apple_hex(255)


print(";       age, x0,  x1,  y0,  y1,  vx0, vx1, vy0, vy1, c0,  c1,  bg")
print(";       ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---")
# Generate and print 5 random points
for _ in range(14):
  age = convert_to_apple_hex(random.randint(10,30))  # age 20 * scale .5 ~= 10 pixels
  x0 = "80"
  x1 = "00"
  y0 = "80"
  y1 = "00"
  color = random.choice([0xb,0xc,0xd,0xe,0xf])
  c0 = convert_to_apple_hex(color)
  c1 = convert_to_apple_hex(color*16)
  scale = random.uniform(0.25, 0.75)
  point = generate_random_point_on_unit_circle(scale)
  fixed = convert_float_to_fixed_binary(point[0]),convert_float_to_fixed_binary(point[1])
  bg = "55"
  (vx0,vx1),(vy0,vy1) = fixed
  print("  .byte ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}, ${:2}".format(age,x0,x1,y0,y1,vx0,vx1,vy0,vy1,c0,c1,bg))
