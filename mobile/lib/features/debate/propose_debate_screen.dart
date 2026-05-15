import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_indicator.dart';

class ProposeDebateScreen extends ConsumerStatefulWidget {
  const ProposeDebateScreen({super.key});

  @override
  ConsumerState<ProposeDebateScreen> createState() =>
      _ProposeDebateScreenState();
}

class _ProposeDebateScreenState extends ConsumerState<ProposeDebateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contextCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  int _wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.debates, data: {
        'title': _titleCtrl.text.trim(),
        'context': _contextCtrl.text.trim(),
        if (_sourceCtrl.text.trim().isNotEmpty)
          'source_url': _sourceCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debate enviado para revisión')),
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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title: Text(
          'Proponer debate',
          style: TddTypography.serif(size: 17, weight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Sobre qué quieres debatir?',
                style:
                    TddTypography.serif(size: 22, weight: FontWeight.w500,
                        letterSpacing: -0.015),
              ),
              const SizedBox(height: 4),
              Text(
                'Un debate bien planteado genera mejor conversación.',
                style: TddTypography.sans(
                    size: 13,
                    color: TddColors.text3,
                    style: FontStyle.italic),
              ),
              const SizedBox(height: 32),
              // Title field
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _titleCtrl,
                builder: (_, value, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      style: TddTypography.serif(size: 16, weight: FontWeight.w400),
                      decoration: InputDecoration(
                        labelText: 'TÍTULO',
                        counterText: '',
                        hintText: 'Enuncia el debate como una pregunta o tesis',
                        hintStyle: TddTypography.sans(
                            size: 14, color: TddColors.text4,
                            style: FontStyle.italic),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        if (v.trim().length < 60) {
                          return 'Mínimo 60 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${value.text.length} / 120',
                      style: TddTypography.mono(size: 9.5, color: TddColors.text4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Context field
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contextCtrl,
                builder: (_, value, __) {
                  final words = _wordCount(value.text);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _contextCtrl,
                        maxLines: 8,
                        maxLength: 2000,
                        textInputAction: TextInputAction.next,
                        style: TddTypography.sans(size: 14, height: 1.6),
                        decoration: InputDecoration(
                          labelText: 'CONTEXTO',
                          counterText: '',
                          hintText: 'Añade contexto, datos o antecedentes…',
                          hintStyle: TddTypography.sans(
                              size: 14, color: TddColors.text4,
                              style: FontStyle.italic),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El contexto es requerido';
                          }
                          if (_wordCount(v) < 80) {
                            return 'Mínimo 80 palabras (tienes ${_wordCount(v)})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$words palabras',
                        style: TddTypography.mono(
                          size: 9.5,
                          color: words >= 80
                              ? TddColors.favor
                              : TddColors.text4,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _sourceCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: TddTypography.sans(size: 14),
                decoration: const InputDecoration(
                  labelText: 'FUENTE (OPCIONAL)',
                ),
              ),
              const SizedBox(height: 36),
              if (_loading)
                const LoadingIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Enviar propuesta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
