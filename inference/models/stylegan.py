import torch
from PIL import Image

from inference.models.base import ModelAdapter


class StyleGANModel(ModelAdapter):
    def load(self):
        # Example using torch hub or local weights
        self.device = self.context.device

        # Placeholder – replace with actual StyleGAN load
        self.G = torch.jit.load("stylegan.pt").to(self.device)
        self.G.eval()

    def generate(self, payload: dict) -> dict:
        latent = payload.get("latent")

        if latent is None:
            # fallback: random latent
            seed = payload.get("seed", 0)
            torch.manual_seed(seed)
            z = torch.randn(1, 512).to(self.device)
        else:
            z = torch.tensor(latent, dtype=torch.float32).to(self.device)
            z = z.unsqueeze(0)

        with torch.no_grad():
            img = self.G(z)

        img = (img.clamp(-1, 1) + 1) / 2
        img = (img * 255).byte().cpu().numpy()[0].transpose(1, 2, 0)

        pil_img = Image.fromarray(img)

        return {
            "type": "image",
            "image": pil_img,  # you may want base64 for consistency
        }
