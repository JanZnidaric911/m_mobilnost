// Persists and exposes accessibility, theme, locale, and simulation settings via Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported appearance modes including WCAG AAA high contrast.
enum AppThemeChoice {
  /// Follow the operating system brightness.
  system,

  /// Always use the light WCAG AA theme.
  light,

  /// Always use the dark WCAG AA theme.
  dark,

  /// Always use the black/white/yellow WCAG AAA high-contrast theme.
  highContrast,
}

/// Immutable accessibility and app preference state.
@immutable
class A11ySettings {
  /// Creates an [A11ySettings] configuration snapshot.
  const A11ySettings({
    this.themeMode = AppThemeChoice.system,
    this.localeCode = 'sl',
    this.extraLargeText = false,
    this.reducedMotion = false,
    this.readAloudEnabled = false,
    this.voiceInputEnabled = true,
    this.hapticAlertsEnabled = true,
    this.soundAlertsOptional = false,
    this.showDataSource = true,
    this.useSimulatedLive = true,
    this.simulationSeed = 42,
    this.usabilityTestMode = false,
    this.analyticsConsent = false,
    this.notificationsConsent = false,
    this.locationManualMode = false,
    this.onboardingDone = false,
  });

  /// Active theme preference (system, light, dark, or highContrast).
  final AppThemeChoice themeMode;

  /// Active language code: 'sl', 'en', 'de', or 'sr_Latn'.
  final String localeCode;

  /// Scales typography up to 200% across the entire app.
  final bool extraLargeText;

  /// Disables transition and motion animations.
  final bool reducedMotion;

  /// Enables text-to-speech playback for instructions and alerts.
  final bool readAloudEnabled;

  /// Enables microphone voice search where supported.
  final bool voiceInputEnabled;

  /// Enables distinct vibration patterns for transit cues.
  final bool hapticAlertsEnabled;

  /// Enables optional short audio alerts alongside haptics.
  final bool soundAlertsOptional;

  /// Shows badges indicating live, simulated, or cached data sources.
  final bool showDataSource;

  /// Uses deterministic simulated Marprom vehicle telemetry.
  final bool useSimulatedLive;

  /// Seed controlling deterministic fleet simulation.
  final int simulationSeed;

  /// Enables developer/evaluator usability test shortcuts.
  final bool usabilityTestMode;

  /// User GDPR consent for anonymous analytics.
  final bool analyticsConsent;

  /// User GDPR consent for push/local arrival and disruption alerts.
  final bool notificationsConsent;

  /// Uses a manually selected Maribor stop instead of GPS.
  final bool locationManualMode;

  /// Whether the first-run onboarding flow has been completed.
  final bool onboardingDone;

  /// Whether high-contrast WCAG AAA mode is active.
  bool get isHighContrast => themeMode == AppThemeChoice.highContrast;

