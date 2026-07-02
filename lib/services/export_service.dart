import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/models/trip.dart';
import '../data/models/vehicle.dart';

class ExportService {
  ExportService._();

  static final _datumsFormat = DateFormat('dd.MM.yyyy');
  static final _zeitFormat = DateFormat('HH:mm');
  static final _kmFormat = NumberFormat('#,##0.0', 'de_DE');

  /// Entfernt Zeichen, die in Dateinamen Probleme machen (z.B. "/").
  static String _dateinameSicher(String s) =>
      s.replaceAll(RegExp(r'[^\w\-.]'), '_');

  /// Erstellt eine CSV-Datei mit Fahrtdaten.
  /// Semikolon als Trennzeichen (deutscher Excel-Standard).
  static Future<File> csvErstellen(
    Vehicle vehicle,
    List<Trip> fahrten,
    DateTime von,
    DateTime bis,
  ) async {
    final header = [
      'Datum',
      'Startzeit',
      'Endzeit',
      'Distanz (km)',
      'Fahrttyp',
      'Startort',
      'Zielort',
      'Erfassung',
    ];

    final rows = <List<String>>[header];
    double gesamtKm = 0.0;
    double privatKm = 0.0;
    double firmenKm = 0.0;

    for (final fahrt in fahrten) {
      gesamtKm += fahrt.distanceKm;
      if (fahrt.istFirmenfahrt) {
        firmenKm += fahrt.distanceKm;
      } else {
        privatKm += fahrt.distanceKm;
      }
      rows.add([
        _datumsFormat.format(fahrt.startTimestamp),
        _zeitFormat.format(fahrt.startTimestamp),
        fahrt.endTimestamp != null ? _zeitFormat.format(fahrt.endTimestamp!) : '',
        _kmFormat.format(fahrt.distanceKm),
        fahrt.istFirmenfahrt ? 'Firma' : 'Privat',
        fahrt.startOrt ?? '',
        fahrt.endOrt ?? '',
        fahrt.manuellErfasst ? 'Manuell' : 'GPS',
      ]);
    }

    rows.add([]);
    rows.add([
      'Gesamtkilometer', '', '', _kmFormat.format(gesamtKm), '', '', '', ''
    ]);
    rows.add([
      'davon Privatfahrten', '', '', _kmFormat.format(privatKm), '', '', '', ''
    ]);
    rows.add([
      'davon Firmenfahrten', '', '', _kmFormat.format(firmenKm), '', '', '', ''
    ]);

    final csvString = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
    ).convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Fahrtenbuch_${_dateinameSicher(vehicle.kennzeichen)}_'
        '${_datumsFormat.format(von)}-${_datumsFormat.format(bis)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString('﻿$csvString', encoding: utf8);

    return file;
  }

  /// Erstellt ein PDF-Dokument mit Fahrtenbuch.
  static Future<File> pdfErstellen(
    Vehicle vehicle,
    List<Trip> fahrten,
    DateTime von,
    DateTime bis,
  ) async {
    final pdf = pw.Document();
    double gesamtKm = 0.0;
    double privatKm = 0.0;
    double firmenKm = 0.0;
    for (final f in fahrten) {
      gesamtKm += f.distanceKm;
      if (f.istFirmenfahrt) {
        firmenKm += f.distanceKm;
      } else {
        privatKm += f.distanceKm;
      }
    }

    final zeitraumText =
        '${_datumsFormat.format(von)} bis ${_datumsFormat.format(bis)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Fahrtenbuch',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${vehicle.name} (${vehicle.kennzeichen})',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Zeitraum: $zeitraumText',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Oldtimer KM-Log',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Seite ${context.pageNumber} von ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Datum', 'Start', 'Ende', 'km', 'Typ', 'Von', 'Nach'],
            data: fahrten.map((f) => [
              _datumsFormat.format(f.startTimestamp),
              _zeitFormat.format(f.startTimestamp),
              f.endTimestamp != null ? _zeitFormat.format(f.endTimestamp!) : '-',
              _kmFormat.format(f.distanceKm),
              f.istFirmenfahrt ? 'Firma' : 'Privat',
              f.startOrt ?? '-',
              f.endOrt ?? '-',
            ]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Gesamtkilometer: ${_kmFormat.format(gesamtKm)} km',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'davon Privatfahrten: ${_kmFormat.format(privatKm)} km · '
                'davon Firmenfahrten: ${_kmFormat.format(firmenKm)} km',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Anzahl Fahrten: ${fahrten.length}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Fahrtenbuch_${_dateinameSicher(vehicle.kennzeichen)}_'
        '${_datumsFormat.format(von)}-${_datumsFormat.format(bis)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Teilt eine Datei über das System-Share-Sheet.
  static Future<void> teilen(File datei) async {
    await Share.shareXFiles([XFile(datei.path)]);
  }
}
