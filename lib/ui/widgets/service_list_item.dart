// lib/ui/widgets/service_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

enum ServiceAction { edit, delete }

class ServiceListItem extends StatelessWidget {
  final Szerviz service;
  final Function(Szerviz) onEdit;
  final Function(Szerviz) onDelete;

  const ServiceListItem({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy. MM. dd.');
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    // Ikon kiválasztása a típus alapján
    IconData typeIcon = Icons.build_circle;
    Color typeColor = Colors.grey;

    if (service.description.toLowerCase().contains('tankolás')) {
      typeIcon = Icons.local_gas_station;
      typeColor = Colors.orange;
    } else if (service.description.toLowerCase().contains('olaj')) {
      typeIcon = Icons.oil_barrel;
      typeColor = Colors.black87;
    } else if (service.description.toLowerCase().contains('műszaki')) {
      typeIcon = Icons.verified;
      typeColor = Colors.blue;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Típusjelző ikon (Modern stílus)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.description,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(context, Icons.calendar_month, dateFormat.format(service.date), Colors.blueGrey),
                      _buildInfoChip(context, Icons.speed, '${numberFormat.format(service.mileage)} km', Colors.orange),
                      _buildInfoChip(context, Icons.payments, '${numberFormat.format(service.cost)} Ft', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            
            PopupMenuButton<ServiceAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == ServiceAction.edit) {
                  onEdit(service);
                } else if (action == ServiceAction.delete) {
                  onDelete(service);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: ServiceAction.edit,
                  child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Szerkesztés')]),
                ),
                const PopupMenuItem(
                  value: ServiceAction.delete,
                  child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Törlés', style: TextStyle(color: Colors.red))]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
