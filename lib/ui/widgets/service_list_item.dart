// lib/ui/widgets/service_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

enum ServiceAction { edit, delete }

class ServiceListItem extends StatelessWidget {
  final Szerviz service;
  final Function(Szerviz) onEdit;
  final Function(Szerviz) onDelete;
  final bool isRefueling; // ÚJ PARAMÉTER

  const ServiceListItem({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    this.isRefueling = false, // Alapértelmezetten false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy. MM. dd.');
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    IconData typeIcon = Icons.build_circle;
    Color typeColor = Colors.grey;

    final descLower = service.description.toLowerCase();
    
    // Ha explicit tankolás, vagy a leírásban benne van
    if (isRefueling || descLower.contains('tankolás')) {
      typeIcon = Icons.local_gas_station;
      typeColor = Colors.green; // Zöld szín a tankoláshoz a fülhöz igazodva
    } else if (descLower.contains('olaj')) {
      typeIcon = Icons.oil_barrel;
      typeColor = Colors.black87;
    } else if (descLower.contains('műszaki')) {
      typeIcon = Icons.verified;
      typeColor = Colors.blue;
    } else if (descLower.contains('biztosítás') || descLower.contains('casco')) {
      typeIcon = Icons.security;
      typeColor = Colors.teal;
    } else if (descLower.contains('matrica')) {
      typeIcon = Icons.confirmation_number;
      typeColor = Colors.purple;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FEJLÉC: Ikon és Dátum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                // Menü gomb
                SizedBox(
                  width: 30,
                  height: 30,
                  child: PopupMenuButton<ServiceAction>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    onSelected: (action) {
                      if (action == ServiceAction.edit) onEdit(service);
                      else if (action == ServiceAction.delete) onDelete(service);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: ServiceAction.edit, child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Szerkesztés')])),
                      const PopupMenuItem(value: ServiceAction.delete, child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Törlés', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // TARTALOM: Leírás
            Expanded(
              child: Text(
                service.description,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            const Divider(),
            
            // LÁBLÉC: Adatok
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(service.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                if (service.mileage > 0)
                Row(
                  children: [
                    const Icon(Icons.speed, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${numberFormat.format(service.mileage)} km', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if (service.cost > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.payments, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('${numberFormat.format(service.cost)} Ft', style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
