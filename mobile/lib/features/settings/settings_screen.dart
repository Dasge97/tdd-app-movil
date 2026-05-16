import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/app_links.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification toggles (local state; persist with SharedPreferences if needed)
  bool _notifComments = true;
  bool _notifFriends = true;
  bool _notifMentions = true;
  bool _notifDebates = false;

  // Privacy
  bool _publicProfile = true;

  // ── Open URL ────────────────────────────────────────────────────────────────

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $url')),
        );
      }
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri(scheme: 'mailto', path: AppLinks.supportEmail,
        queryParameters: {'subject': 'Soporte TDD'});
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppLinks.supportEmail)),
        );
      }
    }
  }

  void _showChangelog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Novedades en v1.0.0',
          style: TddTypography.serif(size: 18, weight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _changelogItem('🎉 Lanzamiento', 'Primera versión pública de TuDebateDiario.'),
              _changelogItem('🤖 Ocho personajes IA', 'Cada mañana, ocho voces editoriales analizan la actualidad española.'),
              _changelogItem('💬 Debates y comentarios', 'Posiciónate (a favor / neutral / en contra) y argumenta con la comunidad.'),
              _changelogItem('🏆 Protagonistas', 'Ranking semanal de los usuarios con mayor puntuación de fiabilidad.'),
              _changelogItem('🔍 Buscador', 'Encuentra debates por tema o palabra clave.'),
              _changelogItem('🔔 Notificaciones', 'Recibe avisos de respuestas, menciones y solicitudes de amistad.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar',
                style: TddTypography.mono(size: 11, color: TddColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _changelogItem(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TddTypography.sans(size: 13, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(desc, style: TddTypography.sans(size: 13, color: TddColors.text2, height: 1.5)),
          ],
        ),
      );

  void _showAiDisclaimer() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Contenido generado por IA',
          style: TddTypography.serif(size: 18, weight: FontWeight.w500),
        ),
        content: Text(
          'Los perfiles y debates marcados con IA son generados automáticamente. '
          'Su contenido puede contener errores, imprecisiones o puntos de vista '
          'no representativos. Consulta siempre fuentes adicionales antes de '
          'tomar decisiones basadas en este contenido.',
          style: TddTypography.sans(size: 14, height: 1.6, color: TddColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Entendido',
                style: TddTypography.mono(size: 11, color: TddColors.accent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(AppLinks.aiInfo);
            },
            child: Text('Saber más',
                style: TddTypography.mono(size: 11, color: TddColors.text3)),
          ),
        ],
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cerrar sesión',
          style: TddTypography.serif(size: 19, weight: FontWeight.w500),
        ),
        content: Text(
          '¿Seguro que quieres cerrar sesión?',
          style: TddTypography.sans(size: 14, color: TddColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TddTypography.mono(size: 11, color: TddColors.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar sesión',
                style: TddTypography.mono(size: 11, color: TddColors.contra)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  // ── Change password ──────────────────────────────────────────────────────────

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TddColors.bgElev,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: TddColors.border, width: 0.5),
      ),
      builder: (ctx) => _ChangePasswordSheet(
        onSaved: () => Navigator.pop(ctx),
      ),
    );
  }

  // ── Delete account ───────────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Eliminar cuenta',
          style: TddTypography.serif(size: 19, weight: FontWeight.w500),
        ),
        content: Text(
          'Esta acción es irreversible. Se borrarán todos tus datos, comentarios y propuestas.',
          style: TddTypography.sans(size: 14, color: TddColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TddTypography.mono(size: 11, color: TddColors.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar mi cuenta',
                style: TddTypography.mono(size: 11, color: TddColors.contra)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete('/api/v1/users/me');
      await ref.read(authProvider.notifier).logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title: Text(
          'Ajustes',
          style: TddTypography.serif(size: 17, weight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── CUENTA ────────────────────────────────────────────────────────
          _sectionHeader('CUENTA'),
          if (user != null)
            _infoRow(
              label: 'Usuario',
              value: '@${user.username}',
            ),
          _actionRow(
            label: 'Cambiar contraseña',
            onTap: _showChangePassword,
          ),
          _actionRow(
            label: 'Cerrar sesión',
            labelColor: TddColors.contra,
            onTap: _logout,
          ),

          // ── NOTIFICACIONES ────────────────────────────────────────────────
          _sectionHeader('NOTIFICACIONES'),
          _toggleRow(
            label: 'Comentarios y respuestas',
            value: _notifComments,
            onChanged: (v) => setState(() => _notifComments = v),
          ),
          _toggleRow(
            label: 'Solicitudes de amistad',
            value: _notifFriends,
            onChanged: (v) => setState(() => _notifFriends = v),
          ),
          _toggleRow(
            label: 'Menciones',
            value: _notifMentions,
            onChanged: (v) => setState(() => _notifMentions = v),
          ),
          _toggleRow(
            label: 'Debates nuevos',
            value: _notifDebates,
            onChanged: (v) => setState(() => _notifDebates = v),
          ),

          // ── PRIVACIDAD ────────────────────────────────────────────────────
          _sectionHeader('PRIVACIDAD'),
          _toggleRow(
            label: 'Perfil público',
            subtitle: 'Cualquier persona puede ver tu perfil y comentarios',
            value: _publicProfile,
            onChanged: (v) => setState(() => _publicProfile = v),
          ),

          // ── SOPORTE ───────────────────────────────────────────────────────
          _sectionHeader('SOPORTE'),
          _actionRow(
            label: 'Centro de ayuda',
            onTap: () => _openUrl(AppLinks.supportWeb),
          ),
          _actionRow(
            label: 'Contactar por email',
            subtitle: AppLinks.supportEmail,
            onTap: _openEmail,
          ),

          // ── INFORMACIÓN ───────────────────────────────────────────────────
          _sectionHeader('INFORMACIÓN'),
          _infoRow(label: 'Versión', value: '1.0.0'),
          _actionRow(
            label: 'Novedades en esta versión',
            onTap: _showChangelog,
          ),
          _actionRow(
            label: 'Aviso sobre contenido IA',
            onTap: _showAiDisclaimer,
          ),
          _actionRow(
            label: 'Términos de uso',
            onTap: () => _openUrl(AppLinks.terms),
          ),
          _actionRow(
            label: 'Política de privacidad',
            onTap: () => _openUrl(AppLinks.privacy),
          ),

          // ── ZONA DE PELIGRO ───────────────────────────────────────────────
          _sectionHeader('ZONA DE PELIGRO'),
          _actionRow(
            label: 'Eliminar cuenta',
            labelColor: TddColors.contra,
            onTap: _deleteAccount,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
        child: Text(
          title,
          style: TddTypography.mono(size: 9.5, color: TddColors.text3),
        ),
      );

  Widget _infoRow({required String label, required String value}) => Container(
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(label, style: TddTypography.sans(size: 14)),
            const Spacer(),
            Text(value,
                style: TddTypography.mono(size: 11, color: TddColors.text3)),
          ],
        ),
      );

  Widget _actionRow({
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    String? subtitle,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: TddColors.border, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TddTypography.sans(
                            size: 14,
                            color: labelColor ?? TddColors.text)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TddTypography.mono(
                              size: 10, color: TddColors.text3)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: TddColors.text4),
            ],
          ),
        ),
      );

  Widget _toggleRow({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TddTypography.sans(size: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TddTypography.sans(
                            size: 12, color: TddColors.text3)),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: TddColors.accent,
              activeTrackColor: TddColors.accentSoft,
              inactiveThumbColor: TddColors.text3,
              inactiveTrackColor: TddColors.surface2,
            ),
          ],
        ),
      );
}

// ── Change password sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _ChangePasswordSheet({required this.onSaved});

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.patch('/api/v1/auth/change-password', data: {
        'currentPassword': _currentCtrl.text,
        'newPassword': _newCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cambiar contraseña',
                style: TddTypography.serif(size: 19, weight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                style: TddTypography.sans(size: 14),
                decoration: InputDecoration(
                  labelText: 'CONTRASEÑA ACTUAL',
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    child: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: TddColors.text3,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                style: TddTypography.sans(size: 14),
                decoration: InputDecoration(
                  labelText: 'NUEVA CONTRASEÑA',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscureNew = !_obscureNew),
                    child: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: TddColors.text3,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                style: TddTypography.sans(size: 14),
                decoration: const InputDecoration(
                  labelText: 'CONFIRMAR CONTRASEÑA',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (v != _newCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: TddColors.accent,
                        strokeWidth: 1.5,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Guardar contraseña'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
