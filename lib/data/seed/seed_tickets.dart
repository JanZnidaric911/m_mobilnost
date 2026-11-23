// Clearly fictional mock Maribor ticket catalog in EUR with 4-language metadata.

import '../models/ticket_type.dart';

/// Seven fictional Marprom EUR ticket types covering single, pass, youth, and senior tiers.
const List<TicketType> seedTicketTypes = [
  TicketType(
    id: 'single',
    code: 'SINGLE75',
    durationMinutes: 75,
    priceEur: 1.30,
    titles: {
      'sl': 'Enkratna vozovnica (75 min)',
      'en': 'Single ride ticket (75 min)',
      'de': 'Einzelfahrschein (75 Min.)',
      'sr_Latn': 'Pojedinačna karta (75 min)',
    },
    descriptions: {
      'sl': 'Velja za neomejeno prestopanje v coni Maribor 75 minut od nakupa.',
      'en': 'Valid for unlimited transfers within Maribor Zone for 75 minutes.',
      'de': 'Gültig für unbegrenzte Umstiege in der Zone Maribor für 75 Minuten.',
      'sr_Latn': 'Važi za neograničena presedanja u zoni Maribor 75 minuta.',
    },
  ),
  TicketType(
    id: 'day_24h',
    code: 'DAY24',
    durationMinutes: 1440,
    priceEur: 3.50,
    titles: {
      'sl': 'Dnevna vozovnica (24 ur)',
      'en': '24-hour day pass',
      'de': '24-Stunden-Tageskarte',
      'sr_Latn': 'Dnevna karta (24 sata)',
    },
    descriptions: {
      'sl': 'Celodnevna vožnja na vseh mestnih linijah v Mariboru.',
      'en': 'Unlimited rides across all Maribor city bus lines for 24 hours.',
      'de': 'Unbegrenzte Fahrten auf allen Stadtbuslinien in Maribor für 24 Stunden.',
      'sr_Latn': 'Neograničena vožnja na svim gradskim linijama u Mariboru 24 sata.',
    },
  ),
  TicketType(
    id: 'weekly',
    code: 'WEEK7',
    durationMinutes: 10080,
    priceEur: 12.00,
    titles: {
      'sl': 'Tedenska vozovnica',
      'en': 'Weekly pass',
      'de': 'Wochenkarte',
      'sr_Latn': 'Nedeljna karta',
    },
    descriptions: {
      'sl': 'Sedem dni neomejenega mestnega prevoza v coni Maribor.',
      'en': 'Seven consecutive days of unlimited travel in Maribor Zone.',
      'de': 'Sieben Tage unbegrenzte Fahrt in der Zone Maribor.',
      'sr_Latn': 'Sedam dana neograničenog gradskog prevoza u zoni Maribor.',
    },
  ),
  TicketType(
    id: 'monthly',
    code: 'MONTH30',
    durationMinutes: 43200,
    priceEur: 35.00,
    titles: {
      'sl': 'Mesečna vozovnica',
      'en': 'Monthly pass',
      'de': 'Monatskarte',
      'sr_Latn': 'Mesečna karta',
    },
    descriptions: {
      'sl': '30-dnevna splošna mestna vozovnica za redne potnike.',
      'en': '30-day standard city pass for daily commuters.',
      'de': '30-Tage-Standardkarte für regelmäßige Fahrgäste.',
      'sr_Latn': 'Mesečna gradska karta za redovne putnike u trajanju od 30 dana.',
    },
  ),
  TicketType(
    id: 'student_monthly',
    code: 'STUD30',
    durationMinutes: 43200,
    priceEur: 20.00,
    isYouthOnly: true,
    titles: {
      'sl': 'Študentska mesečna vozovnica',
      'en': 'Student monthly pass',
      'de': 'Studenten-Monatskarte',
      'sr_Latn': 'Studentska mesečna karta',
    },
    descriptions: {
      'sl': 'Znižana 30-dnevna vozovnica za dijake in študente do 26. leta.',
      'en': 'Discounted 30-day pass for students and youth up to age 26.',
      'de': 'Ermäßigte 30-Tage-Karte für Schüler und Studierende bis 26 Jahre.',
      'sr_Latn': 'Povlašćena 30-dnevna karta za učenike i studente do 26 godina.',
    },
  ),
  TicketType(
    id: 'youth',
    code: 'YOUTH75',
    durationMinutes: 75,
    priceEur: 0.90,
    isYouthOnly: true,
    titles: {
      'sl': 'Mladinska vozovnica (6–26 let)',
      'en': 'Youth single ticket (ages 6–26)',
      'de': 'Jugend-Einzelfahrschein (6–26 J.)',
      'sr_Latn': 'Karta za mlade (6–26 god.)',
    },
    descriptions: {
      'sl': 'Enkratna 75-minutna vozovnica s popustom za mlade.',
      'en': 'Discounted 75-minute single ride ticket for young passengers.',
      'de': 'Ermäßigter 75-Minuten-Einzelfahrschein für junge Fahrgäste.',
      'sr_Latn': 'Povlašćena pojedinačna karta od 75 minuta za mlade putnike.',
    },
  ),
  TicketType(
    id: 'senior',
    code: 'SENIOR75',
    durationMinutes: 75,
    priceEur: 0.90,
    isSeniorOnly: true,
    titles: {
      'sl': 'Upokojenska vozovnica (65+)',
      'en': 'Senior single ticket (65+)',
      'de': 'Senioren-Einzelfahrschein (65+)',
      'sr_Latn': 'Penzionerska karta (65+)',
    },
    descriptions: {
      'sl': 'Enkratna 75-minutna vozovnica s popustom za starejše od 65 let.',
      'en': 'Discounted 75-minute single ticket for riders aged 65 and over.',
      'de': 'Ermäßigter 75-Minuten-Fahrschein für Fahrgäste ab 65 Jahren.',
      'sr_Latn': 'Povlašćena karta od 75 minuta za putnike starije od 65 godina.',
    },
  ),
];

/// Fast ID-indexed map of [seedTicketTypes].
final Map<String, TicketType> seedTicketTypesById = {
  for (final type in seedTicketTypes) type.id: type,
};
