from typing import Dict, Type

from .base import BaseProcessor
from .rembg_processor import RembgProcessor
from .birefnet_processor import BiRefNetProcessor
from .labs851_processor import Labs851Processor


# Registry of available processors
PROCESSORS: Dict[str, Type[BaseProcessor]] = {
    "rembg": RembgProcessor,
    "birefnet": BiRefNetProcessor,
    "851-labs": Labs851Processor,
}

# Cache for loaded processors
_processor_cache: Dict[str, BaseProcessor] = {}


def get_processor(name: str, preload: bool = True) -> BaseProcessor:
    """
    Get a processor instance by name.

    Args:
        name: Processor name ('rembg' or 'birefnet')
        preload: Whether to preload the model

    Returns:
        Processor instance

    Raises:
        ValueError: If processor name is not found
    """
    if name not in PROCESSORS:
        available = ", ".join(PROCESSORS.keys())
        raise ValueError(f"Unknown processor: {name}. Available: {available}")

    # Return cached instance if available
    if name in _processor_cache:
        return _processor_cache[name]

    # Create new instance
    processor = PROCESSORS[name]()

    if preload:
        processor.load_model()

    _processor_cache[name] = processor
    return processor


def list_processors() -> list[dict]:
    """List all available processors with their metadata."""
    return [
        {
            "name": name,
            "description": cls.description if hasattr(cls, 'description') else "",
        }
        for name, cls in PROCESSORS.items()
    ]
