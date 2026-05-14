import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/debate_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Debate> _results = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim() != _query) {
        _query = value.trim();
        if (_query.isNotEmpty) _search(_query);
      }
    });
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final resp = await dio.get(
        ApiEndpoints.debatesSearch,
        queryParameters: {'q': q, 'page': 1},
      );
      final List raw = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
      final list = raw.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar debates...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: () => _search(_query),
                )
              : _results.isEmpty && _query.isNotEmpty
                  ? const Center(
                      child: Text('Sin resultados'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) =>
                          DebateCard(debate: _results[i]),
                    ),
    );
  }
}
