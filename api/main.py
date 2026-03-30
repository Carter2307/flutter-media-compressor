import os
import io
import logging

from fastapi import FastAPI, File, UploadFile, HTTPException, Query, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from PIL import Image
from contextlib import asynccontextmanager

from processors import get_processor, list_processors
from upscalers import get_upscaler, list_upscalers


# Configuration via environment variables
PORT = int(os.environ.get("PORT", "8000"))
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "http://localhost:*").split(",")
MAX_IMAGE_SIZE_MB = int(os.environ.get("MAX_IMAGE_SIZE_MB", "50"))
LOG_LEVEL = os.environ.get("LOG_LEVEL", "info").upper()

logging.basicConfig(level=getattr(logging, LOG_LEVEL, logging.INFO))
logger = logging.getLogger(__name__)

# Defaults
DEFAULT_PROCESSOR = "birefnet"
DEFAULT_UPSCALER = "edsr-x2"
MAX_FILE_SIZE = MAX_IMAGE_SIZE_MB * 1024 * 1024
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "webp", "heic", "tiff"}
MAX_RESOLUTION = 8192


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Preload default models on startup."""
    logger.info(f"Loading default processor: {DEFAULT_PROCESSOR}")
    get_processor(DEFAULT_PROCESSOR, preload=True)
    logger.info("Processor loaded!")

    logger.info(f"Loading default upscaler: {DEFAULT_UPSCALER}")
    get_upscaler(DEFAULT_UPSCALER, preload=True)
    logger.info("Upscaler loaded!")

    logger.info("All models ready!")
    yield


app = FastAPI(title="Image Utility API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Error handling ---

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "detail": exc.detail,
            "code": f"HTTP_{exc.status_code}",
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc),
            "code": "INTERNAL_ERROR",
        },
    )


# --- Validation helpers ---

def validate_image(file: UploadFile) -> None:
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    ext = file.filename.rsplit(".", 1)[-1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"File type not allowed. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
        )


def validate_mime_type(file: UploadFile) -> None:
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")


async def read_and_validate_image(file: UploadFile) -> Image.Image:
    validate_image(file)
    validate_mime_type(file)

    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max {MAX_IMAGE_SIZE_MB}MB allowed."
        )

    try:
        image = Image.open(io.BytesIO(contents))
        if image.width > MAX_RESOLUTION or image.height > MAX_RESOLUTION:
            raise HTTPException(
                status_code=400,
                detail=f"Image resolution too high. Max {MAX_RESOLUTION}x{MAX_RESOLUTION}px."
            )
        return image
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")


def image_to_streaming_response(
    image: Image.Image,
    format: str = "PNG",
    filename: str = "output.png",
    quality: int | None = None,
) -> StreamingResponse:
    img_byte_arr = io.BytesIO()
    save_kwargs = {"format": format}
    if quality is not None and format.upper() in ("JPEG", "WEBP"):
        save_kwargs["quality"] = quality
    if format.upper() == "PNG" and image.mode == "RGBA":
        save_kwargs["format"] = "PNG"
    image.save(img_byte_arr, **save_kwargs)
    img_byte_arr.seek(0)

    media_types = {
        "PNG": "image/png",
        "JPEG": "image/jpeg",
        "WEBP": "image/webp",
    }

    return StreamingResponse(
        img_byte_arr,
        media_type=media_types.get(format.upper(), "image/png"),
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# --- Health ---

@app.get("/health")
async def health_check():
    return {"status": "healthy"}


# --- Processors (Background Removal) ---

@app.get("/api/processors")
async def get_processors():
    """List available background removal processors."""
    processors = list_processors()
    return {
        "processors": processors,
        "default": DEFAULT_PROCESSOR,
    }


@app.post("/api/remove-background")
async def remove_background(
    file: UploadFile = File(...),
    processor: str = Query(default=DEFAULT_PROCESSOR, description="Processor to use"),
):
    input_image = await read_and_validate_image(file)

    try:
        bg_processor = get_processor(processor)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    try:
        output_image = bg_processor.remove_background(input_image)
        return image_to_streaming_response(
            output_image,
            format="PNG",
            filename="removed_bg.png",
        )
    except Exception as e:
        logger.error(f"Error removing background: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


# --- Upscalers ---

@app.get("/api/upscalers")
async def get_upscalers():
    """List available image upscalers."""
    upscalers = list_upscalers()
    return {
        "upscalers": upscalers,
        "default": DEFAULT_UPSCALER,
    }


@app.post("/api/upscale")
async def upscale_image(
    file: UploadFile = File(...),
    upscaler: str = Query(default=DEFAULT_UPSCALER, description="Upscaler to use"),
):
    input_image = await read_and_validate_image(file)

    try:
        img_upscaler = get_upscaler(upscaler)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    try:
        output_image = img_upscaler.upscale(input_image)
        return image_to_streaming_response(
            output_image,
            format="PNG",
            filename="upscaled.png",
        )
    except Exception as e:
        logger.error(f"Error upscaling image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error upscaling image: {str(e)}")


# --- Compress ---

@app.post("/api/compress")
async def compress_image(
    file: UploadFile = File(...),
    quality: int = Query(default=80, ge=1, le=100, description="Compression quality (1-100)"),
    format: str = Query(default="jpeg", description="Output format: jpeg, webp, png"),
):
    input_image = await read_and_validate_image(file)

    format_upper = format.upper()
    if format_upper not in ("JPEG", "WEBP", "PNG"):
        raise HTTPException(status_code=400, detail="Format must be jpeg, webp, or png")

    try:
        # Convert to RGB for JPEG (no alpha channel support)
        if format_upper == "JPEG" and input_image.mode in ("RGBA", "P"):
            input_image = input_image.convert("RGB")

        # Get original size
        original_buf = io.BytesIO()
        input_image.save(original_buf, format=format_upper)
        original_size = original_buf.tell()

        # Compress
        compressed_buf = io.BytesIO()
        save_kwargs = {"format": format_upper}
        if format_upper in ("JPEG", "WEBP"):
            save_kwargs["quality"] = quality
            if format_upper == "JPEG":
                save_kwargs["optimize"] = True
        elif format_upper == "PNG":
            save_kwargs["optimize"] = True

        input_image.save(compressed_buf, **save_kwargs)
        compressed_size = compressed_buf.tell()
        compressed_buf.seek(0)

        ext = "jpg" if format_upper == "JPEG" else format.lower()
        media_types = {"JPEG": "image/jpeg", "WEBP": "image/webp", "PNG": "image/png"}

        return StreamingResponse(
            compressed_buf,
            media_type=media_types[format_upper],
            headers={
                "Content-Disposition": f"attachment; filename=compressed.{ext}",
                "X-Original-Size": str(original_size),
                "X-Compressed-Size": str(compressed_size),
                "X-Compression-Ratio": f"{(1 - compressed_size / original_size) * 100:.1f}%",
                "X-Image-Width": str(input_image.width),
                "X-Image-Height": str(input_image.height),
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error compressing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error compressing image: {str(e)}")


# --- Resize ---

@app.post("/api/resize")
async def resize_image(
    file: UploadFile = File(...),
    width: int | None = Query(default=None, ge=1, le=MAX_RESOLUTION, description="Target width"),
    height: int | None = Query(default=None, ge=1, le=MAX_RESOLUTION, description="Target height"),
    keep_ratio: bool = Query(default=True, description="Maintain aspect ratio"),
):
    if width is None and height is None:
        raise HTTPException(status_code=400, detail="At least one of width or height is required")

    input_image = await read_and_validate_image(file)

    try:
        original_width, original_height = input_image.size

        if keep_ratio:
            if width and height:
                # Fit within box while maintaining ratio
                ratio = min(width / original_width, height / original_height)
                new_width = round(original_width * ratio)
                new_height = round(original_height * ratio)
            elif width:
                ratio = width / original_width
                new_width = width
                new_height = round(original_height * ratio)
            else:
                ratio = height / original_height
                new_width = round(original_width * ratio)
                new_height = height
        else:
            new_width = width or original_width
            new_height = height or original_height

        output_image = input_image.resize(
            (new_width, new_height),
            Image.Resampling.LANCZOS,
        )

        # Determine output format based on input
        out_format = "PNG" if input_image.mode == "RGBA" else "PNG"
        output_buf = io.BytesIO()
        output_image.save(output_buf, format=out_format)
        output_size = output_buf.tell()
        output_buf.seek(0)

        return StreamingResponse(
            output_buf,
            media_type="image/png",
            headers={
                "Content-Disposition": "attachment; filename=resized.png",
                "X-Original-Width": str(original_width),
                "X-Original-Height": str(original_height),
                "X-New-Width": str(new_width),
                "X-New-Height": str(new_height),
                "X-Output-Size": str(output_size),
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resizing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error resizing image: {str(e)}")


# --- Remove Object (Inpainting) ---

@app.post("/api/remove-object")
async def remove_object(
    image: UploadFile = File(...),
    mask: UploadFile = File(...),
):
    input_image = await read_and_validate_image(image)

    # Validate mask
    try:
        mask_contents = await mask.read()
        mask_image = Image.open(io.BytesIO(mask_contents)).convert("L")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid mask image")

    # Ensure mask matches image dimensions
    if mask_image.size != input_image.size:
        mask_image = mask_image.resize(input_image.size, Image.Resampling.LANCZOS)

    try:
        from inpainters.lama_inpainter import LamaInpainter

        inpainter = LamaInpainter()
        if not inpainter.is_loaded():
            inpainter.load_model()

        output_image = inpainter.inpaint(input_image, mask_image)

        return image_to_streaming_response(
            output_image,
            format="PNG",
            filename="object_removed.png",
        )
    except ImportError:
        raise HTTPException(
            status_code=501,
            detail="Object removal is not available. Install iopaint to enable this feature."
        )
    except Exception as e:
        logger.error(f"Error removing object: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error removing object: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
