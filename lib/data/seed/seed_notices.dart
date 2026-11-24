// Sample Marprom Maribor transit notices in all 4 supported languages (sl, en, de, sr_Latn).

import '../models/service_notice.dart';

/// Builds five sample transit notices (detour, delay, cancellation, event, info)
/// anchored relative to [referenceTime] so they stay active during demos and tests.
List<ServiceNotice> buildSeedNotices(DateTime referenceTime) {
  final dayStart =
      DateTime(referenceTime.year, referenceTime.month, referenceTime.day);
  return [
    ServiceNotice(
      id: 'notice_detour_line_4',
      severity: NoticeSeverity.disruption,
      affectedLineIds: const ['G4', 'G5', 'P8'],
      affectedStopIds: const ['lent', 'glavni_trg'],
      publishedAt: dayStart.subtract(const Duration(hours: 2)),
      validUntil: dayStart.add(const Duration(days: 2)),
      titles: const {
        'sl': 'Obvoz na Koroški cesti in Lentu (linije G4, G5 in P8)',
        'en': 'Detour via Koroška cesta & Lent (Lines G4, G5 and P8)',
        'de': 'Umleitung über Koroška cesta & Lent (Linien G4, G5 und P8)',
        'sr_Latn': 'Obilazak na Koroškoj cesti i Lentu (linije G4, G5 i P8)',
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
      affectedLineIds: const ['G6', 'G2'],
      affectedStopIds: const ['tabor', 'ukc_maribor', 'titova_cesta'],
      publishedAt: referenceTime.subtract(const Duration(minutes: 45)),
      validUntil: referenceTime.add(const Duration(hours: 6)),
      titles: const {
        'sl': 'Povečan promet na relaciji Tabor – UKC Maribor (G2, G6)',
        'en': 'Traffic delays between Tabor and UKC Maribor (G2, G6)',
        'de': 'Verkehrsverzögerungen zwischen Tabor und UKC Maribor (G2, G6)',
        'sr_Latn': 'Pojačan saobraćaj na relaciji Tabor – UKC Maribor (G2, G6)',
      },
      bodies: const {
        'sl': 'Na linijah G2 in G6 pričakujte zamude od 4 do 7 minut v smeri AP Maribor.',
        'en': 'Expect 4 to 7 minute delays on Lines G2 and G6 heading toward Maribor Bus Station.',
        'de': 'Auf den Linien G2 und G6 sind 4–7 Min. Verspätung Richtung Busbahnhof möglich.',
        'sr_Latn': 'Na linijama G2 i G6 očekuju se kašnjenja od 4 do 7 minuta ka Glavnoj stanici.',
      },
      alternativeHint: const {
        'sl': 'Za nujne prevoze preverite povezovalno linijo P11 ali G5.',
        'en': 'Consider Line P11 or electric Line G5 as an alternative connection.',
        'de': 'Prüfen Sie alternativ die Linie P11 oder E-Linie G5.',
        'sr_Latn': 'Kao alternativu proverite liniju P11 ili G5.',
      },
    ),
    ServiceNotice(
      id: 'notice_cancelled_18',
      severity: NoticeSeverity.disruption,
      affectedLineIds: const ['P18'],
      affectedStopIds: const ['pekre', 'nova_vas', 'ukc_maribor'],
      publishedAt: dayStart.add(const Duration(hours: 5)),
      validUntil: dayStart.add(const Duration(days: 1)),
      titles: const {
        'sl': 'Odpovedan odhod na liniji P18 (10:40 iz Peker)',
        'en': 'Cancelled departure on Line P18 (10:40 from Pekre)',
        'de': 'Ausfall auf Linie P18 (10:40 Uhr ab Pekre)',
        'sr_Latn': 'Otkazan polazak na liniji P18 (10:40 iz Pekara)',
      },
      bodies: const {
        'sl': 'Odhod ob 10:40 iz Peker proti UKC Maribor danes izjemoma ne bo izveden.',
        'en': 'Today’s 10:40 departure from Pekre toward UKC Maribor is cancelled.',
        'de': 'Die heutige Fahrt um 10:40 Uhr ab Pekre Richtung UKC Maribor entfällt.',
        'sr_Latn': 'Današnji polazak u 10:40 iz Pekara prema UKC Maribor izuzetno ne saobraća.',
      },
      alternativeHint: const {
        'sl': 'Uporabite linijo P8 s postaje Pekre ali linijo G6 z Vzpenjače.',
        'en': 'Use Line P8 from Pekre or Line G6 from Vzpenjača.',
        'de': 'Nutzen Sie Linie P8 ab Pekre oder Linie G6 ab Vzpenjača.',
        'sr_Latn': 'Koristite liniju P8 sa stanice Pekre ili liniju G6 sa Vzpenjače.',
      },
    ),
    ServiceNotice(
      id: 'notice_event_ljudski_vrt',
      severity: NoticeSeverity.info,
      affectedLineIds: const ['G3', 'P7', 'P15'],
      affectedStopIds: const ['ljudski_vrt', 'univerza'],
      publishedAt: dayStart.subtract(const Duration(days: 1)),
      validUntil: dayStart.add(const Duration(days: 3)),
      titles: const {
        'sl': 'Okrepljeni prevozi ob dogodku na Ljudskem vrtu (G3, P7)',
        'en': 'Extra bus frequency for Ljudski vrt stadium event (G3, P7)',
        'de': 'Zusätzliche Busse zur Veranstaltung im Stadion Ljudski vrt (G3, P7)',
        'sr_Latn': 'Pojačani polasci zbog događaja na stadionu Ljudski vrt (G3, P7)',
      },
      bodies: const {
        'sl': 'Med 17:00 in 21:00 vozijo dodatni električni nizkopodni avtobusi na linijah G3 in P7.',
        'en': 'Extra electric low-floor buses operate on Lines G3 and P7 between 17:00 and 21:00.',
        'de': 'Zwischen 17:00 und 21:00 Uhr fahren zusätzliche E-Niederflurbusse auf Linie G3 und P7.',
        'sr_Latn': 'Između 17:00 i 21:00 saobraćaju dodatni električni autobusi na linijama G3 i P7.',
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
      affectedLineIds: const ['G1', 'G2', 'G5', 'G6'],
      affectedStopIds: const ['glavni_trg', 'glavna_postaja'],
      publishedAt: dayStart.subtract(const Duration(days: 5)),
      validUntil: dayStart.add(const Duration(days: 14)),
      titles: const {
        'sl': 'Petkove podaljšane večerne vožnje na glavnih linijah G1, G2, G5 in G6',
        'en': 'Extended Friday evening service on main lines G1, G2, G5 and G6',
        'de': 'Verlängerte Freitagsfahrten auf den Hauptlinien G1, G2, G5 und G6',
        'sr_Latn': 'Produženi večernji polasci petkom na linijama G1, G2, G5 i G6',
      },
      bodies: const {
        'sl': 'Ob petkih vozijo glavni mestni avtobusi Marprom do 23:55 po prenovljenem voznem redu.',
        'en': 'Every Friday, core Marprom main lines operate extended evening trips until 23:55.',
        'de': 'Jeden Freitag verkehren die Hauptlinien von Marprom bis 23:55 Uhr.',
        'sr_Latn': 'Petkom glavne gradske linije Marproma saobraćaju do 23:55.',
      },
      alternativeHint: const {
        'sl': 'Celoten vozni red za vse dni v tednu preverite v zavihku Vozni redi.',
        'en': 'Inspect the full 7-day timetable in the Schedules section.',
        'de': 'Den vollständigen 7-Tage-Fahrplan finden Sie unter Fahrpläne.',
        'sr_Latn': 'Kompletan red vožnje za svih 7 dana pogledajte u odeljku Red vožnje.',
      },
    ),
  ];
}
