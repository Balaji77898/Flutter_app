import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../contexts/auth_provider.dart';
import '../contexts/orders_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../../core/currency_utils.dart';

class BillScreen extends StatelessWidget {
  final String orderId;
  final int tipAmount;
  final int finalTotal;
  final String paymentMethod;

  const BillScreen({
    super.key,
    required this.orderId,
    required this.tipAmount,
    required this.finalTotal,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final auth = context.read<StaffAuthProvider>();
    final order = provider.findById(orderId);
    final billNumber =
        'BILL-${orderId.substring(0, orderId.length < 8 ? orderId.length : 8).toUpperCase()}';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Receipt card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.slate100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top accent bar
                        Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              // Success Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Payment Successful',
                                style: AppTheme.serif(
                                  size: 24,
                                  weight: FontWeight.w900,
                                  color: AppColors.slate900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transaction Completed',
                                style: AppTheme.sans(
                                  size: 14,
                                  color: AppColors.slate500,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Receipt details
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.slate100),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Amount',
                                          style: AppTheme.sans(
                                            size: 12,
                                            weight: FontWeight.w700,
                                            color: AppColors.slate500,
                                          ),
                                        ),
                                        Text(
                                          '₹$finalTotal',
                                          style: AppTheme.serif(
                                            size: 32,
                                            weight: FontWeight.w900,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: AppColors.slate200,
                                        height: 1,
                                      ),
                                    ),
                                    _ReceiptRow(
                                      'Bill Number',
                                      billNumber,
                                      mono: true,
                                    ),
                                    const SizedBox(height: 10),
                                    if (order != null) ...[
                                      _ReceiptRow('Table', order.table),
                                      if (order.customerName != null) ...[
                                        const SizedBox(height: 10),
                                        _ReceiptRow(
                                          'Customer',
                                          order.customerName!,
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 10),
                                    _ReceiptRow('Date', _formatDate()),
                                    const SizedBox(height: 10),
                                    _ReceiptRow(
                                      'Payment Method',
                                      paymentMethod.toUpperCase(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Breakdown
                              if (order != null) ...[
                                const _SectionHeader('Order Items'),
                                const SizedBox(height: 10),
                                ...order.itemsDetails.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.quantity}x ${item.name}',
                                          style: AppTheme.sans(
                                            size: 13,
                                            color: AppColors.slate600,
                                          ),
                                        ),
                                        Text(
                                          '₹${(item.quantity * (double.tryParse(item.price) ?? 0)).round()}',
                                          style: AppTheme.sans(
                                            size: 13,
                                            weight: FontWeight.w600,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 20),
                                if (order.subtotal > 0) ...[
                                  _BreakdownRow(
                                    'Subtotal',
                                    '₹${order.subtotal.round()}',
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (order.tax > 0) ...[
                                  _BreakdownRow('Tax', '₹${order.tax.round()}'),
                                  const SizedBox(height: 6),
                                ],
                                _BreakdownRow('Tip', '₹$tipAmount'),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Paid',
                                      style: AppTheme.sans(
                                        size: 16,
                                        weight: FontWeight.w800,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    Text(
                                      '₹$finalTotal',
                                      style: AppTheme.sans(
                                        size: 20,
                                        weight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Action buttons
                              PrimaryButton(
                                label: 'Print Receipt',
                                icon: Icons.print_rounded,
                                onTap: () => _printReceiptPdf(
                                  context,
                                  order,
                                  billNumber,
                                ),
                              ),
                              const SizedBox(height: 12),
                              PrimaryButton(
                                label: 'Download as PDF',
                                icon: Icons.picture_as_pdf_rounded,
                                color: AppColors.slate900,
                                onTap: () => _downloadReceiptPdf(
                                  context,
                                  order,
                                  billNumber,
                                ),
                              ),
                              const SizedBox(height: 12),
                              PremiumBackButton(
                                label: auth.role == StaffRole.billingStaff
                                    ? 'Back to Billing'
                                    : 'Back to Dashboard',
                                onTap: () => auth.role == StaffRole.billingStaff
                                    ? context.go('/staff/billing')
                                    : context.go('/staff/dashboard'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generatePdfDoc(
    BuildContext context,
    dynamic order,
    String billNumber,
  ) async {
    final restaurantName =
        context.read<StaffAuthProvider>().user?.restaurantName;
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();

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
                      'Payment Receipt',
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
              if (order != null) ...[
                _pdfInfoRow('Table', order.table, font, boldFont),
                if (order.customerName != null)
                  _pdfInfoRow('Customer', order.customerName!, font, boldFont),
              ],
              _pdfInfoRow('Date', _formatDate(), font, boldFont),
              _pdfInfoRow(
                'Payment Method',
                paymentMethod.toUpperCase(),
                font,
                boldFont,
              ),

              pw.SizedBox(height: 16),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 16),

              // Order items header
              if (order != null) ...[
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
                              fontWeight: pw.FontWeight.bold,
                              font: boldFont,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              font: boldFont,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              font: boldFont,
                            ),
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
                            child: pw.Text(
                              item.name,
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${item.quantity}',
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              CurrencyUtils.format(
                                (item.quantity *
                                        (double.tryParse(item.price) ?? 0))
                                    .round(),
                              ),
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
                    boldFont,
                  ),
                if (order.tax > 0)
                  _pdfInfoRow(
                    'Tax',
                    CurrencyUtils.format(order.tax.round()),
                    font,
                    boldFont,
                  ),
                if (tipAmount > 0)
                  _pdfInfoRow(
                    'Tip',
                    CurrencyUtils.format(tipAmount),
                    font,
                    boldFont,
                  ),
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
                      CurrencyUtils.format(finalTotal),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 30),
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

  Future<void> _printReceiptPdf(
    BuildContext context,
    dynamic order,
    String billNumber,
  ) async {
    final pdf = await _generatePdfDoc(context, order, billNumber);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_$billNumber',
    );
  }

  Future<void> _downloadReceiptPdf(
    BuildContext context,
    dynamic order,
    String billNumber,
  ) async {
    final pdf = await _generatePdfDoc(context, order, billNumber);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Receipt_$billNumber.pdf',
    );
  }

  pw.Widget _pdfInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, font: font)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day} ${_month(now.month)} ${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  String _month(int m) {
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _ReceiptRow(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans(size: 13, color: AppColors.slate600)),
        Text(
          value,
          style: mono
              ? const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                )
              : AppTheme.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTheme.sans(
          size: 11,
          weight: FontWeight.w800,
          color: AppColors.slate500,
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakdownRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans(size: 13, color: AppColors.slate500)),
        Text(
          value,
          style: AppTheme.sans(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}
