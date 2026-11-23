// Clearly fictional mock Maribor service notices in all 4 supported languages.

import '../models/service_notice.dart';

/// Builds five fictional sample transit notices (detour, delay, cancellation, event, info)
/// anchored relative to [referenceTime] so they stay active during demos and tests.
List<ServiceNotice> buildSeedNotices(DateTime referenceTime) {
  final dayStart =
      DateTime(referenceTime.year, referenceTime.month, referenceTime.day);
  return [
    ServiceNotice(
      id: 'notice_detour_line_4',
      severity: NoticeSeverity.disruption,
      affectedLineIds: const ['4', '8'],
      affectedStopIds: const ['lent', 'glavni_trg'],
      publishedAt: dayStart.subtract(const Duration(hours: 2)),
      validUntil: dayStart.add(const Duration(days: 2)),
      titles: const {
        'sl': 'Obvoz na Koroški cesti in Lentu (liniji 4 in 8)',
        'en': 'Detour via Koroška cesta & Lent (Lines 4 and 8)',
        'de': 'Umleitung über Koroška cesta & Lent (Linien 4 und 8)',
        'sr_Latn': 'Obilazak na Koroškoj cesti i Lentu (linije 4 i 8)',
      },
      bodies: const {
        'sl': 'Zaradi ureditve cestišča avtobusi vozijo po Starem mostu mimo postaje Drava.',
        'en': 'Due to road resurfacing, buses divert over the Old Bridge via Drava stop.',
        'de': 'Wegen Straßenarbeiten fahren die Busse über die Alte Brücke über Drava.',
        'sr_Latn': 'Zbog radova na putu autobusi voze preko Starog mosta pored stanice Drava.',
      },
      alternativeHint: const {
        'sl': 'Uporabite bližnjo postajo Glavni trg ali Drava.',
        'en': 'Board at nearby Glavni trg or Drava stops instead.',
        'de': 'Nutzen Sie alternativ die Haltestellen Glavni trg oder Drava.',
        'sr_Latn': 'Koristite obližnju stanicu Glavni trg ili Drava.',
      },
    ),
    ServiceNotice(
      id: 'notice_delay_line_6',
      severity: NoticeSeverity.delay,
      affectedLineIds: const ['6', '2'],
      affectedStopIds: const ['tabor', 'ukc_maribor', 'titova_cesta'],
      publishedAt: referenceTime.subtract(const Duration(minutes: 45)),
      validUntil: referenceTime.add(const Duration(hours: 6)),
      titles: const {
        'sl': 'Povečan promet na relaciji Tabor – UKC Maribor',
        'en': 'Traffic delays between Tabor and UKC Maribor',
        'de': 'Verkehrsverzögerungen zwischen Tabor und UKC Maribor',
        'sr_Latn': 'Pojačan saobraćaj na relaciji Tabor – UKC Maribor',
      },
      bodies: const {
        'sl': 'Na linijah 2 in 6 pričakujte zamude od 4 do 7 minut v smeri Glavne postaje.',
        'en': 'Expect 4 to 7 minute delays on Lines 2 and 6 heading toward Main Station.',
        'de': 'Auf den Linien 2 und 6 sind 4–7 Min. Verspätung Richtung Hauptbahnhof möglich.',
        'sr_Latn': 'Na linijama 2 i 6 očekuju se kašnjenja od 4 do 7 minuta ka Glavnoj stanici.',
      },
      alternativeHint: const {
        'sl': 'Za nujne prevoze preverite linijo 21 mimo Magdalene.',
        'en': 'Consider Line 21 via Magdalena as an alternative connection.',
        'de': 'Prüfen Sie alternativ die Linie 21 über Magdalena.',
        'sr_Latn': 'Kao alternativu proverite liniju 21 preko Magdalene.',
      },
    ),
    ServiceNotice(
      id: 'notice_cancelled_18',
      severity: NoticeSeverity.disruption,
      affectedLineIds: const ['18'],
      affectedStopIds: const ['pekre', 'vzpenjaca', 'tezno'],
      publishedAt: dayStart.add(const Duration(hours: 5)),
      validUntil: dayStart.add(const Duration(days: 1)),
      titles: const {
        'sl': 'Odpovedan odhod na liniji 18 (10:40 iz Peker)',
        'en': 'Cancelled departure on Line 18 (10:40 from Pekre)',
        'de': 'Ausfall auf Linie 18 (10:40 Uhr ab Pekre)',
        'sr_Latn': 'Otkazan polazak na liniji 18 (10:40 iz Pekara)',
      },
      bodies: const {
        'sl': 'Odhod ob 10:40 iz Peker proti Teznemu danes izjemoma ne bo izveden.',
        'en': 'Today’s 10:40 departure from Pekre toward Tezno is cancelled.',
        'de': 'Die heutige Fahrt um 10:40 Uhr ab Pekre Richtung Tezno entfällt.',
        'sr_Latn': 'Današnji polazak u 10:40 iz Pekara prema Teznom izuzetno ne saobraća.',
      },
      alternativeHint: const {
        'sl': 'Uporabite linijo 16 s postaje Pekre ali linijo 6 z Vzpenjače.',
        'en': 'Use Line 16 from Pekre or Line 6 from Vzpenjača.',
        'de': 'Nutzen Sie Linie 16 ab Pekre oder Linie 6 ab Vzpenjača.',
        'sr_Latn': 'Koristite liniju 16 sa stanice Pekre ili liniju 6 sa Vzpenjače.',
      },
    ),
    ServiceNotice(
      id: 'notice_event_ljudski_vrt',
      severity: NoticeSeverity.info,
      affectedLineIds: const ['1', '7', '21'],
      affectedStopIds: const ['ljudski_vrt', 'univerza'],
      publishedAt: dayStart.subtract(const Duration(days: 1)),
      validUntil: dayStart.add(const Duration(days: 3)),
      titles: const {
        'sl': 'Okrepljeni prevozi ob dogodku na Ljudskem vrtu',
        'en': 'Extra bus frequency for Ljudski vrt stadium event',
        'de': 'Zusätzliche Busse zur Veranstaltung im Stadion Ljudski vrt',
        'sr_Latn': 'Pojačani polasci zbog događaja na stadionu Ljudski vrt',
      },
      bodies: const {
        'sl': 'Med 17:00 in 21:00 vozijo dodatni nizkopodni avtobusi na linijah 1 in 7.',
        'en': 'Extra low-floor buses operate on Lines 1 and 7 between 17:00 and 21:00.',
        'de': 'Zwischen 17:00 und 21:00 Uhr fahren zusätzliche Niederflurbusse auf Linie 1 und 7.',
        'sr_Latn': 'Između 17:00 i 21:00 saobraćaju dodatni niskopodni autobusi na linijama 1 i 7.',
      },
      alternativeHint: const {
        'sl': 'Priporočamo zgodnejši prihod na postajo Univerza.',
        'en': 'Allow an extra 10 minutes or board at Univerza.',
        'de': 'Planen Sie 10 Minuten mehr ein oder steigen Sie bei Univerza zu.',
        'sr_Latn': 'Preporučujemo raniji dolazak na stanicu Univerza.',
      },
    ),
    ServiceNotice(
      id: 'notice_info_winter_schedule',
      severity: NoticeSeverity.info,
      affectedLineIds: const ['1', '2', '3', '6'],
      affectedStopIds: const ['glavni_trg', 'glavna_postaja'],
      publishedAt: dayStart.subtract(const Duration(days: 5)),
      validUntil: dayStart.add(const Duration(days: 30)),
      titles: const {
        'sl': 'Digitalni prikazovalniki in glasovne najave na glavnih vozliščih',
        'en': 'Digital stop displays active across central hubs',
        'de': 'Digitale Anzeigen an allen zentralen Umsteigepunkten aktiv',
        'sr_Latn': 'Digitalni displeji aktivni na centralnim stajalištima',
      },
      bodies: const {
        'sl': 'Na postajah Glavni trg, Glavna postaja, Europark in UKC so na voljo prilagojene najave.',
        'en': 'Accessible arrival displays and audio cues are active at major Maribor hubs.',
        'de': 'Barrierefreie Anzeigen und Ansagen sind an den großen Knotenpunkten aktiv.',
        'sr_Latn': 'Pristupačni displeji i zvučne najave aktivni su na glavnim čvorištima u Mariboru.',
      },
      alternativeHint: const {
        'sl': 'Glasno branje lahko vklopite tudi v nastavitvah aplikacije.',
        'en': 'You can also enable Read Aloud inside app Settings.',
        'de': 'Sie können Vorlesen (TTS) auch in den App-Einstellungen aktivieren.',
        'sr_Latn': 'Čitanje naglas možete uključiti i u podešavanjima aplikacije.',
      },
    ),
  ];
}
