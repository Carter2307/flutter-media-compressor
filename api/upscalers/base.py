from abc import ABC, abstractmethod
from PIL import Image


class BaseUpscaler(ABC):
    """Abstract base class for image upscalers."""

    name: str = "base"
    description: str = "Base upscaler"
    scale: int = 2

    @abstractmethod
    def load_model(self) -> None:
        """Load the model into memory."""
        pass

    @abstractmethod
    def upscale(self, image: Image.Image) -> Image.Image:
        """
        Upscale an image.

        Args:
            image: PIL Image

        Returns:
            Upscaled PIL Image
        """
        pass

    def is_loaded(self) -> bool:
        """Check if the model is loaded."""
        return True
