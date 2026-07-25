class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  int? userId;

  void clear() => userId = null;
}
