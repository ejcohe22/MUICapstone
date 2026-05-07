import base64
import requests
import typer
from typing import Optional
from rich.console import Console
from rich.panel import Panel

app = typer.Typer(help="Anceps Inference CLI - Slopn't Edition")
console = Console()

API_URL = "http://localhost:8000"
API_KEY = "dev-key"  # Should ideally be from env


@app.command()
def image(
    prompt: str = typer.Argument(..., help="Text prompt for image generation"),
    output: str = typer.Option("output.png", help="Output file path"),
    neg_prompt: Optional[str] = typer.Option(None, "--neg", help="Negative prompt")
):
    """Generate an image using SDXL."""
    payload = {
        "prompt": prompt,
        "negative_prompt": neg_prompt
    }
    
    _execute_generate(payload, output)


@app.command()
def video(
    image_path: str = typer.Argument(..., help="Path to source image"),
    output: str = typer.Option("output.png", help="Output file path (prefix for frames)"),
    frames: int = typer.Option(25, help="Number of frames")
):
    """Generate a video using SVD."""
    with open(image_path, "rb") as f:
        img_b64 = base64.b64encode(f.read()).decode()
        
    payload = {
        "image_base64": img_b64,
        "num_frames": frames
    }
    
    _execute_generate(payload, output)


def _execute_generate(payload: dict, output_path: str):
    headers = {"Authorization": f"Bearer {API_KEY}"}
    
    with console.status("[bold green]Generating..."):
        try:
            res = requests.post(f"{API_URL}/generate", headers=headers, json=payload)
            res.raise_for_status()
            data = res.json()
        except Exception as e:
            console.print(f"[bold red]Error:[/bold red] {e}")
            return

    if data.get("success"):
        out_type = data["type"]
        payload_data = data["payload"]
        
        if out_type == "image":
            with open(output_path, "wb") as f:
                f.write(base64.b64decode(payload_data))
            console.print(Panel(f"Successfully saved image to [bold cyan]{output_path}[/bold cyan]"))
        
        elif out_type == "video":
            # For SVD, payload is a list of b64 frames
            for i, frame_b64 in enumerate(payload_data):
                frame_path = f"frame_{i:03d}_{output_path}"
                with open(frame_path, "wb") as f:
                    f.write(base64.b64decode(frame_b64))
            console.print(Panel(f"Saved {len(payload_data)} frames with prefix [bold cyan]{output_path}[/bold cyan]"))
            
        else:
            console.print(f"Received data: {payload_data}")


@app.command()
def health():
    """Check the health of the inference server."""
    try:
        res = requests.get(f"{API_URL}/health")
        console.print_json(data=res.json())
    except Exception as e:
        console.print(f"[bold red]Offline:[/bold red] {e}")


if __name__ == "__main__":
    app()
