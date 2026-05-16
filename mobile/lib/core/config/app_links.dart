/// URLs y datos de contacto de la app.
/// Cambia [_base] cuando el dominio esté listo; el resto se actualiza solo.
class AppLinks {
  AppLinks._();

  static const String _base = 'https://tudebatediario.com';

  // ── Legales ──────────────────────────────────────────────────────────────────
  static const String privacy = '$_base/legal/privacidad';
  static const String terms   = '$_base/legal/terminos';
  static const String aiInfo  = '$_base/legal/ia';

  // ── Soporte ──────────────────────────────────────────────────────────────────
  static const String supportWeb   = '$_base/soporte';
  static const String supportEmail = 'info@tudebatediario.com';

  // ── Tienda ───────────────────────────────────────────────────────────────────
  static const String appStoreUrl  = 'https://apps.apple.com/app/id000000000';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.tudebatediario.app';
}
