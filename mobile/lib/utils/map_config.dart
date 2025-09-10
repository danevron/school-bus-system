import 'dart:io';

/// Configuration for different map tile providers based on platform and preferences
class MapTileConfig {
  /// Available tile providers
  static const String _cartoPositron = 'carto_positron';
  static const String _cartoVoyager = 'carto_voyager';
  static const String _esriStreets = 'esri_streets';
  static const String _openStreetMap = 'openstreetmap';

  /// Get the recommended tile URL template based on platform
  static String getTileUrlTemplate() {
    if (Platform.isIOS) {
      // Use CartoDB Voyager for iOS (clean, Apple-like styling)
      return getCartoVoyagerUrl();
    } else {
      // Use OpenStreetMap for Android
      return getOpenStreetMapUrl();
    }
  }

  /// Get subdomains for load balancing
  static List<String> getSubdomains() {
    if (Platform.isIOS) {
      return ['a', 'b', 'c', 'd']; // CartoDB uses 4 subdomains
    } else {
      return ['a', 'b', 'c']; // OpenStreetMap uses 3 subdomains
    }
  }

  /// Get additional tile layer options
  static Map<String, String> getAdditionalOptions() {
    if (Platform.isIOS) {
      return {
        'attribution': '© CARTO © OpenStreetMap contributors',
      };
    } else {
      return {
        'attribution': '© OpenStreetMap contributors',
      };
    }
  }

  // Individual tile provider configurations

  /// CartoDB Positron - Clean, minimal style (great for iOS)
  static String getCartoPositronUrl() {
    return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  }

  /// CartoDB Voyager - Balanced style with more detail
  static String getCartoVoyagerUrl() {
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  /// CartoDB Dark Matter - Dark theme
  static String getCartoDarkUrl() {
    return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  }

  /// Esri World Street Map - Professional appearance
  static String getEsriStreetsUrl() {
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  }

  /// Esri World Topographic Map
  static String getEsriTopoUrl() {
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
  }

  /// Esri World Imagery (Satellite)
  static String getEsriImageryUrl() {
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  }

  /// OpenStreetMap - Standard open-source tiles
  static String getOpenStreetMapUrl() {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Get configuration for a specific provider
  static MapTileConfiguration getConfiguration(String provider) {
    switch (provider) {
      case _cartoPositron:
        return MapTileConfiguration(
          urlTemplate: getCartoPositronUrl(),
          subdomains: ['a', 'b', 'c', 'd'],
          attribution: '© CARTO © OpenStreetMap contributors',
          maxZoom: 19,
        );
      case _cartoVoyager:
        return MapTileConfiguration(
          urlTemplate: getCartoVoyagerUrl(),
          subdomains: ['a', 'b', 'c', 'd'],
          attribution: '© CARTO © OpenStreetMap contributors',
          maxZoom: 19,
        );
      case _esriStreets:
        return MapTileConfiguration(
          urlTemplate: getEsriStreetsUrl(),
          subdomains: [],
          attribution: '© Esri © OpenStreetMap contributors',
          maxZoom: 19,
        );
      case _openStreetMap:
      default:
        return MapTileConfiguration(
          urlTemplate: getOpenStreetMapUrl(),
          subdomains: ['a', 'b', 'c'],
          attribution: '© OpenStreetMap contributors',
          maxZoom: 19,
        );
    }
  }

  /// Get the recommended provider for current platform
  static String getRecommendedProvider() {
    return Platform.isIOS ? _cartoPositron : _openStreetMap;
  }
}

/// Configuration data class for tile providers
class MapTileConfiguration {
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;
  final int maxZoom;

  const MapTileConfiguration({
    required this.urlTemplate,
    required this.subdomains,
    required this.attribution,
    required this.maxZoom,
  });
}