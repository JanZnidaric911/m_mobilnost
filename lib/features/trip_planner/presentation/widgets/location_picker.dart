// Searchable stop & Maribor place picker field and sheet with optional voice input.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m_mobilnost/core/accessibility/a11y_settings.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/accessibility/voice_input.dart';
import 'package:m_mobilnost/core/widgets/big_button.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/models/place.dart';
import 'package:m_mobilnost/data/repositories/repository_providers.dart';

import 'trip_endpoint.dart';

/// Accessible >= 56dp selector field displaying a chosen [TripEndpoint] and
/// optional microphone button when voice input is enabled.
class LocationPickerField extends ConsumerWidget {
  /// Creates a [LocationPickerField] for origin or destination selection.
  const LocationPickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.leadingIcon,
    required this.value,
    required this.onTap,
    this.onVoiceSelected,
    this.onClear,
  });

  /// Field caption (e.g. Origin or Destination).
  final String label;

  /// Placeholder text shown when [value] is null.
  final String placeholder;

  /// Leading semantic icon.
  final IconData leadingIcon;

  /// Currently selected endpoint, if any.
  final TripEndpoint? value;

  /// Opens the stop & place search sheet.
  final VoidCallback onTap;

  /// Optional callback invoked after voice input captures a query or endpoint.
  final ValueChanged<String>? onVoiceSelected;

  /// Optional callback to clear the selected endpoint.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(a11ySettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final displayText = value?.displayLabel(l10n) ?? placeholder;
    final hasValue = value != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '$label: $displayText',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasValue ? scheme.primary : scheme.outline,
                      width: hasValue ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        leadingIcon,
                        color: hasValue
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: hasValue
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: hasValue
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (onClear != null && hasValue)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: l10n.commonClear,
                          constraints: const BoxConstraints(
                            minWidth: 56,
                            minHeight: 56,
                          ),
                          onPressed: onClear,
                        )
                      else
                        Icon(
                          Icons.search_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onVoiceSelected != null && settings.voiceInputEnabled) ...[
          const SizedBox(width: 8),
          _VoiceMicButton(
            localeCode: settings.localeCode,
            onQueryRecognized: onVoiceSelected!,
          ),
        ],
      ],
    );
  }
}

/// Opens a modal bottom sheet to search Marprom stops and Maribor places.
Future<TripEndpoint?> showLocationSearchSheet({
  required BuildContext context,
  required String title,
  bool allowCurrentLocation = false,
  String initialQuery = '',
}) {
  return showModalBottomSheet<TripEndpoint>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _LocationSearchSheet(
      title: title,
      allowCurrentLocation: allowCurrentLocation,
      initialQuery: initialQuery,
    ),
  );
}

class _VoiceMicButton extends ConsumerStatefulWidget {
  const _VoiceMicButton({
    required this.localeCode,
    required this.onQueryRecognized,
  });

  final String localeCode;
  final ValueChanged<String> onQueryRecognized;

