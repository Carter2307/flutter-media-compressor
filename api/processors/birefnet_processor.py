import numpy as np
from PIL import Image
import torch
from torchvision import transforms

from .base import BaseProcessor


class BiRefNetProcessor(BaseProcessor):
    """Background removal using BiRefNet model - Better quality for complex images."""

    name = "birefnet"
    description = "BiRefNet - Higher quality, better for hair and fine details"

    def __init__(self):
        self.model = None
        self.device = None
        self.transform = transforms.Compose([
            transforms.Resize((1024, 1024)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])

    def load_model(self) -> None:
        """Load BiRefNet model from HuggingFace."""
        from transformers import AutoModelForImageSegmentation

        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = AutoModelForImageSegmentation.from_pretrained(
            "ZhengPeng7/BiRefNet",
            trust_remote_code=True
        )
        # Force float32 to avoid float16/float32 mismatch on CPU/MPS
        self.model.to(self.device).float()
        self.model.eval()

    def remove_background(self, image: Image.Image) -> Image.Image:
        """Remove background using BiRefNet."""
        if self.model is None:
            self.load_model()

        original_size = image.size

        # Convert to RGB if needed
        if image.mode != "RGB":
            image = image.convert("RGB")

        # Prepare input
        input_tensor = self.transform(image).unsqueeze(0).to(self.device)

        # Inference
        with torch.no_grad():
            preds = self.model(input_tensor)[-1].sigmoid().cpu()

        # Process mask
        pred = preds[0].squeeze()
        mask = (pred * 255).numpy().astype(np.uint8)
        mask = Image.fromarray(mask).resize(original_size, Image.LANCZOS)

        # Apply mask to original image
        image_rgba = image.convert("RGBA")
        image_rgba.putalpha(mask)

        return image_rgba

    def is_loaded(self) -> bool:
        return self.model is not None
