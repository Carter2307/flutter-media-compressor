abstract final class AppConstants {
  static const String appName = 'Image Utility';

  // Image compression
  static const int maxImageBatchSize = 10;
  static const int defaultImageQuality = 80;
  static const int maxImageResolution = 4000;

  // Video compression
  static const int maxVideoDurationMinutes = 30;

  // PDF compression
  static const int maxPdfSizeMb = 100;

  // Supported formats
  static const imageInputFormats = ['jpeg', 'jpg', 'png', 'webp', 'heic'];
  static const imageOutputFormats = ['jpeg', 'png', 'webp'];
  static const videoInputFormats = ['mp4', 'mov', 'avi', 'mkv'];
}