  @override
  ConsumerState<_VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends ConsumerState<_VoiceMicButton> {
  bool _listening = false;

  Future<void> _toggleListen() async {
    final voice = ref.read(voiceInputProvider);
    if (_listening) {
      await voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    final started = await voice.startListening(
      localeCode: widget.localeCode,
      onResult: (text, isFinal) {
        if (!mounted) return;
        if (isFinal && text.trim().isNotEmpty) {
          setState(() => _listening = false);
          widget.onQueryRecognized(text.trim());
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status != 'listening') {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!started && mounted) {
      setState(() => _listening = false);
      // Still open search dialog gracefully when platform speech is unavailable.
      widget.onQueryRecognized('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.a11yVoiceSearchButton,
      child: IconButton.filledTonal(
        tooltip: _listening ? l10n.askVoicePrompt : l10n.a11yVoiceSearchButton,
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        style: IconButton.styleFrom(
          backgroundColor:
              _listening ? scheme.primary : scheme.secondaryContainer,
          foregroundColor:
              _listening ? scheme.onPrimary : scheme.onSecondaryContainer,
        ),
        icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded),
        onPressed: _toggleListen,
      ),
    );
  }
}

class _LocationSearchSheet extends ConsumerStatefulWidget {
  const _LocationSearchSheet({
    required this.title,
    required this.allowCurrentLocation,
    required this.initialQuery,
  });

  final String title;
  final bool allowCurrentLocation;
  final String initialQuery;

  @override
  ConsumerState<_LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<_LocationSearchSheet> {
  late final TextEditingController _controller;
  List<BusStop> _stops = const [];
  List<Place> _places = const [];
  bool _loading = true;
  bool _gpsLoading = false;
  bool _gpsDenied = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _runSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final lineRepo = ref.read(lineRepositoryProvider);
    final results = await Future.wait([
      lineRepo.searchStops(query),
      lineRepo.searchPlaces(query),
    ]);
    if (!mounted) return;
    setState(() {
      _stops = results[0] as List<BusStop>;
      _places = results[1] as List<Place>;
      _loading = false;
    });
  }

  Future<void> _useGps() async {
    setState(() {
      _gpsLoading = true;
      _gpsDenied = false;
    });
    final pos = await tryFetchCurrentGps(requestIfDenied: true);
    if (!mounted) return;
    if (pos != null) {
      await ref.read(a11ySettingsProvider.notifier).setLocationManualMode(false);
      if (!mounted) return;
      Navigator.of(context).pop(TripEndpoint.gps(pos));
      return;
    }
    setState(() {
      _gpsLoading = false;
      _gpsDenied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoritesProvider);
    final settings = ref.watch(a11ySettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.a11yCloseButton,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.commonClose,
                      constraints: const BoxConstraints(
                        minWidth: 56,
                        minHeight: 56,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l10n.a11ySearchField,
                      child: TextField(
                        controller: _controller,
                        onChanged: _runSearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.mapSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  tooltip: l10n.commonClear,
                                  constraints: const BoxConstraints(
                                    minWidth: 56,
                                    minHeight: 56,
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    _runSearch('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (settings.voiceInputEnabled) ...[
                    const SizedBox(width: 8),
                    _VoiceMicButton(
                      localeCode: settings.localeCode,
                      onQueryRecognized: (text) {
                        if (text.isEmpty) return;
                        _controller.text = text;
                        _runSearch(text);
                      },
                    ),
                  ],
                ],
              ),
              if (widget.allowCurrentLocation) ...[
                const SizedBox(height: 12),
                BigButton(
                  icon: Icons.my_location_rounded,
                  label: l10n.mapCenterOnMe,
                  variant: BigButtonVariant.secondary,
                  expanded: true,
                  loading: _gpsLoading,
                  onPressed: _useGps,
                ),
                if (_gpsDenied) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.mapLocationDeniedTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.mapLocationDeniedBody,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollController,
                        children: [
                          if (_places.isNotEmpty) ...[
                            for (final place in _places)
                              _EndpointResultTile(
                                icon: _placeIcon(place.category),
                                title: place.name,
                                subtitle: place.address,
                                trailingBadge: null,
                                onTap: () => Navigator.of(context).pop(
                                  TripEndpoint.place(place),
                                ),
                              ),
                            const Divider(height: 20),
                          ],
                          for (final stop in _stops)
                            _EndpointResultTile(
                              icon: Icons.directions_bus_rounded,
                              title: stop.name,
                              subtitle: stop.lineIds
                                  .map((code) => l10n.linesBadge(code))
                                  .join(' • '),
                              trailingBadge: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (favorites.isStopFavorite(stop.id))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: scheme.primary,
                                        semanticLabel: l10n.commonFavorites,
                                      ),
                                    ),
                                  if (stop.isStepFree)
                                    Icon(
                                      Icons.accessible_rounded,
                                      color: scheme.secondary,
                                      semanticLabel: l10n.stopAmenityStepFree,
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).pop(
                                TripEndpoint.stop(stop),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static IconData _placeIcon(String category) {
    switch (category) {
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'university':
        return Icons.school_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transit':
        return Icons.directions_transit_outlined;
      case 'sport':
        return Icons.stadium_outlined;
      case 'leisure':
        return Icons.park_outlined;
      case 'work':
        return Icons.business_outlined;
      default:
        return Icons.place_outlined;
    }
  }
}

class _EndpointResultTile extends StatelessWidget {
  const _EndpointResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingBadge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailingBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: ListTile(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Icon(icon),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: trailingBadge,
        onTap: onTap,
      ),
    );
  }
}
