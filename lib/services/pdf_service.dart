// lib/services/pdf_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/services/statistics_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  final StatisticsService _statsService = StatisticsService();

  Future<void> generateAndDownloadPdf(Jarmu vehicle, List<Szerviz> allServices) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    final dateFormat = DateFormat('yyyy. MM. dd.');
    
    // 1. SZŰRÉS: Kivesszük a tankolásokat a listából
    final services = allServices.where((s) => !s.description.toLowerCase().contains('tankolás')).toList();

    // Szervizek rendezése
    services.sort((a, b) => b.date.compareTo(a.date));

    // Statisztikák számítása (Ezeknél maradhat az összes adat, vagy itt is szűrhetünk igény szerint)
    // A Total Cost-ba a tankolásokat most nem számoljuk bele a PDF-en, hogy konzisztens legyen a listával
    final totalCost = _statsService.calculateTotalCost(services);
    
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
        ),
        header: (context) => _buildHeader(vehicle),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildVehicleInfo(vehicle, numberFormat),
          pw.SizedBox(height: 20),
          _buildSummary(totalCost, services.length, numberFormat),
          pw.SizedBox(height: 30),
          pw.Text('Részletes Szerviztörténet (Tankolások nélkül)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
          pw.Divider(color: PdfColors.orange),
          pw.SizedBox(height: 10),
          _buildServiceTable(services, dateFormat, numberFormat),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'szerviznaplo_${vehicle.licensePlate}.pdf');
  }

  pw.Widget _buildHeader(Jarmu vehicle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('OLAJFOLT SZERVIZNAPLÓ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
            pw.Text(DateFormat('yyyy. MM. dd.').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.grey)),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Készült az Olajfolt alkalmazással', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.Text('Oldal ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVehicleInfo(Jarmu vehicle, NumberFormat nf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Rendszám', vehicle.licensePlate, isBold: true),
                pw.SizedBox(height: 8),
                _buildInfoRow('Gyártmány', vehicle.make),
                pw.SizedBox(height: 8),
                _buildInfoRow('Modell', vehicle.model),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Évjárat', vehicle.year.toString()),
                pw.SizedBox(height: 8),
                _buildInfoRow('Alvázszám', vehicle.vin ?? '-'),
                pw.SizedBox(height: 8),
                _buildInfoRow('Futásteljesítmény', '${nf.format(vehicle.mileage)} km'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$label:', style: pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 12)),
      ],
    );
  }

  pw.Widget _buildSummary(double totalCost, int count, NumberFormat nf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Összesen $count bejegyzés', style: const pw.TextStyle(fontSize: 14)),
        pw.Text('Összes költség: ${nf.format(totalCost)} Ft', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
      ],
    );
  }

  pw.Widget _buildServiceTable(List<Szerviz> services, DateFormat df, NumberFormat nf) {
    return pw.TableHelper.fromTextArray(
      headers: ['Dátum', 'Leírás', 'Km óra', 'Költség'],
      data: services.map((s) => [
        df.format(s.date),
        s.description,
        '${nf.format(s.mileage)} km',
        s.cost > 0 ? '${nf.format(s.cost)} Ft' : '-',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    );
  }
}
