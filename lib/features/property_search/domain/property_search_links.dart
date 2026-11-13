/// Destinations for Property Search: the buyer website, the MangoLiving app,
/// and the store listing used when that app is not installed.
abstract final class PropertySearchLinks {
  static const String appScheme = 'mangoliving://search';
  static const String appStore =
      'https://apps.apple.com/us/app/mangoliving/id6799199646';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.mangoliving.mangoliving';

  static Uri web(String origin) {
    final String trimmed = origin.trim();
    final String base = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return Uri.parse('$base/search');
  }

  static Uri get app => Uri.parse(appScheme);

  static Uri storeFor({required bool android}) {
    return Uri.parse(android ? playStore : appStore);
  }
}
