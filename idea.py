import base64
import requests

# Anceps Inference - Slopn't Example
URL = "http://127.0.0.1:8000/generate"
HEADERS = {"Content-Type": "application/json", "Authorization": "Bearer dev-key"}

def generate_slopnt_image(prompt: str, output_path: str = "output.png"):
    payload = {
        "prompt": prompt,
        "negative_prompt": "blurry, low quality, slop"
    }

    print(f"Requesting generation: '{prompt}'...")
    
    response = requests.post(URL, json=payload, headers=HEADERS)
    response.raise_for_status()
    
    data = response.json()
    
    if data["success"] and data["type"] == "image":
        img_bytes = base64.b64decode(data["payload"])
        with open(output_path, "wb") as f:
            f.write(img_bytes)
        print(f"Success! Saved slopn't image to {output_path}")
    else:
        print(f"Failed to generate image. Response: {data}")

if __name__ == "__main__":
    generate_slopnt_image(
        prompt="A photo of a GAN-generated landscape that is unironically slopn't"
    )
