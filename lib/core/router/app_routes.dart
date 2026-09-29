/// Named route path constants.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  static const String overview = '/overview';
  static const String clients = '/clients';
  static const String messages = '/messages';

  static String messageThread(String agentClientId) =>
      '/messages/${Uri.encodeComponent(agentClientId)}';
  static const String showings = '/showings';
  static const String more = '/more';

  static const String offers = '/offers';

  static String offerPrepare(String id) =>
      '/offers/${Uri.encodeComponent(id)}/prepare';

  static String offerSummary(String id) =>
      '/offers/${Uri.encodeComponent(id)}/summary';
  static const String analytics = '/analytics';
  static const String account = '/account';
  static const String changePassword = '/change-password';
}
