import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  bool _loading = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final dio = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final resp = await dio.post('/api/v1/users/me/avatar', data: formData);
      final newUrl = resp.data['avatarUrl'] as String?;
      if (newUrl != null && mounted) {
        final userResp = await dio.get('/api/v1/users/me');
        ref
            .read(authProvider.notifier)
            .refreshUser(userResp.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final resp = await dio.put('/api/v1/users/me', data: {
        'bio': _bioCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });
      if (mounted) {
        ref.read(authProvider.notifier).refreshUser(resp.data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        context.pop();
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
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title: Text(
          'Editar perfil',
          style: TddTypography.serif(size: 17, weight: FontWeight.w500),
        ),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: TddColors.accent,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'Guardar',
                        style: TddTypography.sans(
                          size: 14,
                          weight: FontWeight.w500,
                          color: TddColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _AvatarCircle(
                        avatarUrl: user?.avatarUrl,
                        username: user?.username ?? '',
                        uploading: _uploadingAvatar,
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: TddColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: TddColors.bg, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Cambiar foto',
                  style: TddTypography.sans(
                    size: 12,
                    color: TddColors.accent,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Bio
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _bioCtrl,
                builder: (_, value, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 5,
                      maxLength: 300,
                      style: TddTypography.sans(size: 14, height: 1.6),
                      decoration: InputDecoration(
                        labelText: 'BIO',
                        counterText: '',
                        hintText: 'Cuéntanos sobre ti…',
                        hintStyle: TddTypography.sans(
                            size: 14,
                            color: TddColors.text4,
                            style: FontStyle.italic),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${value.text.length} / 300',
                      style: TddTypography.mono(size: 9.5, color: TddColors.text4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Location
              TextFormField(
                controller: _locationCtrl,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                style: TddTypography.sans(size: 14),
                decoration: InputDecoration(
                  labelText: 'UBICACIÓN',
                  suffix: const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: TddColors.text3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool uploading;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.username,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    const size = 84.0;
    const radius = BorderRadius.all(Radius.circular(size / 2));

    Widget content;
    if (uploading) {
      content = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: avatarUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, _) => _initials(username, size),
        errorWidget: (_, _, _) => _initials(username, size),
      );
    } else {
      content = _initials(username, size);
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  static Widget _initials(String username, double size) {
    return Container(
      width: size,
      height: size,
      color: TddColors.surface2,
      alignment: Alignment.center,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TddTypography.sans(
          size: size * 0.4,
          weight: FontWeight.w600,
          color: TddColors.text2,
        ),
      ),
    );
  }
}
