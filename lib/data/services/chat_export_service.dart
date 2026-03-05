import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'ai_assistant_service.dart';

class ChatExportService {
  static final ChatExportService _instance = ChatExportService._internal();
  factory ChatExportService() => _instance;
  ChatExportService._internal();

  /// Export chat as plain text and share
  Future<void> exportAndShareText({
    required List<ChatMessage> messages,
    required DateTime sessionTime,
  }) async {
    final text = _buildTextContent(messages, sessionTime);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/fin_chat_${sessionTime.millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(text);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Lịch sử tư vấn tài chính từ Fin');
  }

  /// Export chat as PDF and share
  Future<void> exportAndSharePdf({
    required List<ChatMessage> messages,
    required DateTime sessionTime,
  }) async {
    final pdf = pw.Document();

    // Try to load a font that supports Vietnamese.
    // If you don't have a bundled ttf, you might need to use standard fonts,
    // but PDF standard fonts often lack full VN accents. Wait, we can use built in fonts for now
    // and replace with a TTF later if needed. For safety, we use Helvetica.

    // We can just add a simple multi-page layout
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Lịch sử tư vấn tài chính - Fin AI'),
            ),
            pw.Paragraph(
              text:
                  'Ngày: ${sessionTime.day}/${sessionTime.month}/${sessionTime.year} ${sessionTime.hour}:${sessionTime.minute}',
            ),
            pw.SizedBox(height: 20),
            ...messages.map((m) {
              final sender = m.isUser ? 'Bạn' : 'Fin 🤖';
              final alignment = m.isUser
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start;
              final color = m.isUser ? PdfColors.blue100 : PdfColors.grey200;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: alignment,
                  children: [
                    pw.Text(
                      sender,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(m.text),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/fin_chat_${sessionTime.millisecondsSinceEpoch}.pdf',
    );
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Lịch sử tư vấn tài chính từ Fin');
  }

  String _buildTextContent(List<ChatMessage> messages, DateTime sessionTime) {
    final buffer = StringBuffer();
    buffer.writeln('=== LỊCH SỬ CHAT VỚI TRỢ LÝ TÀI CHÍNH FIN ===');
    buffer.writeln(
      'Ngày: ${sessionTime.day}/${sessionTime.month}/${sessionTime.year} ${sessionTime.hour}:${sessionTime.minute}',
    );
    buffer.writeln('--------------------------------------------------\n');

    for (final m in messages) {
      final sender = m.isUser ? 'Bạn' : 'Fin 🤖';
      buffer.writeln('[$sender]:');
      buffer.writeln(m.text);
      if (m.actions.isNotEmpty) {
        final actionLabels = m.actions
            .where((a) => a != AiAction.none)
            .map((a) => a.label)
            .join(', ');
        if (actionLabels.isNotEmpty) {
          buffer.writeln('(Gợi ý hành động: $actionLabels)');
        }
      }
      buffer.writeln('\n--------------------------------------------------\n');
    }

    return buffer.toString();
  }
}
