abstract final class ApiEndpoints {
  // Local FastAPI server
  static const String baseUrl = 'http://localhost:8000';

  // Background removal
  static const String removeBackground = '/api/remove-background';

  // Image compression
  static const String compress = '/api/compress';

  // Image resize
  static const String resize = '/api/resize';

  // Upscale
  static const String upscale = '/api/upscale';

  // PDF compression
  static const String compressPdf = '/api/compress-pdf';

  // PDF preview
  static const String pdfPreview = '/api/pdf-preview';

  // Health
  static const String health = '/health';
}
