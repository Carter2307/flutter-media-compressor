from PIL import Image
import numpy as np
import torch

from .base import BaseUpscaler


def get_device():
    """Get the best available device."""
    if torch.cuda.is_available():
        return torch.device("cuda")
    elif torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


class SuperImageUpscaler(BaseUpscaler):
    """Upscaler using super_image library."""

    def __init__(self, model_name: str = "edsr", scale: int = 2):
        self.model_name = model_name
        self.scale = scale
        self.model = None
        self.device = get_device()
        self.name = f"{model_name}-x{scale}"
        self.description = f"{model_name.upper()} {scale}x upscaling"

    def load_model(self) -> None:
        """Load the super_image model."""
        if self.model is not None:
            return

        from super_image import (
            EdsrModel,
            MsrnModel,
            A2nModel,
            PanModel,
        )

        model_map = {
            "edsr": (EdsrModel, f"eugenesiow/edsr-base", f"scale{self.scale}"),
            "msrn": (MsrnModel, f"eugenesiow/msrn", f"scale{self.scale}"),
            "a2n": (A2nModel, f"eugenesiow/a2n", f"scale{self.scale}"),
            "pan": (PanModel, f"eugenesiow/pan", f"scale{self.scale}"),
        }

        if self.model_name not in model_map:
            raise ValueError(f"Unknown model: {self.model_name}")

        model_class, model_path, revision = model_map[self.model_name]
        self.model = model_class.from_pretrained(model_path, scale=self.scale).to(self.device)
        print(f"Model {self.name} loaded on {self.device}")

    def upscale(self, image: Image.Image) -> Image.Image:
        """Upscale the image using super_image."""
        if self.model is None:
            self.load_model()

        from super_image import ImageLoader

        # Convert to RGB if necessary
        if image.mode != "RGB":
            image = image.convert("RGB")

        # Process with super_image (no_grad for inference)
        inputs = ImageLoader.load_image(image).to(self.device)
        with torch.no_grad():
            preds = self.model(inputs)

        # Convert back to PIL
        output = preds.squeeze(0).permute(1, 2, 0).clamp(0, 1).cpu().numpy()
        output = (output * 255).astype(np.uint8)

        return Image.fromarray(output)

    def is_loaded(self) -> bool:
        return self.model is not None
