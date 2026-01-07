Tökéletes. Mivel a projektet AI segítségével fejleszted, a legfontosabb egy olyan README.md fájl, ami nem csak embereknek, hanem a következő AI-nak (ChatGPT, Claude, Copilot) is elmagyarázza a "játékszabályokat".

Ezt a szöveget mentsd el README.md néven a projekt gyökérmappájába. Ha legközelebb segítséget kérsz egy AI-tól, ezt a fájlt csatold neki először, és azonnal érteni fogja a rendszert.

Olajfolt Web - Projekt Dokumentáció

Ez a dokumentum a fejlesztést segítő AI modellek számára készült, hogy megértsék a projekt struktúráját, logikáját és az adatbázis működését.

📌 Projekt Leírása

Az Olajfolt Web egy Flutter alapú webes alkalmazás járművek karbantartásának, szerviznaplójának és költségeinek nyomon követésére. Az alkalmazás Firebase (Firestore, Auth) backendet használ, és Riverpodot az állapotkezeléshez.

Főbb funkciók

Járműkezelés: Több jármű felvétele, szerkesztése, törlése.

Szerviznapló: Karbantartások rögzítése (leírás, dátum, km, ár).

Tankolási napló: Üzemanyag fogyasztás számítása.

Emlékeztetők: Automatikus figyelmeztetés km vagy dátum alapján (pl. olajcsere, műszaki).

Statisztikák: Havi költségek, éves összehasonlítás, predikciók.

Eszközök: Átírási költség kalkulátor, PDF exportálás.

📂 Mappa Struktúra (File Tree)
code
Text
download
content_copy
expand_less
lib/
├── main.dart                  # Belépési pont, Firebase init, App Check
├── firebase_options.dart      # Firebase konfiguráció
├── providers.dart             # Riverpod providerek (Auth, Firestore stream-ek)
├── theme_provider.dart        # Sötét/Világos mód kezelése
├── alap/                      # Statikus adatok és konstansok
│   ├── konstansok.dart        # Szerviz intervallumok, típusok definíciói
│   ├── jarmu_adatok.dart      # Autómárkák listája
│   └── marka_adatok.dart      # Alkatrész márkák (Olaj, Szűrő stb.)
├── modellek/                  # Adatmodellek
│   ├── jarmu.dart             # Jarmu osztály (fromFirestore, toFirestore)
│   └── karbantartas_bejegyzes.dart # Szerviz osztály
├── services/                  # Üzleti logika
│   ├── auth_service.dart      # Login, Register, Logout
│   ├── firestore_service.dart # CRUD műveletek (Jármű, Szerviz)
│   ├── pdf_service.dart       # Szerviznapló PDF generálás
│   └── statistics_service.dart# Fogyasztás és költség számítások
└── ui/                        # Felhasználói felület
    ├── login_page.dart        # Bejelentkezés / Regisztráció
    ├── dashboard_page.dart    # Főmenü (Landing page belépés után)
    ├── home_page.dart         # Járműlista és Részletek főoldala
    ├── notification_settings_page.dart # Értesítési beállítások
    ├── calculators/
    │   └── transfer_cost_page.dart # Átírás kalkulátor
    ├── dialogs/               # Modális ablakok
    │   ├── service_editor_dialog.dart # Szerviz hozzáadása/szerkesztése
    │   ├── fueling_dialog.dart        # Tankolás rögzítése
    │   ├── vehicle_editor_dialog.dart # Jármű felvétele (Emlékeztetők init!)
    │   └── notification_settings_dialog.dart
    └── widgets/               # Újrafelhasználható UI elemek
        ├── service_list_view.dart      # Szerviz lista (TAB 2) - Itt van a szűrés!
        ├── maintenance_reminder_view.dart # Emlékeztető kártyák (TAB 1)
        ├── vehicle_stats_view.dart     # Statisztikák (TAB 4)
        ├── vehicle_data_view.dart      # Jármű adatok + PDF gomb (TAB 3)
        ├── vehicle_detail_panel.dart   # Jobb oldali panel (TabController)
        ├── vehicle_list_view.dart      # Bal oldali járműlista
        ├── service_list_item.dart      # Egy szerviz kártya dizájnja
        └── success_overlay.dart        # Sikeres mentés animáció
🧠 Projekt Logika és "Trükkök" (Fontos az AI-nak)
1. Emlékeztető Rendszer ("Hidden Services")

Ez a projekt legkritikusabb része.

Logika: Az alkalmazás nem tart külön reminders táblát. Az emlékeztetők állapotát (mikor volt utoljára olajcsere) speciális szervizbejegyzések tárolják.

Prefix: Ezeknek a bejegyzéseknek a leírása (description) ezzel kezdődik: Emlékeztető alap: (Lásd: REMINDER_PREFIX a konstansok.dart-ban).

Megjelenítés:

A MaintenanceReminderView (TAB 1) LÁTJA ezeket az adatokat, ebből számolja ki, mennyi van még hátra.

A ServiceListView (TAB 2) ELREJTI ezeket az adatokat (!s.description.startsWith(REMINDER_PREFIX)), hogy a felhasználó ne lásson technikai sorokat a naplóban.

Létrehozás: Új jármű létrehozásakor (VehicleEditorDialog) a rendszer legenerálja ezeket a rejtett bejegyzéseket a megadott dátumokkal/km-rel.

2. Provider Működés

A servicesForSelectedVehicleProvider (providers.dart) lekéri az ÖSSZES szervizt az adatbázisból.

FONTOS: A providerben NEM SZABAD SZŰRNI az adatokat (pl. .where), mert akkor a MaintenanceReminderView nem kapja meg a számoláshoz szükséges alapértékeket. A szűrést csak a UI rétegben (ServiceListView) végezzük.

3. Jármű ID vs Rendszám

A Firestore-ban a jármű dokumentum ID-ja maga a RENDSZÁM (tisztítva, ékezetek nélkül).

A firestore_service.dart-ban az upsertService metódus paraméterei között van egy vehicleNumericId. Ez egy örökölt tulajdonság a régi SQL logikából, de a Firestore-ban jelenleg kevésbé releváns, általában 0-át adunk át neki, vagy a szinkronizáció miatt generálunk egy számot.

4. Firestore Adatbázis Struktúra
code
Text
download
content_copy
expand_less
users/
  └── {uid}/
      └── vehicles/
          └── {licensePlate}/  <-- Dokumentum ID a rendszám!
              ├── fields: make, model, year, mileage, customIntervals (Map)
              └── services/    <-- Subcollection
                  └── {serviceId}/
                      ├── description: "Olajcsere" vagy "Emlékeztető alap: Olajcsere"
                      ├── date: Timestamp
                      ├── mileage: number
                      ├── cost: number
🚀 Fejlesztési Irányelvek (AI-nak)

Szerviz Hozzáadás: Ha új szervizt adsz hozzá, mindig használd a FirestoreService.upsertService metódust.

Emlékeztető Számítás: Ha módosítod a MaintenanceReminderView-t, mindig vedd figyelembe a customIntervals mezőt a Jármű objektumban (egyedi intervallumok kezelése).

Mobil Szinkron: Az alkalmazás kompatibilis a mobil verzióval, ezért az adatbázis sémát (field neveket) TILOS megváltoztatni anélkül, hogy a mobil appot is frissítenénk.

UI: Webes felület lévén figyelj a reszponzivitásra (Split View: balra lista, jobbra részletek).

Használat:
Ha legközelebb feladatot adsz az AI-nak, írd be a promptba:
"Flutter fejlesztés. A projekt struktúrája és működése a csatolt README.md alapján értelmezendő. A feladat a következő: ..."