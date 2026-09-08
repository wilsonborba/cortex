/// Whether the current visitor may enter the chat screen, and why.
enum SessionStatus {
  /// A real Asodya session was established through the `auth_apps` SSO
  /// exchange (an `sid` cookie is set on `api_for_apps`).
  authenticated,

  /// No authenticated session: the landing page should be shown.
  none,
}

extension SessionStatusX on SessionStatus {
  bool get canEnterChat => this == SessionStatus.authenticated;
}
