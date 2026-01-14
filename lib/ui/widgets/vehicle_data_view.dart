// lib/ui/widgets/vehicle_data_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';

class VehicleDataView extends StatelessWidget {
  final Jarmu vehicle;
  final VoidCallback onExportPdf; // Callback a PDF generáláshoz

  const VehicleDataView({
    super.key,
    required this.vehicle,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: 8,
                      margin: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Icon(Icons.directions_car_filled, size: 56, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              vehicle.licensePlate,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${vehicle.make} ${vehicle.model}',
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                            ),
                            
                            const Divider(height: 48, thickness: 1),

                            _buildDataRow(context, Icons.calendar_month, 'Évjárat', vehicle.year.toString(), Colors.blue),
                            _buildDataRow(context, Icons.speed, 'Futásteljesítmény', '${numberFormat.format(vehicle.mileage)} km', Colors.orange),
                            
                            _buildDataRow(
                              context, 
                              Icons.fingerprint, 
                              'Alvázszám (VIN)', 
                              (vehicle.vin != null && vehicle.vin!.isNotEmpty) ? vehicle.vin! : '-', 
                              Colors.purple
                            ),
                            
                            _buildDataRow(
                              context, 
                              Icons.settings, 
                              'Vezérlés típusa', 
                              (vehicle.vezerlesTipusa != null && vehicle.vezerlesTipusa!.isNotEmpty) ? vehicle.vezerlesTipusa! : '-', 
                              Colors.teal
                            ),

                            // ÚJ SOR: Rádió kód
                            _buildDataRow(
                              context, 
                              Icons.radio, 
                              'Rádió kód', 
                              (vehicle.radioCode != null && vehicle.radioCode!.isNotEmpty) ? vehicle.radioCode! : '-', 
                              Colors.redAccent
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // PDF EXPORT GOMB A KÁRTYA ALATT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: onExportPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 28),
                          label: const Text('TELJES JÁRMŰTÖRTÉNET (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700], // Piros szín a figyelemfelkeltéshez
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isPlaceholder = value == '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPlaceholder ? Colors.grey.withOpacity(0.5) : null,
            ),
          ),
        ],
      ),
    );
  }
}
