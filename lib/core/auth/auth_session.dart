/// When true, [main] skips automatic redirect to `/login` on sign-out.
/// Set this before [SupabaseClient.auth.signOut] when the caller navigates
/// to login with custom [RouteSettings.arguments].
bool suppressSignedOutRoute = false;
