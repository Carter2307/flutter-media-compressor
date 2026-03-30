import numpy as np
from PIL import Image

from .base import BaseProcessor


class Labs851Processor(BaseProcessor):
    """Background removal using transparent-background (same as 851-labs/background-remover)."""

    name = "851-labs"
    description = "851-Labs - Fast InSPyReNet model, clean edges"

    def __init__(self):
        self.remover = None

    def load_model(self) -> None:
        """Load the transparent-background model."""
        from transparent_background import Remover

        self.remover = Remover(mode="fast")

    def remove_background(self, image: Image.Image) -> Image.Image:
        """Remove background using transparent-background."""
        if self.remover is None:
            self.load_model()

        # Convert to RGB if needed
        if image.mode != "RGB":
            image = image.convert("RGB")

        # Process the image
        result = self.remover.process(image, type="rgba")

        return result

    def is_loaded(self) -> bool:
        return self.remover is not None