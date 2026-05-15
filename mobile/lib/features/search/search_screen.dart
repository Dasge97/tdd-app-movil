import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../shared/theme/app_theme.dart';
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
      final resp = await dio.get(ApiEndpoints.debatesSearch,
          queryParameters: {'q': q, 'page': 1});
      final List raw = resp.data is List
          ? resp.data as List
          : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
      setState(() {
        _results =
            raw.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
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
        leading: BackButton(color: TddColors.text2),
        title: TextField(
          controller: _ctrl,
          onChanged: _onChanged,
          autofocus: true,
          style: TddTypography.sans(size: 16, style: FontStyle.italic),
          decoration: InputDecoration(
            hintText: 'Buscar debates…',
            hintStyle: TddTypography.sans(
                size: 16, color: TddColors.text4, style: FontStyle.italic),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _search(_query))
              : _query.isEmpty
                  ? Center(
                      child: Text(
                        'Escribe para buscar.',
                        style:
                            TddTypography.sans(size: 14, color: TddColors.text4),
                      ),
                    )
                  : _results.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Center(),
                            Text(
                              'Sin resultados para\n"$_query"',
                              textAlign: TextAlign.center,
                              style: TddTypography.sans(
                                  size: 14, color: TddColors.text3),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                              child: Text(
                                '${_results.length} resultado${_results.length == 1 ? '' : 's'}',
                                style: TddTypography.mono(
                                    size: 10, color: TddColors.text3),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _results.length,
                                itemBuilder: (_, i) =>
                                    DebateCard(debate: _results[i]),
                              ),
                            ),
                          ],
                        ),
    );
  }
}
