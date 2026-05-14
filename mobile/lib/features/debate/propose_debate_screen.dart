import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../shared/widgets/loading_indicator.dart';

class ProposeDebateScreen extends ConsumerStatefulWidget {
  const ProposeDebateScreen({super.key});

  @override
  ConsumerState<ProposeDebateScreen> createState() =>
      _ProposeDebateScreenState();
}

class _ProposeDebateScreenState
    extends ConsumerState<ProposeDebateScreen> {
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
          const SnackBar(
              content:
                  Text('Debate enviado para revisión')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proponer debate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título del debate',
                  helperText: '60–120 caracteres',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _contextCtrl,
                maxLines: 6,
                maxLength: 2000,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Contexto / descripción',
                  helperText: 'Mínimo 80 palabras',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'URL de la fuente (opcional)',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
              ),
              const SizedBox(height: 32),
              if (_loading)
                const LoadingIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Enviar propuesta',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
