import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../../core/currency_utils.dart';

class PrintingUtils {
  static Future<pw.Document> _generateBillPdf(Order order,
      {String? restaurantName}) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();
    final billNumber =
        'BILL-${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName?.isNotEmpty == true
                          ? restaurantName!.toUpperCase()
                          : 'RESTAURANT',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Proforma Invoice / Bill',
                      style: pw.TextStyle(fontSize: 14, font: font),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(height: 2, color: PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Bill info
              _pdfInfoRow('Bill Number', billNumber, font, boldFont),
              _pdfInfoRow('Table', order.table, font, boldFont),
              if (order.customerName != null)
                _pdfInfoRow('Customer', order.customerName!, font, boldFont),
              _pdfInfoRow('Date', _formatDate(), font, boldFont),

              pw.SizedBox(height: 16),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 16),

              // Order items header
              pw.Text(
                'Order Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.SizedBox(height: 10),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: boldFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: boldFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: boldFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...order.itemsDetails.map<pw.TableRow>(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.name,
                              style: pw.TextStyle(font: font)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${item.quantity}',
                              style: pw.TextStyle(font: font)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            CurrencyUtils.format((item.quantity *
                                    (double.tryParse(item.price) ?? 0))
                                .round()),
                            style: pw.TextStyle(font: font),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Totals
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              if (order.subtotal > 0)
                _pdfInfoRow(
                    'Subtotal',
                    CurrencyUtils.format(order.subtotal.round()),
                    font,
                    boldFont),
              if (order.tax > 0)
                _pdfInfoRow('Tax', CurrencyUtils.format(order.tax.round()),
                    font, boldFont),
              pw.SizedBox(height: 6),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                  pw.Text(
                    CurrencyUtils.format(order.total.round()),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'This is a proforma bill. Please pay at the counter.',
                  style: pw.TextStyle(fontSize: 12, font: font),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for dining with us!',
                  style: pw.TextStyle(fontSize: 12, font: font),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> printOrderBill(Order order,
      {String? restaurantName}) async {
    final pdf = await _generateBillPdf(order, restaurantName: restaurantName);
    final billNumber =
        'BILL-${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bill_$billNumber',
    );
  }

  static Future<void> downloadOrderBillPdf(Order order,
      {String? restaurantName}) async {
    final pdf = await _generateBillPdf(order, restaurantName: restaurantName);
    final billNumber =
        'BILL-${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}';
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Bill_$billNumber.pdf',
    );
  }

  static pw.Widget _pdfInfoRow(
      String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, font: font)),
          pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
          ),
        ],
      ),
    );
  }

  static String _formatDate() {
    final now = DateTime.now();
    return '${now.day} ${_month(now.month)} ${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
