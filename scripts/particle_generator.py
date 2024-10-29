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


print(";       vx0, vx1, vy0, vy1")
print(";       ---- ---- ---- ---")
for _ in range(64):
  age = convert_to_apple_hex(random.randint(10,30))  # age 20 * scale .5 ~= 10 pixels
  scale = random.uniform(0.25, 0.75)
  point = generate_random_point_on_unit_circle(scale)
  fixed = convert_float_to_fixed_binary(point[0]),convert_float_to_fixed_binary(point[1])
  (vx0,vx1),(vy0,vy1) = fixed
  print("  .byte ${:2}, ${:2}, ${:2}, ${:2}    ; scale={:6.2}  {:8.2},{:8.2}".format(vx0,vx1,vy0,vy1,scale,point[0],point[1]))
