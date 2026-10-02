from PIL import Image, ImageDraw, ImageFont
import os

img = Image.new('RGB', (1024, 1024), color='#059669')
draw = ImageDraw.Draw(img)

try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 750)
except Exception as e:
    print(f"Font not found: {e}")
    font = ImageFont.load_default()

bbox = draw.textbbox((0, 0), "C", font=font)
w = bbox[2] - bbox[0]
h = bbox[3] - bbox[1]

draw.text(((1024-w)/2 - bbox[0], (1024-h)/2 - bbox[1]), "C", font=font, fill=(255, 255, 255))
os.makedirs("assets", exist_ok=True)
img.save("assets/icon.png")
print("Done!")
