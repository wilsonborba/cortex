/// Whether the current visitor may enter the chat screen, and why.
enum SessionStatus {
  /// A real Asodya session was established through the `auth_apps` SSO
  /// exchange (an `sid` cookie is set on `api_for_apps`).
  authenticated,

  /// Client-side-only flag: the visitor pressed "Continue as Guest". There is
  /// no server session and no token, this is purely a local routing decision.
  /// The chat backend must accept unauthenticated requests for this to work
  /// (see the `api_for_apps` public `/cortex/v1/*` proxy, issue #3).
  guest,

  /// Neither of the above: the landing page should be shown.
  none,
}

extension SessionStatusX on SessionStatus {
  bool get canEnterChat =>
      this == SessionStatus.authenticated || this == SessionStatus.guest;
}
