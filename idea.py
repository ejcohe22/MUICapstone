import base64

import requests

url = "http://127.0.0.1:8000/generate"

headers = {"Content-Type": "application/json", "Authorization": "Bearer dev-key"}

payload = {
    "prompt": (
        "A picture of something that AI struggle to reproduce convincingly",
        "and it is not AI WEIWEI",
    )
}

# Send request
response = requests.post(url, json=payload, headers=headers)
response.raise_for_status()

data = response.json()

# Extract base64 image
img_b64 = data["result"]["image_base64"]

# Decode image
img_bytes = base64.b64decode(img_b64)

# Save to file
output_file = "output.png"
with open(output_file, "wb") as f:
    f.write(img_bytes)

print(f"Saved image to {output_file}")
