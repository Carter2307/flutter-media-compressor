import numpy as np
from PIL import Image


class LamaInpainter:
    """LaMa-based inpainting using IOPaint."""

    name = "lama"
    description = "LaMa inpainting model for object removal"

    def __init__(self):
        self._model = None

    def load_model(self) -> None:
        try:
            from iopaint.model_manager import ModelManager

            self._model = ModelManager(name="lama", device="cpu")
        except ImportError:
            raise ImportError(
                "iopaint is required for object removal. "
                "Install it with: pip install iopaint"
            )

    def is_loaded(self) -> bool:
        return self._model is not None

    def inpaint(self, image: Image.Image, mask: Image.Image) -> Image.Image:
        if not self.is_loaded():
            self.load_model()

        # Convert to numpy arrays as expected by iopaint
        img_array = np.array(image.convert("RGB"))
        mask_array = np.array(mask.convert("L"))

        # Ensure mask is binary (0 or 255)
        mask_array = (mask_array > 127).astype(np.uint8) * 255

        result = self._model(img_array, mask_array)
        return Image.fromarray(result)
