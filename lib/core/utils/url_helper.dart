import 'package:servino_provider/core/api/end_point.dart';

class UrlHelper {
  static String getAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Already absolute HTTP/HTTPS
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Handle file scheme without host (common issue observed)
    // If it's literally "file:///uploads/...", we want to extract "/uploads/..."
    if (url.startsWith('file:///')) {
      // Remove 'file://' to get '/uploads/...' or 'uploads/...'
      String path = url.replaceFirst('file://', '');
      return _buildUrl(path);
    }

    // Handle file scheme with just two slashes if that happens
    if (url.startsWith('file://')) {
      String path = url.replaceFirst('file://', '');
      return _buildUrl(path);
    }

    // Relative path
    return _buildUrl(url);
  }

  static String _buildUrl(String path) {
    String cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return '${EndPoint.imageBaseUrl}$cleanPath';
  }
}
