# inference/cli.py

import base64

import requests
import typer

app = typer.Typer()

API_URL = "http://localhost:8000"


@app.command()
def generate(prompt: str):
    res = requests.post(
        f"{API_URL}/generate",
        headers={"Authorization": "Bearer dev-key"},
        json={"prompt": prompt},
    )

    data = res.json()

    if data["result"]["type"] == "image":
        img_b64 = data["result"]["data"]
        with open("output.png", "wb") as f:
            f.write(base64.b64decode(img_b64))

        print("Saved to output.png")


@app.command()
def health():
    print(requests.get(f"{API_URL}/health").json())


if __name__ == "__main__":
    app()