  /// Converts [themeMode] into Flutter's [ThemeMode] for MaterialApp.
  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case AppThemeChoice.system:
        return ThemeMode.system;
      case AppThemeChoice.light:
        return ThemeMode.light;
      case AppThemeChoice.dark:
      case AppThemeChoice.highContrast:
        return ThemeMode.dark;
    }
  }

  /// Converts [localeCode] into the corresponding [Locale] object.
  Locale toLocale() {
    if (localeCode == 'sr_Latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    if (const ['sl', 'en', 'de'].contains(localeCode)) {
      return Locale(localeCode);
    }
    return const Locale('sl');
  }

  /// Returns a copy with specified fields replaced.
  A11ySettings copyWith({
    AppThemeChoice? themeMode,
    String? localeCode,
    bool? extraLargeText,
    bool? reducedMotion,
    bool? readAloudEnabled,
    bool? voiceInputEnabled,
    bool? hapticAlertsEnabled,
    bool? soundAlertsOptional,
    bool? showDataSource,
    bool? useSimulatedLive,
    int? simulationSeed,
    bool? usabilityTestMode,
    bool? analyticsConsent,
    bool? notificationsConsent,
    bool? locationManualMode,
    bool? onboardingDone,
  }) {
    return A11ySettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      extraLargeText: extraLargeText ?? this.extraLargeText,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      readAloudEnabled: readAloudEnabled ?? this.readAloudEnabled,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
      hapticAlertsEnabled: hapticAlertsEnabled ?? this.hapticAlertsEnabled,
      soundAlertsOptional: soundAlertsOptional ?? this.soundAlertsOptional,
      showDataSource: showDataSource ?? this.showDataSource,
      useSimulatedLive: useSimulatedLive ?? this.useSimulatedLive,
      simulationSeed: simulationSeed ?? this.simulationSeed,
      usabilityTestMode: usabilityTestMode ?? this.usabilityTestMode,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      notificationsConsent: notificationsConsent ?? this.notificationsConsent,
      locationManualMode: locationManualMode ?? this.locationManualMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A11ySettings &&
        other.themeMode == themeMode &&
        other.localeCode == localeCode &&
        other.extraLargeText == extraLargeText &&
        other.reducedMotion == reducedMotion &&
        other.readAloudEnabled == readAloudEnabled &&
        other.voiceInputEnabled == voiceInputEnabled &&
        other.hapticAlertsEnabled == hapticAlertsEnabled &&
        other.soundAlertsOptional == soundAlertsOptional &&
        other.showDataSource == showDataSource &&
        other.useSimulatedLive == useSimulatedLive &&
        other.simulationSeed == simulationSeed &&
        other.usabilityTestMode == usabilityTestMode &&
        other.analyticsConsent == analyticsConsent &&
        other.notificationsConsent == notificationsConsent &&
        other.locationManualMode == locationManualMode &&
        other.onboardingDone == onboardingDone;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        localeCode,
        extraLargeText,
        reducedMotion,
        readAloudEnabled,
        voiceInputEnabled,
        hapticAlertsEnabled,
        soundAlertsOptional,
        showDataSource,
        useSimulatedLive,
        simulationSeed,
        usabilityTestMode,
        analyticsConsent,
        notificationsConsent,
        locationManualMode,
        onboardingDone,
      );
}

/// Provides the initialized [SharedPreferences] instance (overridden at startup).
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Riverpod provider exposing [A11ySettingsNotifier] and current [A11ySettings].
final a11ySettingsProvider =
    StateNotifierProvider<A11ySettingsNotifier, A11ySettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return A11ySettingsNotifier(prefs);
});

/// Manages and persists [A11ySettings] to [SharedPreferences].
class A11ySettingsNotifier extends StateNotifier<A11ySettings> {
  /// Creates a notifier backed by an optional [SharedPreferences] store.
  A11ySettingsNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static const _kThemeMode = 'a11y_theme_mode';
  static const _kLocaleCode = 'a11y_locale_code';
  static const _kExtraLargeText = 'a11y_extra_large_text';
  static const _kReducedMotion = 'a11y_reduced_motion';
  static const _kReadAloud = 'a11y_read_aloud';
  static const _kVoiceInput = 'a11y_voice_input';
  static const _kHapticAlerts = 'a11y_haptic_alerts';
  static const _kSoundAlerts = 'a11y_sound_alerts';
  static const _kShowDataSource = 'a11y_show_data_source';
  static const _kUseSimulatedLive = 'a11y_use_simulated_live';
  static const _kSimulationSeed = 'a11y_simulation_seed';
  static const _kUsabilityTestMode = 'a11y_usability_test_mode';
  static const _kAnalyticsConsent = 'a11y_analytics_consent';
  static const _kNotificationsConsent = 'a11y_notifications_consent';
  static const _kLocationManual = 'a11y_location_manual';
  static const _kOnboardingDone = 'a11y_onboarding_done';

