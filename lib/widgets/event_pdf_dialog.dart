import 'package:flutter/material.dart';
import '../models/models.dart';
import 'report_export_dialog.dart';
export 'report_export_dialog.dart';

class EventPdfExportDialog extends StatelessWidget {
  final PujaEvent event;

  const EventPdfExportDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ReportExportDialog(
      initialEvent: event,
      initialAllEvents: false,
    );
  }
}
