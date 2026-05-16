import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/debate.dart';
import '../theme/app_theme.dart';

class TickerWidget extends StatefulWidget {
  final List<Debate> debates;

  const TickerWidget({super.key, required this.debates});

  @override
  State<TickerWidget> createState() => _TickerWidgetState();
}

class _TickerWidgetState extends State<TickerWidget> {
  final _ctrl = ScrollController();
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _alive = false;
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    // pequeña pausa para que el layout se estabilice
    await Future.delayed(const Duration(milliseconds: 600));
    while (_alive && mounted && _ctrl.hasClients) {
      final pos = _ctrl.position;
      final max = pos.maxScrollExtent;
      if (max <= 0) break;

      // el contenido está duplicado; media vuelta = una iteración completa
      final half = (max + pos.viewportDimension) / 2;
      final ms = (half / 55 * 1000).toInt(); // ~55 px/s, legible

      await _ctrl.animateTo(
        half,
        duration: Duration(milliseconds: ms),
        curve: Curves.linear,
      );

      if (!_alive || !mounted || !_ctrl.hasClients) break;
      _ctrl.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debates.isEmpty) return const SizedBox.shrink();

    // duplicar para loop seamless
    final doubled = [...widget.debates, ...widget.debates];

    return Container(
      height: 34,
      color: TddColors.text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // etiqueta fija "HOT"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: TddColors.accent,
            alignment: Alignment.center,
            child: Text(
              'HOT',
              style: TddTypography.mono(
                size: 8.5,
                letterSpacing: 0.25,
                color: TddColors.accentInk,
              ),
            ),
          ),
          // contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: doubled.expand<Widget>((d) {
                  return [
                    const SizedBox(width: 28),
                    GestureDetector(
                      onTap: () => context.push('/home/debate/${d.id}'),
                      child: Row(
                        children: [
                          Text(
                            d.title,
                            style: TddTypography.mono(
                              size: 10.5,
                              color: TddColors.accentInk,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${d.commentCount ?? 0} comentarios',
                            style: TddTypography.mono(
                              size: 9.5,
                              color: TddColors.text3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: TddColors.text2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ];
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
