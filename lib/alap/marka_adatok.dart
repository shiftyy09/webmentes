// lib/alap/marka_adatok.dart

/// Magyarországon elterjedt autós alkatrész- és folyadékmárkák kategóriák szerint.
const Map<String, List<String>> BRANDS_BY_CATEGORY = {
  'Olaj': [
    'Castrol', 'Motul', 'Mobil 1', 'Shell', 'Valvoline', 'Total', 'Elf', 
    'Liqui Moly', 'Mannol', 'Eneos', 'Repsol', 'Fuchs', 'Petronas', 'Aral', 
    'BMW (OEM)', 'Ford (OEM)', 'Opel (GM)', 'Toyota (OEM)', 'Ravenol', 'Mol'
  ],
  'Szűrő': [ // Légszűrő, Pollenszűrő, Üzemanyagszűrő
    'Mann-Filter', 'Bosch', 'Mahle', 'Knecht', 'Purflux', 'Filtron', 'Hengst', 
    'Champion', 'Fram', 'UFI', 'Blue Print', 'Sofima', 'Muller', 'Japanparts'
  ],
  'Fék': [ // Fékbetét, Féktárcsa, Fékfolyadék
    'Brembo', 'TRW', 'ATE', 'Textar', 'Bosch', 'Ferodo', 'Zimmermann', 
    'Jurid', 'LPR', 'Delphi', 'Meyle', 'Febi Bilstein', 'EBC Brakes'
  ],
  'Gyújtás': [ // Gyújtógyertya
    'NGK', 'Bosch', 'Denso', 'Beru', 'Champion', 'Magneti Marelli', 'Eyquem'
  ],
  'Vezérlés': [ // Szíj, Lánc
    'Continental (Contitech)', 'Gates', 'INA', 'SKF', 'Dayco', 'Bosch', 'Ruville', 'Fai'
  ],
  'Akkumulátor': [
    'Varta', 'Bosch', 'Exide', 'Banner', 'Perion', 'Rocket', 'Electric Power', 'Yuasa'
  ],
  'Gumi': [
    'Michelin', 'Continental', 'Bridgestone', 'Goodyear', 'Pirelli', 'Hankook', 
    'Nokian', 'Dunlop', 'Toyo', 'Yokohama', 'Kumho', 'Nexen', 'Barum', 'Debica'
  ],
  'Egyéb': [
    'Bosch', 'Valeo', 'Hella', 'Sachs', 'Luk', 'Monroe', 'KYB', 'Lemförder', 'Delphi'
  ]
};

/// Segédfüggvény a megfelelő márkalista kiválasztásához a szerviz típusa alapján.
List<String> getBrandsForServiceType(String serviceType) {
  if (serviceType.contains('Olaj')) return BRANDS_BY_CATEGORY['Olaj']!;
  if (serviceType.contains('szűrő')) return BRANDS_BY_CATEGORY['Szűrő']!;
  if (serviceType.contains('Fék')) return BRANDS_BY_CATEGORY['Fék']!;
  if (serviceType.contains('gyertya')) return BRANDS_BY_CATEGORY['Gyújtás']!;
  if (serviceType.contains('Vezérlés') || serviceType.contains('Szíj')) return BRANDS_BY_CATEGORY['Vezérlés']!;
  if (serviceType.contains('Akkumulátor')) return BRANDS_BY_CATEGORY['Akkumulátor']!;
  if (serviceType.contains('Gumi') || serviceType.contains('Kerék')) return BRANDS_BY_CATEGORY['Gumi']!;
  
  return BRANDS_BY_CATEGORY['Egyéb']!;
}
