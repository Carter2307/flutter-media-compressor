from PIL import Image
from rembg import remove, new_session

from .base import BaseProcessor


class RembgProcessor(BaseProcessor):
    """Background removal using rembg library with U2-Net model."""

    name = "rembg"
    description = "Rembg with U2-Net - Fast and reliable, good for most images"

    def __init__(self, model_name: str = "u2net"):
        self.model_name = model_name
        self.session = None

    def load_model(self) -> None:
        """Pre-load the rembg session for faster inference."""
        self.session = new_session(self.model_name)

    def remove_background(self, image: Image.Image) -> Image.Image:
        """Remove background using rembg."""
        if self.session is None:
            self.load_model()
        return remove(image, session=self.session)

    def is_loaded(self) -> bool:
        return self.session is not None