  static A11ySettings _loadInitial(SharedPreferences? prefs) {
    if (prefs == null) return const A11ySettings();
    final themeName = prefs.getString(_kThemeMode);
    final theme = AppThemeChoice.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemeChoice.system,
    );
    return A11ySettings(
      themeMode: theme,
      localeCode: prefs.getString(_kLocaleCode) ?? 'sl',
      extraLargeText: prefs.getBool(_kExtraLargeText) ?? false,
      reducedMotion: prefs.getBool(_kReducedMotion) ?? false,
      readAloudEnabled: prefs.getBool(_kReadAloud) ?? false,
      voiceInputEnabled: prefs.getBool(_kVoiceInput) ?? true,
      hapticAlertsEnabled: prefs.getBool(_kHapticAlerts) ?? true,
      soundAlertsOptional: prefs.getBool(_kSoundAlerts) ?? false,
      showDataSource: prefs.getBool(_kShowDataSource) ?? true,
      useSimulatedLive: prefs.getBool(_kUseSimulatedLive) ?? true,
      simulationSeed: prefs.getInt(_kSimulationSeed) ?? 42,
      usabilityTestMode: prefs.getBool(_kUsabilityTestMode) ?? false,
      analyticsConsent: prefs.getBool(_kAnalyticsConsent) ?? false,
      notificationsConsent: prefs.getBool(_kNotificationsConsent) ?? false,
      locationManualMode: prefs.getBool(_kLocationManual) ?? false,
      onboardingDone: prefs.getBool(_kOnboardingDone) ?? false,
    );
  }

  /// Updates and persists [themeMode].
  Future<void> setThemeMode(AppThemeChoice value) async {
    state = state.copyWith(themeMode: value);
    await _prefs?.setString(_kThemeMode, value.name);
  }

  /// Updates and persists [localeCode] ('sl', 'en', 'de', or 'sr_Latn').
  Future<void> setLocaleCode(String value) async {
    state = state.copyWith(localeCode: value);
    await _prefs?.setString(_kLocaleCode, value);
  }

  /// Updates and persists [extraLargeText].
  Future<void> setExtraLargeText(bool value) async {
    state = state.copyWith(extraLargeText: value);
    await _prefs?.setBool(_kExtraLargeText, value);
  }

  /// Updates and persists [reducedMotion].
  Future<void> setReducedMotion(bool value) async {
    state = state.copyWith(reducedMotion: value);
    await _prefs?.setBool(_kReducedMotion, value);
  }

  /// Updates and persists [readAloudEnabled].
  Future<void> setReadAloudEnabled(bool value) async {
    state = state.copyWith(readAloudEnabled: value);
    await _prefs?.setBool(_kReadAloud, value);
  }

  /// Updates and persists [voiceInputEnabled].
  Future<void> setVoiceInputEnabled(bool value) async {
    state = state.copyWith(voiceInputEnabled: value);
    await _prefs?.setBool(_kVoiceInput, value);
  }

  /// Updates and persists [hapticAlertsEnabled].
  Future<void> setHapticAlertsEnabled(bool value) async {
    state = state.copyWith(hapticAlertsEnabled: value);
    await _prefs?.setBool(_kHapticAlerts, value);
  }

  /// Updates and persists [soundAlertsOptional].
  Future<void> setSoundAlertsOptional(bool value) async {
    state = state.copyWith(soundAlertsOptional: value);
    await _prefs?.setBool(_kSoundAlerts, value);
  }

  /// Updates and persists [showDataSource].
  Future<void> setShowDataSource(bool value) async {
    state = state.copyWith(showDataSource: value);
    await _prefs?.setBool(_kShowDataSource, value);
  }

  /// Updates and persists [useSimulatedLive].
  Future<void> setUseSimulatedLive(bool value) async {
    state = state.copyWith(useSimulatedLive: value);
    await _prefs?.setBool(_kUseSimulatedLive, value);
  }

  /// Updates and persists [simulationSeed].
  Future<void> setSimulationSeed(int value) async {
    state = state.copyWith(simulationSeed: value);
    await _prefs?.setInt(_kSimulationSeed, value);
  }

  /// Updates and persists [usabilityTestMode].
  Future<void> setUsabilityTestMode(bool value) async {
    state = state.copyWith(usabilityTestMode: value);
    await _prefs?.setBool(_kUsabilityTestMode, value);
  }

  /// Updates and persists [analyticsConsent].
  Future<void> setAnalyticsConsent(bool value) async {
    state = state.copyWith(analyticsConsent: value);
    await _prefs?.setBool(_kAnalyticsConsent, value);
  }

  /// Updates and persists [notificationsConsent].
  Future<void> setNotificationsConsent(bool value) async {
    state = state.copyWith(notificationsConsent: value);
    await _prefs?.setBool(_kNotificationsConsent, value);
  }

  /// Updates and persists [locationManualMode].
  Future<void> setLocationManualMode(bool value) async {
    state = state.copyWith(locationManualMode: value);
    await _prefs?.setBool(_kLocationManual, value);
  }

  /// Updates and persists [onboardingDone].
  Future<void> setOnboardingDone(bool value) async {
    state = state.copyWith(onboardingDone: value);
    await _prefs?.setBool(_kOnboardingDone, value);
  }

  /// Resets all preferences back to defaults while clearing persisted keys.
  Future<void> resetAll() async {
    state = const A11ySettings();
    await _prefs?.clear();
  }
}
