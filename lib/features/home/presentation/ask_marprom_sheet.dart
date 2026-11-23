// Interactive Ask Marprom bottom sheet with voice input, TTS, and sample prompts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/accessibility/a11y_settings.dart';
import '../../../core/accessibility/favorites_provider.dart';
import '../../../core/accessibility/read_aloud.dart';
import '../../../core/accessibility/semantics_helpers.dart';
import '../../../core/accessibility/voice_input.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/simulated_data_badge.dart';
import '../domain/ask_marprom.dart';

/// Opens the modal [AskMarpromSheet], optionally submitting [initialQuery] immediately.
Future<void> showAskMarpromSheet(
  BuildContext context, {
  String? initialQuery,
  LatLng? userPosition,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => AskMarpromSheet(
      initialQuery: initialQuery,
      userPosition: userPosition ?? GeoUtils.mariborCenter,
    ),
  );
}

/// Interactive Q&A sheet powered by [AskMarpromAssistant] with optional voice input.
class AskMarpromSheet extends ConsumerStatefulWidget {
  /// Creates an [AskMarpromSheet] for natural-language Marprom transit queries.
  const AskMarpromSheet({
    super.key,
    this.initialQuery,
    this.userPosition = GeoUtils.mariborCenter,
  });

  /// Optional prompt submitted automatically once the sheet mounts.
  final String? initialQuery;

  /// Current or manual rider position for nearest-stop queries.
  final LatLng userPosition;

  @override
  ConsumerState<AskMarpromSheet> createState() => _AskMarpromSheetState();
}

class _AskMarpromSheetState extends ConsumerState<AskMarpromSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatTurn> _turns = [];
  VoiceInputService? _voiceInput;
  bool _isSubmitting = false;
  bool _isListening = false;
  bool _ranInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceInput ??= ref.read(voiceInputProvider);
    if (!_ranInitial && widget.initialQuery != null) {
      _ranInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _submitQuery(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _voiceInput?.stop();
    super.dispose();
  }

  Future<void> _submitQuery(String rawText) async {
    final query = rawText.trim();
    if (query.isEmpty || _isSubmitting) return;

    final l10n = context.l10n;
    final settings = ref.read(a11ySettingsProvider);
    final favorites = ref.read(favoritesProvider);
    final isOffline = ref.read(isOfflineProvider);
    final assistant = ref.read(askMarpromProvider);

    _controller.clear();
    setState(() {
      _isSubmitting = true;
      _turns.add(_ChatTurn.user(query));
    });

    final reply = await assistant.ask(
      query,
      l10n: l10n,
      localeCode: settings.localeCode,
      userPosition: widget.userPosition,
      preferredStopId: favorites.manualStopId,
      useSimulatedLive: settings.useSimulatedLive,
      isOffline: isOffline,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _turns.add(_ChatTurn.assistant(reply));
    });

    if (settings.readAloudEnabled) {
      await ref.read(readAloudProvider).speak(
            reply.text,
            enabled: true,
            localeCode: settings.localeCode,
          );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _toggleVoice() async {
    final voice = ref.read(voiceInputProvider);
    final settings = ref.read(a11ySettingsProvider);
    if (_isListening) {
      await voice.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    final started = await voice.startListening(
      localeCode: settings.localeCode,
      onResult: (words, isFinal) {
        if (!mounted) return;
        _controller.text = words;
        if (isFinal) {
          setState(() => _isListening = false);
          _submitQuery(words);
        }
      },
      onStatus: (status) {
        if (mounted && !voice.isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!started && mounted) {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(a11ySettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final samples = [
      l10n.askSample1,
      l10n.askSample2,
      l10n.askSample3,
      l10n.askSample4,
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.askTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        l10n.askDisclaimer,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (_turns.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: l10n.askClearChat,
                    constraints:
                        const BoxConstraints(minWidth: 56, minHeight: 56),
                    onPressed: () => setState(() => _turns.clear()),
                  ),
                Semantics(
                  button: true,
                  label: l10n.a11yCloseButton,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.commonClose,
                    constraints:
                        const BoxConstraints(minWidth: 56, minHeight: 56),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sample in samples)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(sample),
                    onPressed: () => _submitQuery(sample),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _turns.isEmpty
                  ? SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          l10n.askSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: _turns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final turn = _turns[index];
                        if (turn.isUser) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                turn.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          );
                        }
                        final reply = turn.reply!;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            liveRegion: index == _turns.length - 1,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (reply.freshness != null) ...[
                                      SimulatedDataBadge(
                                        freshness: reply.freshness,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    Text(
                                      reply.text,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(56, 56),
                                          ),
                                          icon: const Icon(
                                            Icons.volume_up_rounded,
                                          ),
                                          label: Text(l10n.a11yReadAloudButton),
                                          onPressed: () {
                                            ref.read(readAloudProvider).speak(
                                                  reply.text,
                                                  enabled: true,
                                                  localeCode:
                                                      settings.localeCode,
                                                );
                                          },
                                        ),
                                        if (reply.suggestedRoute != null &&
                                            reply.actionLabel != null)
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(56, 56),
                                            ),
                                            icon: const Icon(
                                              Icons.arrow_forward_rounded,
                                            ),
                                            label: Text(reply.actionLabel!),
                                            onPressed: () {
                                              final route =
                                                  reply.suggestedRoute!;
                                              Navigator.of(context).pop();
                                              if (route == '/plan' ||
                                                  route == '/map' ||
                                                  route == '/tickets') {
                                                context.go(route);
                                              } else {
                                                context.push(route);
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    textField: true,
                    label: l10n.a11ySearchField,
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submitQuery,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? l10n.askVoicePrompt
                            : l10n.askInputHint,
                      ),
                    ),
                  ),
                ),
                if (settings.voiceInputEnabled) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: l10n.a11yVoiceSearchButton,
                    child: IconButton.filledTonal(
                      constraints:
                          const BoxConstraints(minWidth: 56, minHeight: 56),
                      tooltip: l10n.a11yVoiceSearchButton,
                      icon: Icon(
                        _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                      ),
                      onPressed: _toggleVoice,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: l10n.askSend,
                  child: IconButton.filled(
                    constraints:
                        const BoxConstraints(minWidth: 56, minHeight: 56),
                    tooltip: l10n.askSend,
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitQuery(_controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTurn {
  const _ChatTurn._({
    required this.isUser,
    required this.text,
    this.reply,
  });

  factory _ChatTurn.user(String text) => _ChatTurn._(isUser: true, text: text);

  factory _ChatTurn.assistant(AskMarpromReply reply) =>
      _ChatTurn._(isUser: false, text: reply.text, reply: reply);

  final bool isUser;
  final String text;
  final AskMarpromReply? reply;
}
