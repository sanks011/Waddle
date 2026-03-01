import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/activity_session.dart';

/// Time range filter for PDF exports.
enum ExportRange { week, month, year }

/// Generates and shares a branded PDF report of health & fitness data.
class PdfExportService {
  PdfExportService._();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates a branded PDF with the given data and opens the share sheet.
  static Future<void> exportAndShare({
    required String username,
    required ExportRange range,
    required List<ActivitySession> sessions,
    required int waterGoalMl,
    required int waterConsumedMl,
    required int calorieGoal,
  }) async {
    final pdf = pw.Document();

    // Load app icon as logo
    pw.MemoryImage? logo;
    try {
      final iconData = await rootBundle.load('assets/penguin.png');
      logo = pw.MemoryImage(iconData.buffer.asUint8List());
    } catch (_) {}

    // Date calculations
    final now = DateTime.now();
    final DateFormat dateFmt = DateFormat('MMM d, yyyy');
    final DateFormat dayFmt = DateFormat('EEE, MMM d');
    final DateFormat timeFmt = DateFormat('h:mm a');
    final DateTime rangeStart;
    final String rangeLabel;

    switch (range) {
      case ExportRange.week:
        rangeStart = now.subtract(const Duration(days: 7));
        rangeLabel = 'Past 1 Week';
        break;
      case ExportRange.month:
        rangeStart = now.subtract(const Duration(days: 30));
        rangeLabel = 'Past 1 Month';
        break;
      case ExportRange.year:
        rangeStart = now.subtract(const Duration(days: 365));
        rangeLabel = 'Past 1 Year';
        break;
    }

    // Filter sessions
    final filteredSessions = sessions
        .where((s) =>
            s.isCompleted &&
            s.endTime != null &&
            s.endTime!.isAfter(rangeStart))
        .toList()
      ..sort((a, b) => b.endTime!.compareTo(a.endTime!));

    // Aggregate stats
    double totalDistance = 0;
    double totalMinutes = 0;
    double totalCalories = 0;
    for (final s in filteredSessions) {
      totalDistance += s.distance;
      final mins = s.endTime!.difference(s.startTime).inMinutes.toDouble();
      totalMinutes += mins;
      final estimatedSteps = s.distance / 0.762;
      totalCalories += estimatedSteps * 0.04;
    }

    // ── Theme Colors ────────────────────────────────────────────────────────
    const brandPurple = PdfColor.fromInt(0xFF7B2FBE);
    const headerBg = PdfColor.fromInt(0xFF1A1A2E);
    const white = PdfColors.white;
    const lightGray = PdfColor.fromInt(0xFFF5F5F5);
    const darkText = PdfColor.fromInt(0xFF222222);
    const mutedText = PdfColor.fromInt(0xFF666666);

    // ── Build PDF ───────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(logo, username, rangeLabel, dateFmt.format(now), brandPurple, headerBg, white),
        footer: (context) => _buildFooter(context, brandPurple, mutedText),
        build: (context) => [
          pw.SizedBox(height: 20),

          // ── Summary Cards ────────────────────────────────────────────────
          _sectionTitle('Summary', brandPurple),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statCard('Sessions', '${filteredSessions.length}', brandPurple, lightGray),
              _statCard('Distance', '${(totalDistance / 1000).toStringAsFixed(2)} km', brandPurple, lightGray),
              _statCard('Exercise', '${totalMinutes.round()} min', brandPurple, lightGray),
              _statCard('Calories', '${totalCalories.round()} kcal', brandPurple, lightGray),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _statCard('Water Goal', '${waterGoalMl} ml/day', brandPurple, lightGray),
              pw.SizedBox(width: 8),
              _statCard('Water Today', '${waterConsumedMl} ml', brandPurple, lightGray),
              pw.SizedBox(width: 8),
              _statCard('Calorie Goal', '${calorieGoal} kcal/day', brandPurple, lightGray),
              pw.Spacer(),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Session Log ──────────────────────────────────────────────────
          _sectionTitle('Activity Log ($rangeLabel)', brandPurple),
          pw.SizedBox(height: 10),

          if (filteredSessions.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Center(
                child: pw.Text(
                  'No completed sessions in this period.',
                  style: pw.TextStyle(color: mutedText, fontSize: 12),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: white,
              ),
              headerDecoration: const pw.BoxDecoration(color: headerBg),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9, color: darkText),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Date', 'Time', 'Distance', 'Duration', 'Calories'],
              data: filteredSessions.map((s) {
                final mins = s.endTime!.difference(s.startTime).inMinutes;
                final steps = s.distance / 0.762;
                final kcal = (steps * 0.04).round();
                return [
                  dayFmt.format(s.endTime!),
                  timeFmt.format(s.startTime),
                  '${(s.distance / 1000).toStringAsFixed(2)} km',
                  '${mins}m',
                  '$kcal kcal',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 30),

          // ── Disclaimer ──────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'This report is generated by Waddle. '
              'Calorie estimates are based on step calculations from GPS distance '
              'and may vary from actual values. Consult a health professional for '
              'precise health metrics.',
              style: pw.TextStyle(fontSize: 8, color: mutedText, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    // ── Save & Share ────────────────────────────────────────────────────────
    final dir = await getTemporaryDirectory();
    final rangeSuffix = range.name;
    final fileName = 'BhagoPro_Health_${rangeSuffix}_${DateFormat('yyyyMMdd').format(now)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Waddle Health Report — $rangeLabel',
      ),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    String username,
    String rangeLabel,
    String dateStr,
    PdfColor brandPurple,
    PdfColor headerBg,
    PdfColor white,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: pw.BoxDecoration(
        color: headerBg,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          if (logo != null) ...[
            pw.Image(logo, width: 36, height: 36),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Waddle',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Health & Fitness Report',
                  style: pw.TextStyle(fontSize: 11, color: brandPurple),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                username,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '$rangeLabel  •  $dateStr',
                style: pw.TextStyle(fontSize: 9, color: brandPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor brand, PdfColor muted) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Waddle',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
        ],
      ),
    );
  }

  static pw.Expanded _statCard(String label, String value, PdfColor accent, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
