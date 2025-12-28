// lib/alap/konstansok.dart

/// Alkalmazás-szintű konstansok és szerviz definíciók.
/// Bárhonnan elérhető az appon belül.

// Emlékeztető típusok prefixe
const String REMINDER_PREFIX = 'Emlékeztető alap: ';

// Szerviz típusok és alapértelmezett intervallumok (km, hónap)
// Ahol null, ott az adott intervallum nem releváns vagy nem fix.
const Map<String, Map<String, dynamic>> SERVICE_DEFINITIONS = {
  'Olajcsere': {'intervalKm': 15000, 'intervalHonap': 12},
  'Légszűrő': {'intervalKm': 30000, 'intervalHonap': null},
  'Pollenszűrő': {'intervalKm': 30000, 'intervalHonap': null},
  'Üzemanyagszűrő': {'intervalKm': 60000, 'intervalHonap': null},
  'Gyújtógyertya': {'intervalKm': 60000, 'intervalHonap': null},
  'Fékbetét (első)': {'intervalKm': 40000, 'intervalHonap': null},
  'Fékbetét (hátsó)': {'intervalKm': 60000, 'intervalHonap': null},
  'Fékfolyadék': {'intervalKm': 60000, 'intervalHonap': 24}, // Pl. 2 évente
  'Hűtőfolyadék': {'intervalKm': 120000, 'intervalHonap': 36}, // Pl. 3 évente
  'Kuplung': {'intervalKm': 150000, 'intervalHonap': null},
  'Vezérlés (Szíj)': {'intervalKm': 120000, 'intervalHonap': null}, // Régebbi "Vezérlés csere"
  'Műszaki vizsga': {'intervalKm': null, 'intervalHonap': 24}, // 2 évente
  'Kötelező biztosítás': {'intervalKm': null, 'intervalHonap': 12}, // Évente
  'CASCO': {'intervalKm': null, 'intervalHonap': 12}, // Évente
  'Pályamatrica': {'intervalKm': null, 'intervalHonap': 12}, // Évente
};

// Azon szerviztípusok listája, amelyeknél figyelembe vesszük a km-alapú emlékeztetőt
const List<String> KM_BASED_SERVICE_TYPES = [
  'Olajcsere',
  'Légszűrő',
  'Pollenszűrő',
  'Gyújtógyertya',
  'Üzemanyagszűrő',
  'Vezérlés (Szíj)',
  'Fékbetét (első)',
  'Fékbetét (hátsó)',
  'Fékfolyadék',
  'Hűtőfolyadék',
  'Kuplung',
];

// Azon szerviztípusok listája, amelyeknél figyelembe vesszük a dátum-alapú emlékeztetőt
const List<String> DATE_BASED_SERVICE_TYPES = [
  'Műszaki vizsga',
  'Olajcsere', // Az olajcsere dátum és km alapú is lehet
  'Fékfolyadék',
  'Hűtőfolyadék',
  'Kötelező biztosítás',
  'CASCO',
  'Pályamatrica',
];

// Az összes emlékeztető alapjául szolgáló szerviztípus
final List<String> ALL_REMINDER_SERVICE_TYPES =
    (KM_BASED_SERVICE_TYPES + DATE_BASED_SERVICE_TYPES).toSet().toList();
