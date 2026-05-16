class ApiEndpoints {
  static const String baseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: 'http://10.0.2.2:3000');
  static const String wsUrl =
      String.fromEnvironment('WS_URL', defaultValue: 'ws://10.0.2.2:8080');

  // Auth
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // Debates
  static const String debatesToday = '/api/v1/debates/today';
  static const String debatesTrending = '/api/v1/debates/trending';
  static const String debatesSearch = '/api/v1/debates/search';
  static const String debatesTicker = '/api/v1/debates/ticker';
  static const String debatesTopToday = '/api/v1/debates/top-today';
  static const String debatesTopWeek = '/api/v1/debates/top-week';
  static const String debatesRecent = '/api/v1/debates/recent';
  static const String debates = '/api/v1/debates';
  static String debateById(int id) => '/api/v1/debates/$id';
  static String debatePositions(int id) => '/api/v1/debates/$id/positions';
  static String debateComments(int id) => '/api/v1/debates/$id/comments';
  static String commentVote(int id) => '/api/v1/comments/$id/vote';
  static String debateReport(int id) => '/api/v1/debates/$id/report';
  static String commentReport(int id) => '/api/v1/comments/$id/report';

  // Users
  static String userByUsername(String username) => '/api/v1/users/$username';
  static const String me = '/api/v1/users/me';
  static const String myFavorites = '/api/v1/users/me/favorites';
  static const String usersProtagonistas = '/api/v1/users/protagonistas';

  // Social
  static const String friends = '/api/v1/friends';
  static String friendById(int userId) => '/api/v1/friends/$userId';
  static String friendAccept(int userId) => '/api/v1/friends/$userId/accept';
  static String favoriteDebate(int debateId) =>
      '/api/v1/favorites/$debateId';

  // Chat
  static const String conversations = '/api/v1/chat/conversations';
  static String conversationMessages(int id) =>
      '/api/v1/chat/conversations/$id/messages';

  // Personas
  static const String personas = '/api/v1/personas';
  static String personaDebates(String username) =>
      '/api/v1/personas/$username/debates';

  // Notifications
  static const String notifications = '/api/v1/notifications';
  static String notificationRead(int id) => '/api/v1/notifications/$id/read';
  static const String notificationsReadAll = '/api/v1/notifications/read-all';
}
