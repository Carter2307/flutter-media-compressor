from typing import Dict

from .base import BaseUpscaler
from .super_image_upscaler import SuperImageUpscaler


# Available upscaler configurations
UPSCALER_CONFIGS = [
    {"model": "edsr", "scale": 2},
    {"model": "edsr", "scale": 4},
    {"model": "msrn", "scale": 2},
    {"model": "msrn", "scale": 4},
    {"model": "a2n", "scale": 2},
    {"model": "pan", "scale": 2},
]

# Cache for loaded upscalers
_upscaler_cache: Dict[str, BaseUpscaler] = {}


def _get_upscaler_name(model: str, scale: int) -> str:
    return f"{model}-x{scale}"


def get_upscaler(name: str, preload: bool = True) -> BaseUpscaler:
    """
    Get an upscaler instance by name.

    Args:
        name: Upscaler name (e.g., 'edsr-x2', 'msrn-x4')
        preload: Whether to preload the model

    Returns:
        Upscaler instance

    Raises:
        ValueError: If upscaler name is not found
    """
    available_names = [_get_upscaler_name(c["model"], c["scale"]) for c in UPSCALER_CONFIGS]

    if name not in available_names:
        raise ValueError(f"Unknown upscaler: {name}. Available: {', '.join(available_names)}")

    # Return cached instance if available
    if name in _upscaler_cache:
        return _upscaler_cache[name]

    # Parse name to get model and scale
    parts = name.rsplit("-x", 1)
    model = parts[0]
    scale = int(parts[1])

    # Create new instance
    upscaler = SuperImageUpscaler(model_name=model, scale=scale)

    if preload:
        upscaler.load_model()

    _upscaler_cache[name] = upscaler
    return upscaler


def list_upscalers() -> list[dict]:
    """List all available upscalers with their metadata."""
    return [
        {
            "name": _get_upscaler_name(config["model"], config["scale"]),
            "model": config["model"],
            "scale": config["scale"],
            "description": f"{config['model'].upper()} {config['scale']}x upscaling",
        }
        for config in UPSCALER_CONFIGS
    ]
