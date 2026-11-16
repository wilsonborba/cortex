import 'package:flutter/material.dart';
import '../../../../dal/local/inspection_demo.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';
import '../chat/answer_inspection.dart';

/// The real answer inspection in the landing hero (cortex#81), with a
/// static recorded sample in the site language. It never calls a model or
/// the Cortex API, and it has no continue action.
class LandingInspectionDemo extends StatefulWidget {
  const LandingInspectionDemo({super.key, this.source});
  final InspectionDemoSource? source;
  @override
  State<LandingInspectionDemo> createState() => _LandingInspectionDemoState();
}

class _LandingInspectionDemoState extends State<LandingInspectionDemo> {
  AnswerInspectionController? _controller;
  String? _language;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = InspectionDemoSource.language(
      Localizations.localeOf(context).languageCode,
    );
    if (language != _language) {
      _language = language;
      final hit = InspectionDemoSource.cached(language);
      if (hit != null) {
        _controller?.dispose();
        _controller = AnswerInspectionController(
          text: hit.$1,
          initialData: hit.$2,
        );
      } else {
        _load(language);
      }
    }
  }

  Future<void> _load(String language) async {
    final (text, data) = await (widget.source ?? const InspectionDemoSource())
        .load(language);
    if (!mounted || language != _language) return;
    final old = _controller;
    setState(() {
      _controller = AnswerInspectionController(text: text, initialData: data);
    });
    old?.dispose();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _reset() {
    final c = _controller;
    if (c == null) return;
    c.closeRadar(unpin: true);
    c.moveTo(c.spans.length - 1, pin: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final c = _controller;
    return AppCard(
      key: const Key('landing-inspection'),
      radius: Radii.dialog,
      padding: const EdgeInsets.all(Space.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.heroDemoLabel,
            style: TextStyles.caption1Strong.copyWith(color: p.muted),
          ),
          const SizedBox(height: Space.s12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s12,
                vertical: Space.s8,
              ),
              decoration: BoxDecoration(
                color: p.selected,
                borderRadius: BorderRadius.circular(Radii.large),
              ),
              child: Text(
                l.heroDemoQuestion,
                style: TextStyles.body1.copyWith(color: p.text),
              ),
            ),
          ),
          const SizedBox(height: Space.s16),
          if (c == null)
            const SizedBox(height: 160)
          else
            InspectionAnswer(
              key: ValueKey(_language),
              controller: c,
              onExit: _reset,
            ),
        ],
      ),
    );
  }
}
