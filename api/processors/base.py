from abc import ABC, abstractmethod
from PIL import Image


class BaseProcessor(ABC):
    """Abstract base class for background removal processors."""

    name: str = "base"
    description: str = "Base processor"

    @abstractmethod
    def load_model(self) -> None:
        """Load the model into memory. Called once at startup."""
        pass

    @abstractmethod
    def remove_background(self, image: Image.Image) -> Image.Image:
        """
        Remove background from an image.

        Args:
            image: PIL Image in RGB or RGBA format

        Returns:
            PIL Image with transparent background (RGBA)
        """
        pass

    def is_loaded(self) -> bool:
        """Check if the model is loaded."""
        return True
