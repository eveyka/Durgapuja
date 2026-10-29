import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../services/r2_storage_service.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'glass_container.dart';
import 'event_and_donation_dialogs.dart';
export 'event_and_donation_dialogs.dart';
export 'collection_account_dialogs.dart';
export 'event_pdf_dialog.dart';
export 'report_export_dialog.dart';

// ==========================================
// 1. ADD CHANDA / BOOK COLLECTION DIALOG (Fast Daily Collection + Single Slip)
// ==========================================
class AddChandaSlipDialog extends StatefulWidget {
  final int initialMode; // 0: Daily Collection, 1: Single Slip
  final int? initialBookNumber;
  const AddChandaSlipDialog({super.key, this.initialMode = 0, this.initialBookNumber});

  @override
  State<AddChandaSlipDialog> createState() => _AddChandaSlipDialogState();
}

class _AddChandaSlipDialogState extends State<AddChandaSlipDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _entryMode; // 0: Daily Book Collection (Fast), 1: Single Donor Slip

  int? _selectedBook;

  // Mode 0: Daily Book Collection Fields
  String _selectedDay = 'Day 1';
  DateTime _selectedDate = DateTime.now();
  final _dailyAmountController = TextEditingController();
  final _slipsCountController = TextEditingController(text: '10');
  final _areaNotesController = TextEditingController();
  PaymentMode _dailyPaymentMode = PaymentMode.cash;

  // Mode 1: Single Slip Fields
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _slipNumberController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;
  String? _slipPhotoUrl;

  final List<String> _quickDays = [
    'Day 1',
    'Day 2',
    'Day 3',
    'Day 4',
    'Day 5',
    'Maha Saptami',
    'Maha Ashtami',
    'Maha Navami',
    'Bijoya Dashami',
  ];

  final List<int> _quickDailyAmounts = [2000, 5000, 10000, 20000, 50000];
  final List<int> _quickSingleAmounts = [251, 501, 1001, 2100, 5100];

  @override
  void initState() {
    super.initState();
    _entryMode = widget.initialMode;
    _selectedBook = widget.initialBookNumber;
  }

  @override
  void dispose() {
    _dailyAmountController.dispose();
    _slipsCountController.dispose();
    _areaNotesController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final books = provider.books;

    if (_selectedBook == null && books.isNotEmpty) {
      _selectedBook = books.first.bookNumber;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 560,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _entryMode == 0 ? Icons.collections_bookmark : Icons.receipt_long,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _entryMode == 0 ? 'Record Book Collection' : 'New Chanda Slip',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _entryMode == 0
                                      ? 'Direct Day-wise total collection entry'
                                      : 'Record individual donor & issue receipt',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mode Selector Toggle (Fast Daily Entry vs Single Slip)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _entryMode = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _entryMode == 0 ? AppTheme.primaryBlue.withAlpha(45) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _entryMode == 0 ? AppTheme.primaryBlue : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on,
                                    size: 14, color: _entryMode == 0 ? AppTheme.primaryBlue : Colors.white60),
                                const SizedBox(width: 5),
                                Text(
                                  'Daily / Book Total',
                                  style: TextStyle(
                                    color: _entryMode == 0 ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _entryMode = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _entryMode == 1 ? AppTheme.goldAccent.withAlpha(45) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _entryMode == 1 ? AppTheme.goldAccent : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 14, color: _entryMode == 1 ? AppTheme.goldAccent : Colors.white60),
                                const SizedBox(width: 5),
                                Text(
                                  'Single Slip Slip',
                                  style: TextStyle(
                                    color: _entryMode == 1 ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ==========================================
                // COMMON: Assigned Chanda Book
                // ==========================================
                _buildFieldLabel('Select Chanda Book *'),
                DropdownButtonFormField<int>(
                  initialValue: _selectedBook,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: _inputDecoration('Select Book', Icons.menu_book),
                  items: books.map((b) {
                    final remaining = b.totalSlips - b.usedSlips;
                    return DropdownMenuItem(
                      value: b.bookNumber,
                      child: Text(
                        'Book #${b.bookNumber} • ${b.assignedTo} (${b.usedSlips}/${b.totalSlips} used, $remaining left)',
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBook = val),
                  validator: (v) => v == null ? 'Please select a book' : null,
                ),
                const SizedBox(height: 14),

                // ==========================================
                // MODE 0: FAST DAILY BOOK COLLECTION
                // ==========================================
                if (_entryMode == 0) ...[
                  // Day Selection Chips
                  _buildFieldLabel('Collection Day / Milestone'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickDays.map((day) {
                        final isSelected = _selectedDay == day;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(day),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryBlue,
                            backgroundColor: const Color(0x1F1E293B),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorder,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF070D1E) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedDay = day);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount Field & Quick Chips
                  _buildFieldLabel('Day Collection Amount (₹) *'),
                  TextFormField(
                    controller: _dailyAmountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: _inputDecoration('e.g. 15000', Icons.currency_rupee),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Amount Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickDailyAmounts.map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: const Color(0x1F1E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            label: Text(
                              '₹$amt',
                              style: const TextStyle(
                                  color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              setState(() {
                                _dailyAmountController.text = amt.toString();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Slips used & Payment Mode
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Slips Cut / Used'),
                            TextFormField(
                              controller: _slipsCountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _inputDecoration('e.g. 15', Icons.tag),
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null) {
                                  return 'Invalid count';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Date'),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0x1F1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.glassBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(_selectedDate),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payment Mode
                  _buildFieldLabel('Payment Mode'),
                  Row(
                    children: [
                      _PaymentModeChip(
                        label: 'Cash',
                        icon: Icons.money,
                        selected: _dailyPaymentMode == PaymentMode.cash,
                        onTap: () => setState(() => _dailyPaymentMode = PaymentMode.cash),
                      ),
                      const SizedBox(width: 8),
                      _PaymentModeChip(
                        label: 'UPI / QR',
                        icon: Icons.qr_code_2,
                        selected: _dailyPaymentMode == PaymentMode.upi,
                        onTap: () => setState(() => _dailyPaymentMode = PaymentMode.upi),
                      ),
                      const SizedBox(width: 8),
                      _PaymentModeChip(
                        label: 'Bank Transfer',
                        icon: Icons.account_balance,
                        selected: _dailyPaymentMode == PaymentMode.bankTransfer,
                        onTap: () => setState(() => _dailyPaymentMode = PaymentMode.bankTransfer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Area / Remarks
                  _buildFieldLabel('Area / Collector Note (Optional)'),
                  TextFormField(
                    controller: _areaNotesController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('e.g. Market Shops / Station Road collection', Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 22),

                  // Submit Daily Collection Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() && _selectedBook != null) {
                          final assignedBook = books.firstWhere((b) => b.bookNumber == _selectedBook);
                          final slipsUsed = int.tryParse(_slipsCountController.text.trim()) ?? 1;
                          final amount = double.tryParse(_dailyAmountController.text.trim()) ?? 0.0;

                          provider.addBookDailyCollection(
                            bookNumber: _selectedBook!,
                            dayLabel: _selectedDay,
                            amount: amount,
                            slipsCount: slipsUsed,
                            paymentMode: _dailyPaymentMode,
                            collectedBy: assignedBook.assignedTo,
                            areaOrNotes: _areaNotesController.text.trim().isNotEmpty
                                ? _areaNotesController.text.trim()
                                : null,
                            customDate: _selectedDate,
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.successGreen,
                              content: Text(
                                '✅ Book #${_selectedBook!} $_selectedDay collection (₹${amount.toStringAsFixed(0)}) recorded!',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Book Collection',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // MODE 1: SINGLE DONOR SLIP (DETAILED)
                // ==========================================
                if (_entryMode == 1) ...[
                  // 1. SL / Slip Number (Customizable)
                  _buildFieldLabel('SL / Slip No. (Auto-suggested or set custom)'),
                  TextFormField(
                    controller: _slipNumberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: _inputDecoration('e.g. 1', Icons.confirmation_number_outlined),
                  ),
                  const SizedBox(height: 14),

                  // 2. Donor Name
                  _buildFieldLabel('Donor / Family / Shop Name *'),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('e.g. Subhash Banerjee & Family', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter donor name' : null,
                  ),
                  const SizedBox(height: 14),

                  // 3. Amount Field & Quick Chips
                  _buildFieldLabel('Collection Amount (₹) *'),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: _inputDecoration('e.g. 1001', Icons.currency_rupee),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Amount Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickSingleAmounts.map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: const Color(0x1F1E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            label: Text(
                              '₹$amt',
                              style: const TextStyle(
                                  color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              setState(() {
                                _amountController.text = amt.toString();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. WhatsApp / Phone Number
                  _buildFieldLabel('WhatsApp / Mobile Number (Optional)'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('e.g. 9876543210', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),

                  // 5. Payment Mode
                  _buildFieldLabel('Payment Mode'),
                  Row(
                    children: [
                      _PaymentModeChip(
                        label: 'Cash',
                        icon: Icons.money,
                        selected: _paymentMode == PaymentMode.cash,
                        onTap: () => setState(() => _paymentMode = PaymentMode.cash),
                      ),
                      const SizedBox(width: 8),
                      _PaymentModeChip(
                        label: 'UPI / QR',
                        icon: Icons.qr_code_2,
                        selected: _paymentMode == PaymentMode.upi,
                        onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                      ),
                      const SizedBox(width: 8),
                      _PaymentModeChip(
                        label: 'Bank Transfer',
                        icon: Icons.account_balance,
                        selected: _paymentMode == PaymentMode.bankTransfer,
                        onTap: () => setState(() => _paymentMode = PaymentMode.bankTransfer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Address / Notes
                  _buildFieldLabel('Flat / Address / Notes (Optional)'),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('e.g. Flat 3B, Sunshine Apartments', Icons.home_outlined),
                  ),
                  const SizedBox(height: 14),

                  // 7. Physical Slip Photo Attachment
                  _buildFieldLabel('Physical Slip / Receipt Photo (Optional)'),
                  _slipPhotoUrl != null
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.successGreen.withAlpha(90), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => BillImagePreviewDialog(
                                    imageUrl: _slipPhotoUrl!,
                                    title: _nameController.text.isNotEmpty ? _nameController.text : 'Chanda Slip',
                                    subtitle: 'Book #$_selectedBook',
                                    onDelete: () => setState(() => _slipPhotoUrl = null),
                                    onReplace: () => showAttachSlipModal(
                                      context,
                                      onUploaded: (url) => setState(() => _slipPhotoUrl = url),
                                      existingUrl: _slipPhotoUrl,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _slipPhotoUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.white10,
                                      child: const Icon(Icons.broken_image, color: Colors.white54),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Slip Photo Attached',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Compressed Full HD • Tap to view',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'View Full Slip',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => BillImagePreviewDialog(
                                      imageUrl: _slipPhotoUrl!,
                                      title: _nameController.text.isNotEmpty ? _nameController.text : 'Chanda Slip',
                                      subtitle: 'Book #$_selectedBook',
                                      onDelete: () => setState(() => _slipPhotoUrl = null),
                                      onReplace: () => showAttachSlipModal(
                                        context,
                                        onUploaded: (url) => setState(() => _slipPhotoUrl = url),
                                        existingUrl: _slipPhotoUrl,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                                    ),
                                    child: const Icon(Icons.zoom_in_rounded, color: AppTheme.primaryBlue, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Remove Slip Photo',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () async {
                                    final confirmed = await showConfirmDeleteImageDialog(
                                      context,
                                      title: 'Remove Attached Photo?',
                                      message: 'Are you sure you want to remove this slip photo?',
                                    );
                                    if (confirmed) {
                                      setState(() => _slipPhotoUrl = null);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dangerRose.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.dangerRose.withAlpha(80)),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => showAttachSlipModal(
                            context,
                            onUploaded: (url) => setState(() => _slipPhotoUrl = url),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Attach Paper Slip Photo',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Camera or Gallery • Auto-compressed for cloud',
                                        style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() && _selectedBook != null) {
                          final assignedBook = books.firstWhere((b) => b.bookNumber == _selectedBook);
                          final customSlip = int.tryParse(_slipNumberController.text.trim());
                          final createdSlip = provider.addChandaSlip(
                            bookNumber: _selectedBook!,
                            donorName: _nameController.text.trim(),
                            amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                            address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
                            paymentMode: _paymentMode,
                            collectedBy: assignedBook.assignedTo,
                            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                            slipPhotoUrl: _slipPhotoUrl,
                            customSlipNumber: customSlip,
                          );
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => SlipReceiptActionDialog(slip: createdSlip),
                          );
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save & Issue Digital Slip',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 2. ADD EXPENSE / KHARCHA DIALOG (Easy to use)
// ==========================================
class AddExpenseDialog extends StatefulWidget {
  final ExpenseVoucher? existing;
  final String? initialEventId;
  final String? initialAccountId;
  final String? initialAccountName;

  const AddExpenseDialog({
    super.key,
    this.existing,
    this.initialEventId,
    this.initialAccountId,
    this.initialAccountName,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payeeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.pandal;
  PaymentMode _paymentMode = PaymentMode.cash;
  String? _selectedEventId;
  String? _selectedAccountId;
  String? _selectedAccountName;
  DateTime _expenseDate = DateTime.now();
  String? _receiptPhotoUrl;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final exp = widget.existing;
    if (exp != null) {
      _payeeController.text = exp.payeeName;
      _amountController.text = exp.amount == exp.amount.roundToDouble()
          ? exp.amount.toStringAsFixed(0)
          : exp.amount.toString();
      _descController.text = exp.description ?? '';
      _selectedCategory = exp.category;
      _paymentMode = exp.paymentMode;
      _selectedEventId = exp.eventId;
      _selectedAccountId = exp.accountId;
      _selectedAccountName = exp.accountName;
      _expenseDate = exp.date;
      _receiptPhotoUrl = exp.receiptPhotoUrl;
    } else {
      _selectedEventId = widget.initialEventId;
      _selectedAccountId = widget.initialAccountId;
      _selectedAccountName = widget.initialAccountName;
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final effectiveEventId = widget.existing != null
        ? _selectedEventId
        : (_selectedEventId ?? widget.initialEventId ?? provider.selectedEvent?.id ?? (provider.events.isNotEmpty ? provider.events.first.id : null));
    if (_selectedEventId != effectiveEventId && effectiveEventId != null) {
      _selectedEventId = effectiveEventId;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 560,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRose.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppTheme.dangerRose,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing ? 'Edit Expense Voucher' : 'Record Expense Voucher',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _isEditing
                                      ? 'Update voucher #${widget.existing!.voucherNo}'
                                      : 'Record expenditure voucher & receipt',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withAlpha(20), height: 1),
                const SizedBox(height: 16),

                // Event / Festival Selector
                if (provider.events.isNotEmpty) ...[
                  _buildFieldLabel('Event / Festival *'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.events.any((e) => e.id == _selectedEventId)
                            ? _selectedEventId
                            : provider.events.first.id,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.dangerRose),
                        items: provider.events.map((evt) {
                          return DropdownMenuItem(
                            value: evt.id,
                            child: Row(
                              children: [
                                const Icon(Icons.festival_outlined, size: 16, color: AppTheme.dangerRose),
                                const SizedBox(width: 8),
                                Text(
                                  '${evt.name} (${evt.year})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEventId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Expenditure Account Selector (Optional / Linked)
                if (provider.expenditureAccounts.isNotEmpty) ...[
                  _buildFieldLabel('Expenditure A/C (Head / Department)'),
                  DropdownButtonFormField<String?>(
                    initialValue: provider.expenditureAccounts.any((a) => a.id == _selectedAccountId)
                        ? _selectedAccountId
                        : null,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    decoration: _inputDecoration('Select Expenditure A/C (Optional)', Icons.account_balance_wallet_outlined),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None / General Expenditure', style: TextStyle(fontSize: 13, color: Colors.white54)),
                      ),
                      ...provider.expenditureAccounts.map((acc) {
                        return DropdownMenuItem<String?>(
                          value: acc.id,
                          child: Row(
                            children: [
                              const Icon(Icons.folder_outlined, size: 16, color: AppTheme.dangerRose),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${acc.accountName} (${acc.category.displayName})',
                                  style: const TextStyle(fontSize: 13, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedAccountId = val;
                        if (val != null) {
                          final match = provider.expenditureAccounts.firstWhere((a) => a.id == val);
                          _selectedAccountName = match.accountName;
                          _selectedCategory = match.category;
                        } else {
                          _selectedAccountName = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Category Selector
                _buildFieldLabel('Expense Category *'),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: _inputDecoration('Expense Category', Icons.category_outlined),
                  items: ExpenseCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 10),
                          Text(cat.displayName, style: const TextStyle(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Payee / Vendor Name
                _buildFieldLabel('Payee / Vendor / Contractor Name *'),
                TextFormField(
                  controller: _payeeController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. New Bengal Decorators', Icons.store_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter payee name' : null,
                ),
                const SizedBox(height: 14),

                // Amount
                _buildFieldLabel('Expense Amount (₹) *'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration('e.g. 25000', Icons.currency_rupee),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Bill / Voucher Description
                _buildFieldLabel('Description / Purpose'),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. Advance payment for sound system', Icons.description_outlined),
                ),
                const SizedBox(height: 14),

                // Payment Mode
                _buildFieldLabel('Paid Via'),
                Row(
                  children: [
                    _PaymentModeChip(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: _paymentMode == PaymentMode.cash,
                      onTap: () => setState(() => _paymentMode = PaymentMode.cash),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'UPI / QR',
                      icon: Icons.qr_code_2,
                      selected: _paymentMode == PaymentMode.upi,
                      onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'Bank Transfer',
                      icon: Icons.account_balance,
                      selected: _paymentMode == PaymentMode.bankTransfer,
                      onTap: () => setState(() => _paymentMode = PaymentMode.bankTransfer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bill / Receipt Photo Attachment Section
                _buildFieldLabel('Bill / Invoice Photo (Optional)'),
                _receiptPhotoUrl != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.successGreen.withAlpha(90), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: _payeeController.text.isNotEmpty ? _payeeController.text : 'Bill Receipt',
                                  subtitle: 'Attached Receipt',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _receiptPhotoUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image, color: Colors.white54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bill Attached',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Saved securely • Tap to view',
                                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'View Full Bill',
                              icon: const Icon(Icons.zoom_in_rounded, color: AppTheme.primaryBlue, size: 20),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: _payeeController.text.isNotEmpty ? _payeeController.text : 'Bill Receipt',
                                  subtitle: 'Attached Receipt',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove Bill',
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 20),
                              onPressed: () => setState(() => _receiptPhotoUrl = null),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => showAttachBillModal(
                          context,
                          onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attach Bill / Invoice Photo',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Take photo or choose from gallery',
                                      style: TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final description = _descController.text.trim().isNotEmpty ? _descController.text.trim() : null;
                        final targetEvt = _selectedEventId ?? provider.selectedEvent?.id ?? (provider.events.isNotEmpty ? provider.events.first.id : null);
                        if (_isEditing) {
                          provider.updateExpense(
                            expenseId: widget.existing!.id,
                            payeeName: _payeeController.text.trim(),
                            category: _selectedCategory,
                            amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                            paymentMode: _paymentMode,
                            paidBy: widget.existing!.paidBy,
                            description: description,
                            eventId: targetEvt,
                            accountId: _selectedAccountId,
                            accountName: _selectedAccountName,
                            date: _expenseDate,
                            receiptPhotoUrl: _receiptPhotoUrl,
                            clearReceiptPhoto: _receiptPhotoUrl == null,
                          );
                        } else {
                          provider.addExpense(
                            payeeName: _payeeController.text.trim(),
                            category: _selectedCategory,
                            amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                            paymentMode: _paymentMode,
                            paidBy: provider.cashierName,
                            description: description,
                            eventId: targetEvt,
                            accountId: _selectedAccountId,
                            accountName: _selectedAccountName,
                            date: _expenseDate,
                            receiptPhotoUrl: _receiptPhotoUrl,
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content: Text(
                              _isEditing ? '✅ Voucher updated successfully!' : '✅ Expense voucher saved successfully!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isEditing ? Icons.save_outlined : Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'Update Voucher' : 'Save Expense Voucher',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.dangerRose, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.dangerRose, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 3. ISSUE NEW CHANDA BOOK DIALOG (Easy to use)
// ==========================================
class AddBookDialog extends StatefulWidget {
  final ChandaBook? existing;
  const AddBookDialog({super.key, this.existing});

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bookNoController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _startSlipController = TextEditingController();
  final _endSlipController = TextEditingController();

  int _slipCountPreset = 100; // 50, 100, or -1 for custom

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final b = widget.existing!;
      _bookNoController.text = b.bookNumber.toString();
      _assigneeController.text = b.assignedTo;
      _phoneController.text = b.collectorPhone ?? '';
      _startSlipController.text = b.startSlip.toString();
      _endSlipController.text = b.endSlip.toString();
      final count = (b.endSlip - b.startSlip) + 1;
      _slipCountPreset = (count == 50 || count == 100) ? count : -1;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<PujaProvider>(context, listen: false);
        final nextBookNum = provider.books.isNotEmpty
            ? provider.books.map((b) => b.bookNumber).reduce((a, b) => a > b ? a : b) + 1
            : 1;
        final nextStartSlip = provider.books.isNotEmpty
            ? provider.books.map((b) => b.endSlip).reduce((a, b) => a > b ? a : b) + 1
            : 1;

        setState(() {
          _bookNoController.text = nextBookNum.toString();
          _startSlipController.text = nextStartSlip.toString();
          _endSlipController.text = (nextStartSlip + _slipCountPreset - 1).toString();
        });
      });
    }
  }

  void _updateEndSlip() {
    final start = int.tryParse(_startSlipController.text.trim());
    if (start != null && _slipCountPreset > 0) {
      _endSlipController.text = (start + _slipCountPreset - 1).toString();
    }
  }

  @override
  void dispose() {
    _bookNoController.dispose();
    _assigneeController.dispose();
    _phoneController.dispose();
    _startSlipController.dispose();
    _endSlipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);

    final startSlip = int.tryParse(_startSlipController.text.trim()) ?? 0;
    final endSlip = int.tryParse(_endSlipController.text.trim()) ?? 0;
    final totalSlips = (endSlip >= startSlip && startSlip > 0) ? (endSlip - startSlip + 1) : 0;
    final isEditing = widget.existing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Edit Chanda Book' : 'Issue New Chanda Book',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isEditing
                                      ? 'Update Book #${widget.existing!.bookNumber} information'
                                      : 'Assign a receipt booklet to a collector',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Field 1: Book Number
                _buildFieldLabel('Chanda Book Number *'),
                TextFormField(
                  controller: _bookNoController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: _inputDecoration('e.g. 5', Icons.bookmark_outline),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Book number is required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Field 2: Collector / Member Name
                _buildFieldLabel('Collector / Member Name *'),
                TextFormField(
                  controller: _assigneeController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. Rahul Sen (Committee Member)', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter collector name' : null,
                ),
                const SizedBox(height: 14),

                // Field 2.5: Collector Mobile
                _buildFieldLabel('Collector Mobile (Optional)'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. 9876543210', Icons.phone_outlined),
                ),
                const SizedBox(height: 14),

                // Field 3: Slip Booklet Size Presets
                _buildFieldLabel('Total Slips in Book'),
                Row(
                  children: [
                    _buildPresetChip(50, '50 Slips'),
                    const SizedBox(width: 8),
                    _buildPresetChip(100, '100 Slips'),
                    const SizedBox(width: 8),
                    _buildPresetChip(-1, 'Custom Range'),
                  ],
                ),
                const SizedBox(height: 14),

                // Field 4: Start & End Slip Inputs
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Start Slip # *'),
                          TextFormField(
                            controller: _startSlipController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: _inputDecoration('e.g. 401', Icons.tag),
                            onChanged: (_) => _updateEndSlip(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('End Slip # *'),
                          TextFormField(
                            controller: _endSlipController,
                            keyboardType: TextInputType.number,
                            enabled: _slipCountPreset == -1,
                            style: TextStyle(
                              color: _slipCountPreset == -1 ? Colors.white : AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: _inputDecoration('e.g. 500', Icons.receipt),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final end = int.tryParse(v.trim());
                              final start = int.tryParse(_startSlipController.text.trim());
                              if (end == null || start == null || end < start) {
                                return 'End >= Start';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          totalSlips > 0
                              ? 'This book will issue $totalSlips slips (from #$startSlip to #$endSlip)'
                              : 'Enter valid slip range',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing ? AppTheme.goldAccent : AppTheme.primaryBlue,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final bookNo = int.tryParse(_bookNoController.text.trim()) ?? 1;
                        final assignee = _assigneeController.text.trim();
                        final phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
                        final start = int.tryParse(_startSlipController.text.trim()) ?? 1;
                        final end = int.tryParse(_endSlipController.text.trim()) ?? (start + 99);

                        if (isEditing) {
                          provider.updateBook(
                            id: widget.existing!.id,
                            bookNumber: bookNo,
                            assignedTo: assignee,
                            collectorPhone: phone,
                            startSlip: start,
                            endSlip: end,
                          );
                        } else {
                          provider.addBook(
                            bookNumber: bookNo,
                            assignedTo: assignee,
                            collectorPhone: phone,
                            startSlip: start,
                            endSlip: end,
                          );
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content: Text(
                              isEditing ? '✅ Book #$bookNo details updated!' : '✅ New Chanda Book allocated successfully!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditing ? Icons.save_outlined : Icons.add_task, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Save Book Changes' : 'Allocate Book & Register',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(int preset, String label) {
    final isSelected = _slipCountPreset == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _slipCountPreset = preset;
            if (preset > 0) {
              _updateEndSlip();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withAlpha(40) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primaryBlue.withAlpha(50)),
      ),
    );
  }
}

// ==========================================
// 4. PAYMENT MODE SELECTOR CHIP
// ==========================================
class _PaymentModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlue.withAlpha(40) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primaryBlue : AppTheme.glassBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppTheme.primaryBlue : Colors.white60),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. GIVE ADVANCE TO MEMBER DIALOG
// ==========================================
class GiveAdvanceDialog extends StatefulWidget {
  final MemberAdvance? existing;
  final String? initialEventId;

  const GiveAdvanceDialog({super.key, this.existing, this.initialEventId});

  @override
  State<GiveAdvanceDialog> createState() => _GiveAdvanceDialogState();
}

class _GiveAdvanceDialogState extends State<GiveAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contractAmountController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.bhogCatering;
  PaymentMode _paymentMode = PaymentMode.cash;
  String? _selectedEventId;
  DateTime _selectedDate = DateTime.now();
  String? _receiptPhotoUrl;

  final List<int> _quickAmounts = [2000, 5000, 10000, 15000, 20000];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final a = widget.existing!;
      _nameController.text = a.memberName;
      if (a.originalAmount != null && a.originalAmount! > 0) {
        _contractAmountController.text = a.originalAmount!.toStringAsFixed(0);
      }
      _amountController.text = a.advanceAmount.toStringAsFixed(0);
      _purposeController.text = a.purpose;
      _selectedCategory = a.category;
      _paymentMode = a.paymentMode;
      _selectedEventId = a.eventId;
      _selectedDate = a.dateGiven;
      _receiptPhotoUrl = a.receiptPhotoUrl;
    } else {
      _selectedEventId = widget.initialEventId;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contractAmountController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final isEditing = widget.existing != null;
    final effectiveEventId = isEditing
        ? _selectedEventId
        : (_selectedEventId ?? widget.initialEventId ?? provider.selectedEvent?.id ?? (provider.events.isNotEmpty ? provider.events.first.id : null));
    if (_selectedEventId != effectiveEventId && effectiveEventId != null) {
      _selectedEventId = effectiveEventId;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wallet_outlined,
                              color: AppTheme.goldAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Edit Advance Account' : 'Give Advance / Contractor Deal',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isEditing
                                      ? 'Update advance details for ${widget.existing!.memberName}'
                                      : 'Set contract deal & hand over advance installments',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Event / Festival Selector
                if (provider.events.isNotEmpty) ...[
                  _buildFieldLabel('Event / Festival *'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.goldAccent.withAlpha(90), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.events.any((e) => e.id == _selectedEventId)
                            ? _selectedEventId
                            : provider.events.first.id,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldAccent),
                        items: provider.events.map((evt) {
                          return DropdownMenuItem(
                            value: evt.id,
                            child: Row(
                              children: [
                                const Icon(Icons.festival_outlined, size: 16, color: AppTheme.goldAccent),
                                const SizedBox(width: 8),
                                Text(
                                  '${evt.name} (${evt.year})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEventId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Contractor / Member Name
                _buildFieldLabel('Contractor / Member / Vendor Name *'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. Pandal Contractor / Rahul Sen', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 14),

                // Original Contract / Agreed Deal Amount
                _buildFieldLabel('Total Agreed / Contract Amount (Original Deal)'),
                TextFormField(
                  controller: _contractAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: _inputDecoration('e.g. 50000 (total pandal contract deal)', Icons.description_outlined),
                ),
                const SizedBox(height: 4),
                Text(
                  '💡 Leave blank if there is no fixed contract (regular member shopping advance).',
                  style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140)),
                ),
                const SizedBox(height: 14),

                // Advance Amount Handover Now
                _buildFieldLabel(isEditing ? 'Advance Amount (₹) *' : 'Advance Amount to Give Now (₹) *'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration('e.g. 1000', Icons.currency_rupee),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickAmounts.map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: const Color(0x1F1E293B),
                          side: const BorderSide(color: AppTheme.glassBorder),
                          label: Text(
                            '₹$amt',
                            style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              _amountController.text = amt.toString();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Purpose
                _buildFieldLabel('Purpose / What is this advance for? *'),
                TextFormField(
                  controller: _purposeController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. Bamboo booking, ropes & pandal labor', Icons.shopping_bag_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter purpose' : null,
                ),
                const SizedBox(height: 14),

                // Category
                _buildFieldLabel('Expense Category'),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: _inputDecoration('Category', Icons.category_outlined),
                  items: ExpenseCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 10),
                          Text(cat.displayName, style: const TextStyle(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Payment Mode
                _buildFieldLabel('Given Via'),
                Row(
                  children: [
                    _PaymentModeChip(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: _paymentMode == PaymentMode.cash,
                      onTap: () => setState(() => _paymentMode = PaymentMode.cash),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'UPI / QR',
                      icon: Icons.qr_code_2,
                      selected: _paymentMode == PaymentMode.upi,
                      onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'Bank Transfer',
                      icon: Icons.account_balance,
                      selected: _paymentMode == PaymentMode.bankTransfer,
                      onTap: () => setState(() => _paymentMode = PaymentMode.bankTransfer),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Advance Date Picker
                _buildFieldLabel(isEditing ? 'Advance Date' : 'Date of Advance *'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.goldAccent,
                              onPrimary: Color(0xFF070D1E),
                              surface: Color(0xFF0F172A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, color: Colors.white60, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Voucher / Receipt Photo
                _buildFieldLabel('Advance Slip / Agreement Photo (Optional)'),
                _receiptPhotoUrl != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.successGreen.withAlpha(90), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: _nameController.text.isNotEmpty ? _nameController.text : 'Advance Slip',
                                  subtitle: 'Attached Slip / Agreement',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _receiptPhotoUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image, color: Colors.white54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Slip Attached',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Saved securely • Tap to view',
                                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'View Full Slip',
                              icon: const Icon(Icons.zoom_in_rounded, color: AppTheme.primaryBlue, size: 20),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: _nameController.text.isNotEmpty ? _nameController.text : 'Advance Slip',
                                  subtitle: 'Attached Slip / Agreement',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove Slip',
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 20),
                              onPressed: () => setState(() => _receiptPhotoUrl = null),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => showAttachBillModal(
                          context,
                          onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attach Advance Slip / Agreement (Optional)',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Photo of cash voucher, signed receipt or deal contract',
                                      style: TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final member = _nameController.text.trim();
                        final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        final contractAmt = double.tryParse(_contractAmountController.text.trim());
                        final purpose = _purposeController.text.trim();
                        final targetEvt = _selectedEventId ?? provider.selectedEvent?.id ?? (provider.events.isNotEmpty ? provider.events.first.id : null);

                        if (isEditing) {
                          provider.updateAdvance(
                            id: widget.existing!.id,
                            memberName: member,
                            amount: amount,
                            originalAmount: contractAmt,
                            category: _selectedCategory,
                            paymentMode: _paymentMode,
                            purpose: purpose,
                            dateGiven: _selectedDate,
                            eventId: targetEvt,
                            receiptPhotoUrl: _receiptPhotoUrl,
                            clearReceiptPhoto: _receiptPhotoUrl == null,
                          );
                        } else {
                          provider.giveAdvance(
                            memberName: member,
                            amount: amount,
                            originalAmount: contractAmt,
                            category: _selectedCategory,
                            paymentMode: _paymentMode,
                            purpose: purpose,
                            date: _selectedDate,
                            eventId: targetEvt,
                            receiptPhotoUrl: _receiptPhotoUrl,
                          );
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content: Text(
                              isEditing
                                  ? '✅ Advance updated successfully!'
                                  : '✅ Advance account recorded! Settlement marked as Pending.',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditing ? Icons.save_outlined : Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Save Advance Changes' : 'Issue Advance Cash',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 5B. ADD ADVANCE INSTALLMENT DIALOG
// ==========================================
class AddAdvanceInstallmentDialog extends StatefulWidget {
  final MemberAdvance advance;
  const AddAdvanceInstallmentDialog({super.key, required this.advance});

  @override
  State<AddAdvanceInstallmentDialog> createState() => _AddAdvanceInstallmentDialogState();
}

class _AddAdvanceInstallmentDialogState extends State<AddAdvanceInstallmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final adv = widget.advance;
    final provider = Provider.of<PujaProvider>(context, listen: false);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 500,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_card_rounded, color: AppTheme.goldAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Advance Installment',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Pay further advance to ${adv.memberName}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Account overview banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (adv.hasContract) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Original Contract', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
                            Text(currency.format(adv.effectiveOriginalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Already Paid', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
                            Text(currency.format(adv.advanceAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Remaining Due', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
                            Text(currency.format(adv.remainingDue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF87171))),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Paid So Far', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
                            Text(currency.format(adv.advanceAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${adv.installments.length} payment(s)', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                _buildFieldLabel('New Advance Amount (₹) *'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration('e.g. 500', Icons.currency_rupee),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      500,
                      1000,
                      2000,
                      5000,
                      if (adv.hasContract && adv.remainingDue > 0) adv.remainingDue.toInt(),
                    ].map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: const Color(0x1F1E293B),
                          side: const BorderSide(color: AppTheme.glassBorder),
                          label: Text(
                            '₹$amt',
                            style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => setState(() => _amountController.text = amt.toString()),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment Mode
                _buildFieldLabel('Payment Mode'),
                Row(
                  children: [
                    _PaymentModeChip(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: _paymentMode == PaymentMode.cash,
                      onTap: () => setState(() => _paymentMode = PaymentMode.cash),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'UPI / QR',
                      icon: Icons.qr_code_2,
                      selected: _paymentMode == PaymentMode.upi,
                      onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'Bank Transfer',
                      icon: Icons.account_balance,
                      selected: _paymentMode == PaymentMode.bankTransfer,
                      onTap: () => setState(() => _paymentMode = PaymentMode.bankTransfer),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Payment Date
                _buildFieldLabel('Payment Date *'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.goldAccent,
                              onPrimary: Color(0xFF070D1E),
                              surface: Color(0xFF0F172A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, color: Colors.white60, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Note / Purpose
                _buildFieldLabel('Installment Note / For What?'),
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. 2nd advance / transport fee', Icons.notes_rounded),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Add Advance Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        final note = _noteController.text.trim();
                        provider.addAdvanceInstallment(
                          advanceId: adv.id,
                          amount: amt,
                          paymentMode: _paymentMode,
                          note: note.isNotEmpty ? note : 'Advance installment',
                          date: _selectedDate,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content: Text(
                              '✅ Added ₹${amt.toStringAsFixed(0)} advance to ${adv.memberName}!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 6. SETTLE ADVANCE & RETURN CASH DIALOG
// ==========================================
class SettleAdvanceDialog extends StatefulWidget {
  final MemberAdvance advance;

  const SettleAdvanceDialog({super.key, required this.advance});

  @override
  State<SettleAdvanceDialog> createState() => _SettleAdvanceDialogState();
}

class _SettleAdvanceDialogState extends State<SettleAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _spentController = TextEditingController();
  final _billsController = TextEditingController();

  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _settlementDate = DateTime.now();
  String? _receiptPhotoUrl;

  @override
  void initState() {
    super.initState();
    _paymentMode = widget.advance.paymentMode;
    _receiptPhotoUrl = widget.advance.receiptPhotoUrl;
    if (widget.advance.hasContract) {
      _spentController.text = widget.advance.effectiveOriginalAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _spentController.dispose();
    _billsController.dispose();
    super.dispose();
  }

  Widget _buildModeChip(PaymentMode mode, String label) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldAccent.withAlpha(35) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.goldAccent : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(150))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final adv = widget.advance;
    final hasContract = adv.hasContract;

    final double spent = double.tryParse(_spentController.text.trim()) ?? 0.0;
    final double diff = adv.advanceAmount - spent;
    final bool isRefund = diff > 0 && spent > 0;
    final bool isExtraClaim = diff < 0 && spent > 0;
    final double finalBalanceToPay = spent > adv.advanceAmount ? (spent - adv.advanceAmount) : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: AppTheme.successGreenLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasContract ? 'Settle Contractor Final Bill' : 'Settle Advance & Return Cash',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  hasContract
                                      ? 'Clear remaining due & record final voucher'
                                      : 'Record final bill & calculate refund/claim',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Advance Info Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adv.memberName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${adv.category.displayName} • ${adv.purpose}',
                                  style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasContract ? const Color(0xFF38BDF8).withAlpha(25) : AppTheme.goldAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasContract ? const Color(0xFF38BDF8).withAlpha(80) : AppTheme.goldAccent.withAlpha(100),
                              ),
                            ),
                            child: Text(
                              hasContract ? 'CONTRACT DEAL' : 'Advance: ₹${adv.advanceAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: hasContract ? const Color(0xFF38BDF8) : AppTheme.goldAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasContract) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat('Total Deal', '₹${adv.effectiveOriginalAmount.toInt()}', const Color(0xFF38BDF8)),
                              Container(width: 1, height: 26, color: Colors.white12),
                              _buildMiniStat('Advance Paid', '₹${adv.advanceAmount.toInt()}', AppTheme.goldAccent),
                              Container(width: 1, height: 26, color: Colors.white12),
                              _buildMiniStat(
                                'Balance Due',
                                '₹${adv.remainingDue.toInt()}',
                                adv.remainingDue > 0 ? const Color(0xFFFF7B92) : AppTheme.successGreenLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Settlement Helper Chips (for contracts)
                if (hasContract) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            backgroundColor: const Color(0xFF0284C7).withAlpha(40),
                            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.1),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            label: Text(
                              '🎯 Settle Full Deal (₹${adv.effectiveOriginalAmount.toInt()})',
                              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => setState(() => _spentController.text = adv.effectiveOriginalAmount.toInt().toString()),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            backgroundColor: AppTheme.goldAccent.withAlpha(30),
                            side: const BorderSide(color: AppTheme.goldAccent, width: 1.1),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            label: Text(
                              '✋ Settle at Paid Advance (₹${adv.advanceAmount.toInt()})',
                              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => setState(() => _spentController.text = adv.advanceAmount.toInt().toString()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Actual Bill Amount
                _buildFieldLabel(hasContract ? 'Final Agreed Deal / Bill Amount (₹) *' : 'Actual Bill Amount / Total Spent (₹) *'),
                TextFormField(
                  controller: _spentController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration(
                    hasContract ? 'e.g. ${adv.effectiveOriginalAmount.toInt()}' : 'e.g. 8500',
                    Icons.receipt_long,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Actual spent/bill amount is required';
                    if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Bill Item Details
                _buildFieldLabel('Settlement Notes / Breakdown (Optional)'),
                TextFormField(
                  controller: _billsController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    hasContract
                        ? 'e.g. Final bamboo dismantling & pandal handover completed'
                        : 'e.g. Mustard oil ₹3500, Rice ₹3500, Fruits ₹1500',
                    Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Real-time Settlement Calculation Box
                if (spent > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasContract
                          ? (spent >= adv.advanceAmount ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFF59E0B).withAlpha(25))
                          : (isRefund
                              ? AppTheme.successGreen.withAlpha(25)
                              : isExtraClaim
                                  ? AppTheme.dangerRose.withAlpha(25)
                                  : AppTheme.primaryBlue.withAlpha(25)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasContract
                            ? (spent >= adv.advanceAmount ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                            : (isRefund
                                ? AppTheme.successGreenLight
                                : isExtraClaim
                                    ? AppTheme.dangerRose
                                    : AppTheme.primaryBlue),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          hasContract
                              ? (spent >= adv.advanceAmount ? Icons.handshake_rounded : Icons.savings_rounded)
                              : (isRefund
                                  ? Icons.savings
                                  : isExtraClaim
                                      ? Icons.add_card
                                      : Icons.check_circle),
                          color: hasContract
                              ? (spent >= adv.advanceAmount ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                              : (isRefund
                                  ? AppTheme.successGreenLight
                                  : isExtraClaim
                                      ? AppTheme.dangerRose
                                      : AppTheme.primaryBlue),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasContract) ...[
                                if (spent > adv.advanceAmount) ...[
                                  Text(
                                    '🤝 Final Balance to Pay Contractor: ₹${finalBalanceToPay.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Committee will pay remaining balance of ₹${finalBalanceToPay.toStringAsFixed(0)} to ${adv.memberName}.\n• Official expense of ₹${spent.toStringAsFixed(0)} will be recorded into accounts.\n• Account balance due becomes ₹0 (✅ 100% Settled).',
                                    style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 11.5, height: 1.3),
                                  ),
                                ] else if (spent == adv.advanceAmount) ...[
                                  Text(
                                    '✅ Settled at Current Advance: ₹${spent.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• No additional payment required.\n• Deal finalized at advance amount paid so far with zero pending dues.',
                                    style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 11.5),
                                  ),
                                ] else ...[
                                  Text(
                                    '💰 Contractor Cash Refund: ₹${diff.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Contractor returns excess advance of ₹${diff.toStringAsFixed(0)} back into Committee funds.',
                                    style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 11.5),
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  isRefund
                                      ? '💰 Cash Refund to Cashier: ₹${diff.toStringAsFixed(0)}'
                                      : isExtraClaim
                                          ? '⚠️ Member Extra Claim: ₹${(-diff).toStringAsFixed(0)}'
                                          : '✅ 100% Exact Settlement',
                                  style: TextStyle(
                                    color: isRefund
                                        ? AppTheme.successGreenLight
                                        : isExtraClaim
                                            ? const Color(0xFFFF7B92)
                                            : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isRefund
                                      ? 'Member will return ₹${diff.toStringAsFixed(0)} cash back into Cashier desk.'
                                      : isExtraClaim
                                          ? 'Cashier will pay ₹${(-diff).toStringAsFixed(0)} extra cash to member.'
                                          : 'Full advance amount was spent with zero balance remaining.',
                                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Balance Payment Mode Selector (when paying extra balance to contractor)
                  if (finalBalanceToPay > 0) ...[
                    _buildFieldLabel('Balance Payment Mode (₹${finalBalanceToPay.toInt()}) *'),
                    Row(
                      children: [
                        _buildModeChip(PaymentMode.cash, '💵 Cash'),
                        const SizedBox(width: 8),
                        _buildModeChip(PaymentMode.upi, '📱 UPI'),
                        const SizedBox(width: 8),
                        _buildModeChip(PaymentMode.bankTransfer, '🏦 Bank'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Settlement Bill / Invoice Photo (Optional)
                _buildFieldLabel('Settlement Bill / Invoice Photo (Optional)'),
                _receiptPhotoUrl != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.successGreen.withAlpha(90), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: '${adv.memberName} - Settlement Bill',
                                  subtitle: 'Settlement Receipt',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _receiptPhotoUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image, color: Colors.white54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Settlement Bill Attached',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Saved securely • Tap to view',
                                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'View Full Bill',
                              icon: const Icon(Icons.zoom_in_rounded, color: AppTheme.primaryBlue, size: 20),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => BillImagePreviewDialog(
                                  imageUrl: _receiptPhotoUrl!,
                                  title: '${adv.memberName} - Settlement Bill',
                                  subtitle: 'Settlement Receipt',
                                  onDelete: () => setState(() => _receiptPhotoUrl = null),
                                  onReplace: () => showAttachBillModal(
                                    context,
                                    onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                                    existingUrl: _receiptPhotoUrl,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove Bill',
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 20),
                              onPressed: () => setState(() => _receiptPhotoUrl = null),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => showAttachBillModal(
                          context,
                          onUploaded: (url) => setState(() => _receiptPhotoUrl = url),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attach Settlement Bill / Invoice Photo',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Store invoice, final settlement memo or voucher slip',
                                      style: TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Settlement Date Selector
                _buildFieldLabel('Settlement Date *'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _settlementDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.goldAccent,
                              onPrimary: Colors.black,
                              surface: Color(0xFF0F172A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _settlementDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_settlementDate),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, color: Colors.white60, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Settle Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreenLight,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final actual = double.tryParse(_spentController.text.trim()) ?? 0.0;
                        provider.settleAdvance(
                          advanceId: adv.id,
                          actualSpent: actual,
                          settlementPaymentMode: _paymentMode,
                          billDetails: _billsController.text.trim().isNotEmpty ? _billsController.text.trim() : null,
                          settlementDate: _settlementDate,
                          receiptPhotoUrl: _receiptPhotoUrl,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content: Text(
                              hasContract
                                  ? '✅ Contractor deal settled! Final expense ₹${actual.toStringAsFixed(0)} recorded & Balance Cleared!'
                                  : (isRefund
                                      ? '✅ Advance settled! ₹${diff.toStringAsFixed(0)} cash returned to Cash in Hand.'
                                      : '✅ Advance settled and recorded into official Expenses!'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          hasContract ? 'Confirm & Settle Contractor Deal' : 'Confirm & Settle Advance',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.successGreenLight, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.successGreenLight, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 6B. EDIT ADVANCE INSTALLMENT DIALOG
// ==========================================
class EditAdvanceInstallmentDialog extends StatefulWidget {
  final MemberAdvance advance;
  final AdvanceInstallment installment;

  const EditAdvanceInstallmentDialog({
    super.key,
    required this.advance,
    required this.installment,
  });

  @override
  State<EditAdvanceInstallmentDialog> createState() => _EditAdvanceInstallmentDialogState();
}

class _EditAdvanceInstallmentDialogState extends State<EditAdvanceInstallmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late PaymentMode _paymentMode;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.installment.amount.toInt().toString());
    _noteController = TextEditingController(text: widget.installment.note);
    _paymentMode = widget.installment.paymentMode;
    _selectedDate = widget.installment.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildModeChip(PaymentMode mode, String label) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldAccent.withAlpha(35) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.goldAccent : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context, listen: false);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 500,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Installment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.advance.memberName,
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Amount
                _buildFieldLabel('Installment Amount (₹) *'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration('e.g. 1000', Icons.currency_rupee_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment Mode
                _buildFieldLabel('Payment Mode *'),
                Row(
                  children: [
                    _buildModeChip(PaymentMode.cash, '💵 Cash'),
                    const SizedBox(width: 8),
                    _buildModeChip(PaymentMode.upi, '📱 UPI'),
                    const SizedBox(width: 8),
                    _buildModeChip(PaymentMode.bankTransfer, '🏦 Bank'),
                  ],
                ),
                const SizedBox(height: 14),

                // Date
                _buildFieldLabel('Installment Date *'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.goldAccent),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                _buildFieldLabel('Note / Purpose'),
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. Bamboo purchase cash', Icons.notes_rounded),
                ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        provider.editAdvanceInstallment(
                          advanceId: widget.advance.id,
                          installmentId: widget.installment.id,
                          newAmount: newAmount,
                          newPaymentMode: _paymentMode,
                          newDate: _selectedDate,
                          newNote: _noteController.text.trim(),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF162032),
                            content: Text('✅ Installment updated successfully!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Save Installment Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. SLIP RECEIPT ACTION & WHATSAPP SHARE DIALOG
// ==========================================
class SlipReceiptActionDialog extends StatelessWidget {
  final ChandaSlip slip;

  const SlipReceiptActionDialog({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currentSlip = provider.slips.firstWhere((s) => s.id == slip.id, orElse: () => slip);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreenLight.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.successGreenLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slip Issued Successfully!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Share digital receipt with donor',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Receipt Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Slip #${currentSlip.slipNumber} • Book #${currentSlip.bookNumber}',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(
                        currency.format(currentSlip.amount),
                        style: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentSlip.donorName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (currentSlip.phone != null && currentSlip.phone!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(currentSlip.phone!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (currentSlip.address != null && currentSlip.address!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      currentSlip.address!,
                      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Physical Slip Photo Section
            if (currentSlip.slipPhotoUrl != null && currentSlip.slipPhotoUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.successGreen.withAlpha(90), width: 1.2),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => BillImagePreviewDialog(
                          imageUrl: currentSlip.slipPhotoUrl!,
                          title: currentSlip.donorName,
                          subtitle: 'Slip #${currentSlip.slipNumber} • Book #${currentSlip.bookNumber}',
                          onDelete: () => provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: null),
                          onReplace: () => showAttachSlipModal(
                            context,
                            onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: url),
                            existingUrl: currentSlip.slipPhotoUrl,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          currentSlip.slipPhotoUrl!,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 46,
                            height: 46,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.white54, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Physical Slip Attached',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Full HD • Tap to zoom',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'View Full Slip Photo',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => BillImagePreviewDialog(
                            imageUrl: currentSlip.slipPhotoUrl!,
                            title: currentSlip.donorName,
                            subtitle: 'Slip #${currentSlip.slipNumber} • Book #${currentSlip.bookNumber}',
                            onDelete: () => provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: null),
                            onReplace: () => showAttachSlipModal(
                              context,
                              onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: url),
                              existingUrl: currentSlip.slipPhotoUrl,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                          ),
                          child: const Icon(Icons.zoom_in_rounded, color: AppTheme.primaryBlue, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Remove Slip Photo',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final confirmed = await showConfirmDeleteImageDialog(
                            context,
                            title: 'Remove Slip Photo?',
                            message: 'Are you sure you want to remove the physical slip photo for Slip #${currentSlip.slipNumber}?',
                          );
                          if (confirmed) {
                            provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: null);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRose.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.dangerRose.withAlpha(80)),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showAttachSlipModal(
                  context,
                  onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: currentSlip.id, photoUrl: url),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attach Physical Slip Photo',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            Text(
                              'Camera or Gallery • Auto-compressed',
                              style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Action 1: Send on WhatsApp Button (Shares PDF directly)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text(
                  'Send WhatsApp Receipt (PDF)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  ReceiptShareService.shareSlipPdf(
                    slip: currentSlip,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Action 2 & 3: Print / Share PDF
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Print Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ReceiptShareService.printSlipPdf(
                          slip: currentSlip,
                          pujaName: provider.pujaName,
                          currentYear: provider.currentYear,
                          cashierName: provider.cashierName,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ReceiptShareService.shareSlipPdf(
                          slip: currentSlip,
                          pujaName: provider.pujaName,
                          currentYear: provider.currentYear,
                          cashierName: provider.cashierName,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Manage Row: Edit & Delete slip
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldAccent,
                        side: const BorderSide(color: AppTheme.goldAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          DialogRoute(
                            context: context,
                            builder: (_) => AddEditDonationDialog(existing: slip),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRose,
                        side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          DialogRoute(
                            context: context,
                            builder: (_) => DeleteConfirmDialog(
                              title: 'Delete Donation?',
                              message:
                                  'Are you sure you want to delete the donation of ₹${slip.amount.toStringAsFixed(0)} by ${slip.donorName}?',
                              onConfirm: () => provider.deleteDonation(slip.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Done Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done / Close', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7B. EXPENSE VOUCHER ACTION & WHATSAPP SHARE DIALOG
// ==========================================
class ExpenseVoucherActionDialog extends StatelessWidget {
  final ExpenseVoucher voucher;

  const ExpenseVoucherActionDialog({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context, listen: false);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isAdvance = voucher.isAdvance;
    final themeColor = isAdvance ? const Color(0xFFF59E0B) : AppTheme.dangerRose;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor.withAlpha(80)),
                      ),
                      child: Icon(
                        isAdvance ? Icons.wallet_rounded : Icons.receipt_long_rounded,
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdvance ? 'Advance Voucher Details' : 'Expense Voucher Details',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isAdvance
                              ? 'Official advance disbursement record'
                              : 'Official festival expense record',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Voucher Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category & Voucher # on left, Amount on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColor.withAlpha(70)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdvance ? Icons.wallet_rounded : voucher.category.icon,
                              size: 13,
                              color: themeColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${voucher.category.displayName} • #${voucher.voucherNo}',
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(voucher.amount),
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payee Name
                  Text(
                    voucher.payeeName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  // Disbursed by & Mode
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (voucher.paidBy.isNotEmpty) ...[
                        const Icon(Icons.badge_outlined, size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(
                          'Paid by ${voucher.paidBy}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.white38)),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x221E293B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Text(
                          voucher.paymentMode.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Date
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMMM yyyy, hh:mm a').format(voucher.date),
                        style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11.5),
                      ),
                    ],
                  ),

                  // Note / Description
                  if (voucher.description != null && voucher.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x181E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              voucher.description!.trim(),
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Advance Installment linked notice
                  if (isAdvance) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded, size: 12, color: Color(0xFFFBBF24)),
                          SizedBox(width: 4),
                          Text(
                            'Linked to Contractor Advance Account',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bill / Receipt Photo Section
            if (voucher.receiptPhotoUrl != null && voucher.receiptPhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.successGreen.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => BillImagePreviewDialog(
                          imageUrl: voucher.receiptPhotoUrl!,
                          title: voucher.payeeName,
                          subtitle: 'Voucher #${voucher.voucherNo}',
                          onDelete: () {
                            provider.updateExpenseReceiptPhoto(expenseId: voucher.id, photoUrl: null);
                            Navigator.pop(context);
                          },
                          onReplace: () => showAttachBillModal(
                            context,
                            onUploaded: (url) {
                              provider.updateExpenseReceiptPhoto(expenseId: voucher.id, photoUrl: url);
                            },
                            existingUrl: voucher.receiptPhotoUrl,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          voucher.receiptPhotoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Official Bill Attached',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to preview or zoom',
                            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => BillImagePreviewDialog(
                          imageUrl: voucher.receiptPhotoUrl!,
                          title: voucher.payeeName,
                          subtitle: 'Voucher #${voucher.voucherNo}',
                          onDelete: () {
                            provider.updateExpenseReceiptPhoto(expenseId: voucher.id, photoUrl: null);
                            Navigator.pop(context);
                          },
                          onReplace: () => showAttachBillModal(
                            context,
                            onUploaded: (url) {
                              provider.updateExpenseReceiptPhoto(expenseId: voucher.id, photoUrl: url);
                            },
                            existingUrl: voucher.receiptPhotoUrl,
                          ),
                        ),
                      ),
                      child: const Text('View Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('+ Attach Bill / Invoice Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => showAttachBillModal(
                    context,
                    onUploaded: (url) {
                      provider.updateExpenseReceiptPhoto(expenseId: voucher.id, photoUrl: url);
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => ExpenseVoucherActionDialog(
                          voucher: voucher.copyWith(receiptPhotoUrl: url),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action 1: Send on WhatsApp Button (Shares PDF directly)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text(
                  'Share Voucher on WhatsApp (PDF)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  ReceiptShareService.shareExpenseVoucherPdf(
                    voucher: voucher,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Action 2 & 3: Print / Share PDF
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Print Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ReceiptShareService.printExpenseVoucherPdf(
                          voucher: voucher,
                          pujaName: provider.pujaName,
                          currentYear: provider.currentYear,
                          cashierName: provider.cashierName,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ReceiptShareService.shareExpenseVoucherPdf(
                          voucher: voucher,
                          pujaName: provider.pujaName,
                          currentYear: provider.currentYear,
                          cashierName: provider.cashierName,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action 2: Manage Row (Edit & Delete)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldAccent,
                        side: const BorderSide(color: AppTheme.goldAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          DialogRoute(
                            context: context,
                            builder: (_) => AddExpenseDialog(
                              initialEventId: voucher.eventId,
                              existing: voucher,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRose,
                        side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          DialogRoute(
                            context: context,
                            builder: (_) => ConfirmDeleteDialog(
                              title: 'Delete Expense Voucher?',
                              message:
                                  'Voucher #${voucher.voucherNo} (${voucher.payeeName} - ₹${voucher.amount.toStringAsFixed(0)}) will be permanently deleted.',
                              onConfirm: () => provider.deleteExpense(voucher.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Done / Close Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done / Close', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. EDIT COMMITTEE SETTINGS DIALOG
// ==========================================
class EditCommitteeSettingsDialog extends StatefulWidget {
  final int initialTab; // 0: Committee Profile, 1: Account & Security
  const EditCommitteeSettingsDialog({super.key, this.initialTab = 0});

  @override
  State<EditCommitteeSettingsDialog> createState() => _EditCommitteeSettingsDialogState();
}

class _EditCommitteeSettingsDialogState extends State<EditCommitteeSettingsDialog> {
  late int _currentTab;
  final _formKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _changePasswordFormKey = GlobalKey<FormState>();

  // Committee controllers
  late final TextEditingController _pujaNameController;
  late final TextEditingController _yearController;
  late final TextEditingController _cashierController;
  late final TextEditingController _presidentController;
  late final TextEditingController _secretaryController;

  // Category budgets (optional)
  bool _showBudgets = false;
  final Map<ExpenseCategory, TextEditingController> _budgetControllers = {};

  // Account & Security controllers
  late final TextEditingController _linkEmailController;
  late final TextEditingController _linkPasswordController;
  late final TextEditingController _linkConfirmPasswordController;
  late final TextEditingController _newPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;
  bool _isLinking = false;
  bool _isUpdatingPassword = false;
  bool _isSendingReset = false;
  bool _showChangePassword = false;
  String? _accountSuccessMsg;
  String? _accountErrorMsg;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;

    final provider = Provider.of<PujaProvider>(context, listen: false);
    _pujaNameController = TextEditingController(text: provider.pujaName);
    _yearController = TextEditingController(text: provider.currentYear.toString());
    _cashierController = TextEditingController(text: provider.cashierName);
    _presidentController = TextEditingController(text: provider.presidentName);
    _secretaryController = TextEditingController(text: provider.secretaryName);

    for (final cat in ExpenseCategory.values) {
      final existing = provider.categoryBudgets[cat];
      _budgetControllers[cat] = TextEditingController(
        text: existing != null
            ? (existing == existing.roundToDouble() ? existing.toStringAsFixed(0) : existing.toString())
            : '',
      );
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _linkEmailController = TextEditingController(text: auth.email);
    _linkPasswordController = TextEditingController();
    _linkConfirmPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _pujaNameController.dispose();
    _yearController.dispose();
    _cashierController.dispose();
    _presidentController.dispose();
    _secretaryController.dispose();
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    _linkEmailController.dispose();
    _linkPasswordController.dispose();
    _linkConfirmPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 580,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentTab == 0 ? Icons.settings : Icons.manage_accounts,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTab == 0 ? 'Committee & Puja Profile' : 'Account & Security Settings',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _currentTab == 0
                                ? 'Customize details shown on reports & PDF'
                                : 'Manage Google & Email login credentials',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentTab = 0;
                            _accountErrorMsg = null;
                            _accountSuccessMsg = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _currentTab == 0 ? AppTheme.primaryBlue.withAlpha(50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _currentTab == 0 ? AppTheme.primaryBlue.withAlpha(140) : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.festival_outlined,
                                size: 16,
                                color: _currentTab == 0 ? AppTheme.primaryBlue : Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Committee Profile',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _currentTab == 0 ? FontWeight.bold : FontWeight.w500,
                                  color: _currentTab == 0 ? Colors.white : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentTab = 1;
                            if (_linkEmailController.text.isEmpty && auth.email.isNotEmpty) {
                              _linkEmailController.text = auth.email;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _currentTab == 1 ? AppTheme.primaryBlue.withAlpha(50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _currentTab == 1 ? AppTheme.primaryBlue.withAlpha(140) : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security_outlined,
                                size: 16,
                                color: _currentTab == 1 ? AppTheme.primaryBlue : Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account & Login',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _currentTab == 1 ? FontWeight.bold : FontWeight.w500,
                                  color: _currentTab == 1 ? Colors.white : Colors.white70,
                                ),
                              ),
                              if (auth.isGoogleUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0x334285F4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0x664285F4)),
                                  ),
                                  child: const Text(
                                    'Google',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8AB4F8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tab 0: Committee Profile
              if (_currentTab == 0) _buildCommitteeTab(provider),

              // Tab 1: Account & Security (Google Email linking)
              if (_currentTab == 1) _buildAccountTab(auth),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMMITTEE TAB CONTENT
  // ==========================================
  Widget _buildCommitteeTab(PujaProvider provider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puja Name
          _buildLabel('Durga Puja Committee Name *'),
          TextFormField(
            controller: _pujaNameController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration('e.g. Tribeni Shanga Durga Puja Samiti', Icons.festival),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          // Year & Cashier Name
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Puja Year *'),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('2026', Icons.calendar_today),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Cashier / Treasurer *'),
                    TextFormField(
                      controller: _cashierController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Cashier Name', Icons.badge),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // President & Secretary
          _buildLabel('President Name (for Audit PDF)'),
          TextFormField(
            controller: _presidentController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('e.g. Dr. S. Mukherjee', Icons.person),
          ),
          const SizedBox(height: 14),

          _buildLabel('General Secretary Name (for Audit PDF)'),
          TextFormField(
            controller: _secretaryController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('e.g. Anirban Paul', Icons.person_outline),
          ),
          const SizedBox(height: 16),

          // Category Budgets Section
          GestureDetector(
            onTap: () => setState(() => _showBudgets = !_showBudgets),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _showBudgets ? AppTheme.goldAccent.withAlpha(120) : AppTheme.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 18,
                    color: _showBudgets ? AppTheme.goldAccent : Colors.white54,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category-wise Expense Budgets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: _showBudgets ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Optional • Real-time budget limit tracking',
                          style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showBudgets ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ),
          if (_showBudgets) ...[
            const SizedBox(height: 12),
            ...ExpenseCategory.values.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: cat.color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, size: 14, color: cat.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.displayName,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _budgetControllers[cat],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '₹ 0',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 10, right: 2),
                            child: Icon(Icons.currency_rupee, size: 14, color: Colors.white38),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.glassBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Text(
              'Tip: Khaali chhod do agar us category ka budget nahi hai.',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10.5),
            ),
          ],
          const SizedBox(height: 22),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: const Color(0xFF070D1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  provider.updateCommitteeSettings(
                    newPujaName: _pujaNameController.text.trim(),
                    newCashierName: _cashierController.text.trim(),
                    newYear: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
                    newPresident: _presidentController.text.trim().isNotEmpty
                        ? _presidentController.text.trim()
                        : 'President',
                    newSecretary: _secretaryController.text.trim().isNotEmpty
                        ? _secretaryController.text.trim()
                        : 'Secretary',
                  );

                  // Save category budgets (blank = no budget)
                  final budgets = <ExpenseCategory, double>{};
                  for (final entry in _budgetControllers.entries) {
                    final amount = double.tryParse(entry.value.text.trim());
                    if (amount != null && amount > 0) {
                      budgets[entry.key] = amount;
                    }
                  }
                  provider.saveBudgets(budgets);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.cardSurface,
                      content: Text('✅ Committee settings & profile updated!', style: TextStyle(color: Colors.white)),
                    ),
                  );
                }
              },
              child: const Text('Save & Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACCOUNT & SECURITY TAB CONTENT (Google + Email Add)
  // ==========================================
  Widget _buildAccountTab(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Profile Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorderLight),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryBlue.withAlpha(40),
                backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                    ? NetworkImage(auth.photoUrl!)
                    : null,
                child: auth.photoUrl == null || auth.photoUrl!.isEmpty
                    ? Text(
                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.displayName.isNotEmpty ? auth.displayName : 'Puja Cashier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.email.isNotEmpty ? auth.email : 'No email attached',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Provider Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (auth.isGoogleUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x2E4285F4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x664285F4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.g_mobiledata, color: Color(0xFF8AB4F8), size: 16),
                                SizedBox(width: 2),
                                Text(
                                  'Google Sign-In',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8AB4F8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (auth.isPasswordLinked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x2E10B981),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x6610B981)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Email Login Linked',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (auth.isGoogleUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x2EF59E0B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x66F59E0B)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Email Password Not Set',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFBBF24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Notifications banner if any
        if (_accountSuccessMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x2E10B981),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x6610B981)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _accountSuccessMsg!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_accountErrorMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x2EF43F5E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x66F43F5E)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.dangerRose, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _accountErrorMsg!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // -------------------------------------------------------------
        // SECTION A: GOOGLE USER WITHOUT EMAIL & PASSWORD LINKED
        // -------------------------------------------------------------
        if (auth.isGoogleUser && !auth.isPasswordLinked) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withAlpha(20),
                  const Color(0x1F1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withAlpha(100), width: 1.2),
            ),
            child: Form(
              key: _accountFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_link, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add / Link Email & Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              'Google ke sath Email & Password se bhi login karein',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x260F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppTheme.goldAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aap abhi Google se logged in hain. Email aur password add karne se aap future me direct Email & Password se bhi issi account me login kar payenge.',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  _buildLabel('Login Email *'),
                  TextFormField(
                    controller: _linkEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _inputDecoration('e.g. yourname@gmail.com', Icons.alternate_email),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email address is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password Field
                  _buildLabel('Create Password * (min 6 characters)'),
                  TextFormField(
                    controller: _linkPasswordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryBlue, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Confirm Password Field
                  _buildLabel('Confirm Password *'),
                  TextFormField(
                    controller: _linkConfirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Re-enter password',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primaryBlue, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm password';
                      if (v != _linkPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: _isLinking
                          ? null
                          : () async {
                              if (_accountFormKey.currentState!.validate()) {
                                setState(() {
                                  _isLinking = true;
                                  _accountErrorMsg = null;
                                  _accountSuccessMsg = null;
                                });

                                final success = await auth.linkEmailPassword(
                                  email: _linkEmailController.text.trim(),
                                  password: _linkPasswordController.text,
                                );

                                setState(() {
                                  _isLinking = false;
                                  if (success) {
                                    _accountSuccessMsg =
                                        '✅ Email & Password successfully linked! Now you can sign in with either Google or this Email.';
                                    _linkPasswordController.clear();
                                    _linkConfirmPasswordController.clear();
                                  } else {
                                    _accountErrorMsg = auth.errorMessage ??
                                        'Failed to link email. Please check your credentials and try again.';
                                  }
                                });
                              }
                            },
                      child: _isLinking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF070D1E)),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Link Email & Password',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // -------------------------------------------------------------
        // SECTION B: DUAL SIGN-IN IS ACTIVE (Email is already linked!)
        // -------------------------------------------------------------
        if (auth.isPasswordLinked) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x1F10B981), Color(0x1F1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x6610B981)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dual Login Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            'Google and Email & Password both configured',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Aapka email (${auth.email}) is account se successfully linked hai. Aap kisi bhi device par Google ya Email & Password dono me se kisi bhi tareeqe se login kar sakte hain.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 14),

                // Change Password button toggle
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: Icon(
                    _showChangePassword ? Icons.expand_less : Icons.lock_reset,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text(
                    _showChangePassword ? 'Close Password Change' : 'Change / Update Password',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => setState(() => _showChangePassword = !_showChangePassword),
                ),

                if (_showChangePassword) ...[
                  const SizedBox(height: 14),
                  Form(
                    key: _changePasswordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('New Password (min 6 characters)'),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryBlue, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xD9081022),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password cannot be empty';
                            if (v.length < 6) return 'Must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: const Color(0xFF070D1E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _isUpdatingPassword
                                    ? null
                                    : () async {
                                        if (_changePasswordFormKey.currentState!.validate()) {
                                          setState(() {
                                            _isUpdatingPassword = true;
                                            _accountErrorMsg = null;
                                            _accountSuccessMsg = null;
                                          });

                                          final ok = await auth.updatePassword(_newPasswordController.text);

                                          setState(() {
                                            _isUpdatingPassword = false;
                                            if (ok) {
                                              _accountSuccessMsg = '✅ Password updated successfully!';
                                              _newPasswordController.clear();
                                              _showChangePassword = false;
                                            } else {
                                              _accountErrorMsg = auth.errorMessage ?? 'Failed to update password.';
                                            }
                                          });
                                        }
                                      },
                                child: _isUpdatingPassword
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070D1E)),
                                      )
                                    : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: AppTheme.glassBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _isSendingReset
                                    ? null
                                    : () async {
                                        if (auth.email.isEmpty) return;
                                        setState(() => _isSendingReset = true);
                                        final sent = await auth.sendPasswordReset(auth.email);
                                        setState(() {
                                          _isSendingReset = false;
                                          if (sent) {
                                            _accountSuccessMsg =
                                                '📩 Password reset link sent to ${auth.email}. Check your inbox.';
                                          } else {
                                            _accountErrorMsg = auth.errorMessage ?? 'Failed to send reset email.';
                                          }
                                        });
                                      },
                                child: _isSendingReset
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                      )
                                    : const Text('Send Reset Link', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // -------------------------------------------------------------
        // SECTION C: NON-GOOGLE USER (Email & Password account)
        // -------------------------------------------------------------
        if (!auth.isGoogleUser && !auth.isPasswordLinked) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1F1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logged in with ${auth.email.isNotEmpty ? auth.email : "Local Session"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sign Out Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x14F43F5E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33F43F5E)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppTheme.dangerRose, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Log out of this Cashier Desk session',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmSignOutDialog(context);
                },
                child: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppTheme.dangerRose, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sign Out?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to sign out from your Cashier Desk account?',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Provider.of<AuthProvider>(context, listen: false).signOut();
                      },
                      child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 9. GENERIC DELETE CONFIRMATION DIALOG
// ==========================================
class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        maxWidth: 440,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.dangerRose.withAlpha(90), width: 1.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRose.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.dangerRose,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(180), height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ==========================================
// 10. EDIT CHANDA SLIP DIALOG
// ==========================================
class EditChandaSlipDialog extends StatefulWidget {
  final ChandaSlip slip;

  const EditChandaSlipDialog({super.key, required this.slip});

  @override
  State<EditChandaSlipDialog> createState() => _EditChandaSlipDialogState();
}

class _EditChandaSlipDialogState extends State<EditChandaSlipDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _slipsCountController;
  late final TextEditingController _bookNoController;
  late final TextEditingController _slipNoController;
  late String _dayLabel;

  PaymentMode _paymentMode = PaymentMode.cash;

  final List<String> _quickDays = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Saptami', 'Ashtami', 'Navami', 'Dashami'];

  @override
  void initState() {
    super.initState();
    final slip = widget.slip;
    _nameController = TextEditingController(text: slip.donorName);
    _amountController = TextEditingController(
      text: slip.amount == slip.amount.roundToDouble()
          ? slip.amount.toStringAsFixed(0)
          : slip.amount.toString(),
    );
    _phoneController = TextEditingController(text: slip.phone ?? '');
    _addressController = TextEditingController(text: slip.address ?? slip.notes ?? '');
    _slipsCountController = TextEditingController(text: slip.slipsCount.toString());
    _bookNoController = TextEditingController(text: slip.bookNumber.toString());
    _slipNoController = TextEditingController(text: slip.slipNumber.toString());
    _dayLabel = slip.dayLabel ?? 'Day 1';
    _paymentMode = slip.paymentMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _slipsCountController.dispose();
    _bookNoController.dispose();
    _slipNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context, listen: false);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDailyCollection = widget.slip.dayLabel != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 560,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: AppTheme.goldAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDailyCollection ? 'Edit Day Collection' : 'Edit Chanda Slip',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Slip #${widget.slip.slipNumber} • Book #${widget.slip.bookNumber}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // If daily collection: Day Selector
                if (isDailyCollection) ...[
                  _buildFieldLabel('Collection Day / Milestone'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickDays.map((d) {
                        final isSel = _dayLabel == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(d, style: TextStyle(color: isSel ? const Color(0xFF070D1E) : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: AppTheme.primaryBlue,
                            backgroundColor: const Color(0x1F1E293B),
                            side: BorderSide(color: isSel ? AppTheme.primaryBlue : AppTheme.glassBorder),
                            onSelected: (val) {
                              if (val) setState(() => _dayLabel = d);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Book Number & Slip Number (Editable)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Book No. *'),
                          TextFormField(
                            controller: _bookNoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: _inputDecoration('e.g. 1', Icons.menu_book),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('SL / Slip No. *'),
                          TextFormField(
                            controller: _slipNoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: _inputDecoration('e.g. 1', Icons.confirmation_number_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Donor Name / Collection Label
                _buildFieldLabel(isDailyCollection ? 'Collection Title / Area' : 'Donor / Family / Shop Name *'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    isDailyCollection ? 'e.g. Market Area Collection' : 'e.g. Subhash Banerjee & Family',
                    isDailyCollection ? Icons.location_on_outlined : Icons.person_outline,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Field is required' : null,
                ),
                const SizedBox(height: 14),

                // Amount
                _buildFieldLabel('Collection Amount (₹) *'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: _inputDecoration('e.g. 1001', Icons.currency_rupee),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Book #${widget.slip.bookNumber} totals will automatically adjust from ${currency.format(widget.slip.amount)}.',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 14),

                // Slips count if daily collection
                if (isDailyCollection) ...[
                  _buildFieldLabel('Total Slips Used in this Batch *'),
                  TextFormField(
                    controller: _slipsCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: _inputDecoration('e.g. 15', Icons.receipt_long_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Phone
                if (!isDailyCollection) ...[
                  _buildFieldLabel('WhatsApp / Mobile Number'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('e.g. 9876543210', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                ],

                // Payment Mode
                _buildFieldLabel('Payment Mode'),
                Row(
                  children: [
                    _PaymentModeChip(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: _paymentMode == PaymentMode.cash,
                      onTap: () => setState(() => _paymentMode = PaymentMode.cash),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'UPI / QR',
                      icon: Icons.qr_code_2,
                      selected: _paymentMode == PaymentMode.upi,
                      onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                    ),
                    const SizedBox(width: 8),
                    _PaymentModeChip(
                      label: 'Bank Transfer',
                      icon: Icons.account_balance,
                      selected: _paymentMode == PaymentMode.bankTransfer,
                      onTap: () => setState(() => _paymentMode = PaymentMode.bankTransfer),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address / Notes
                _buildFieldLabel(isDailyCollection ? 'Notes / Details' : 'Flat / Address / Notes'),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. Additional details or area', Icons.home_outlined),
                ),
                const SizedBox(height: 22),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final addressText = _addressController.text.trim();
                        final slipsCount = int.tryParse(_slipsCountController.text.trim()) ?? 1;
                        final customBook = int.tryParse(_bookNoController.text.trim()) ?? widget.slip.bookNumber;
                        final customSlip = int.tryParse(_slipNoController.text.trim()) ?? widget.slip.slipNumber;

                        provider.updateChandaSlip(
                          slipId: widget.slip.id,
                          donorName: _nameController.text.trim(),
                          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                          address: addressText.isNotEmpty ? addressText : null,
                          paymentMode: _paymentMode,
                          notes: widget.slip.notes,
                          dayLabel: isDailyCollection ? _dayLabel : widget.slip.dayLabel,
                          slipsCount: slipsCount,
                          bookNumber: customBook,
                          slipNumber: customSlip,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.cardSurface,
                            content:
                                Text('✅ Collection updated successfully!', style: TextStyle(color: Colors.white)),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Update Record',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.goldAccent, size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
      ),
    );
  }
}

// ==========================================
// 11. VOUCHER ACTIONS (Edit / Delete) DIALOG
// ==========================================
class VoucherActionDialog extends StatelessWidget {
  final ExpenseVoucher expense;

  const VoucherActionDialog({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: expense.category.color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(expense.category.icon, color: expense.category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.payeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${expense.voucherNo} • ${expense.category.displayName}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(expense.date),
                    style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12),
                  ),
                  Text(
                    '-${currency.format(expense.amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: const Color(0xFF070D1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AddExpenseDialog(existing: expense),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRose,
                  side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmDeleteDialog(
                      title: 'Delete Expense Voucher?',
                      message:
                          'Voucher ${expense.voucherNo} for ${expense.payeeName} (${currency.format(expense.amount)}) will be permanently removed from all totals and reports.',
                      onConfirm: () {
                        Provider.of<PujaProvider>(context, listen: false).deleteExpense(expense.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 12. DONOR HISTORY DIALOG
// ==========================================
class DonorHistoryDialog extends StatelessWidget {
  final DonorSummary donor;

  const DonorHistoryDialog({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: GlassContainer(
        maxWidth: 560,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlue.withAlpha(40),
                  child: Text(
                    donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${donor.donationCount} donation${donor.donationCount > 1 ? 's' : ''} • Last: ${dateFormat.format(donor.lastDonation)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Donated Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.successGreen.withAlpha(50), AppTheme.successGreen.withAlpha(15)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.successGreenLight.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL CONTRIBUTION',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(donor.totalDonated),
                    style: const TextStyle(
                      color: AppTheme.successGreenLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Donation History List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: donor.slips.length,
                itemBuilder: (context, index) {
                  final slip = donor.slips[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (slip.paymentMode == PaymentMode.cash ? AppTheme.successGreen : AppTheme.primaryBlue)
                                .withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slip.paymentMode == PaymentMode.cash
                                ? Icons.money
                                : slip.paymentMode == PaymentMode.upi
                                    ? Icons.qr_code_2
                                    : Icons.account_balance,
                            size: 15,
                            color: slip.paymentMode == PaymentMode.cash
                                ? AppTheme.successGreenLight
                                : AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book #${slip.bookNumber} • Slip #${slip.slipNumber} • ${slip.collectedBy}',
                                style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                dateFormat.format(slip.createdAt),
                                style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${currency.format(slip.amount)}',
                          style: const TextStyle(
                            color: AppTheme.successGreenLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 13. ADD / EDIT IN-KIND (SAMAGRI) DONATION DIALOG
// ==========================================
class AddInKindDonationDialog extends StatefulWidget {
  final InKindDonation? existing;
  const AddInKindDonationDialog({super.key, this.existing});

  @override
  State<AddInKindDonationDialog> createState() => _AddInKindDonationDialogState();
}

class _AddInKindDonationDialogState extends State<AddInKindDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _donorNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _estValueController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _notesController = TextEditingController();

  InKindCategory _category = InKindCategory.bhogGroceries;
  DateTime _selectedDate = DateTime.now();

  final List<String> _quickItemSuggestions = [
    '50 Kg Basmati Rice',
    '10L Mustard Oil',
    'Pure Cow Ghee (5 Tins)',
    'Maa Durga Saree (Benarasi)',
    'Purohit Dhoti Set',
    'Maha Bhog Sweets (10 Kg)',
    'Brass Puja Thali & Bell',
    'Generator Diesel (50L)',
    'Sandhi Puja Flowers (108 Lotus)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _donorNameController.text = e.donorName;
      _phoneController.text = e.phone ?? '';
      _itemNameController.text = e.itemName;
      _quantityController.text = e.quantity;
      _estValueController.text = e.estimatedValue != null ? e.estimatedValue!.toStringAsFixed(0) : '';
      _receivedByController.text = e.receivedBy;
      _notesController.text = e.notes ?? '';
      _category = e.category;
      _selectedDate = e.date;
    }
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _phoneController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _estValueController.dispose();
    _receivedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);

    if (_receivedByController.text.isEmpty && widget.existing == null) {
      _receivedByController.text = provider.cashierName;
    }

    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 560,
        borderRadius: 28,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit In-Kind Donation' : 'Record In-Kind Donation',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'In-Kind Donations (Goods, Materials & Supplies)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 1. Donor Name
                _buildFieldLabel('Donor / Sponsor / Family Name *'),
                TextFormField(
                  controller: _donorNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. Ramesh Ghosh & Family / ABC Sweets', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter donor name' : null,
                ),
                const SizedBox(height: 14),

                // 2. Item Name & Quick Suggestions
                _buildFieldLabel('Donated Item / Material Name *'),
                TextFormField(
                  controller: _itemNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: _inputDecoration('e.g. 50 Kg Basmati Rice', Icons.card_giftcard),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter item name' : null,
                ),
                const SizedBox(height: 8),

                // Quick Item Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickItemSuggestions.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: const Color(0x1F1E293B),
                          side: const BorderSide(color: AppTheme.glassBorder),
                          label: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _itemNameController.text = item;
                              if (item.contains('Rice') || item.contains('Oil') || item.contains('Ghee') || item.contains('Sweets')) {
                                _category = InKindCategory.bhogGroceries;
                              } else if (item.contains('Saree') || item.contains('Dhoti')) {
                                _category = InKindCategory.murtiDressOrnaments;
                              } else if (item.contains('Diesel') || item.contains('Sound')) {
                                _category = InKindCategory.decorLighting;
                              } else if (item.contains('Flowers') || item.contains('Thali')) {
                                _category = InKindCategory.pujaSamagri;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Category Selector
                _buildFieldLabel('Category'),
                DropdownButtonFormField<InKindCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: _inputDecoration('Category', Icons.category_outlined),
                  items: InKindCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.displayName,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 14),

                // 4. Quantity & Estimated Value
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Quantity / Units *'),
                          TextFormField(
                            controller: _quantityController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration('e.g. 50 Kg / 2 Pcs', Icons.scale_outlined),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter quantity' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Approx Value (₹)'),
                          TextFormField(
                            controller: _estValueController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration('Optional est. ₹', Icons.currency_rupee),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. WhatsApp & Received By
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Donor Mobile (Optional)'),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('9876543210', Icons.phone_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Received By *'),
                          TextFormField(
                            controller: _receivedByController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('Volunteer Name', Icons.badge_outlined),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter receiver name' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 6. Notes
                _buildFieldLabel('Purpose / Specific Puja Notes (Optional)'),
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('e.g. For Ashtami Maha Bhog / Pratima decoration', Icons.notes),
                ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final donor = _donorNameController.text.trim();
                        final item = _itemNameController.text.trim();
                        final qty = _quantityController.text.trim();
                        final estVal = double.tryParse(_estValueController.text.trim());
                        final receiver = _receivedByController.text.trim();
                        final phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
                        final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

                        if (isEdit) {
                          provider.updateInKindDonation(
                            id: widget.existing!.id,
                            donorName: donor,
                            phone: phone,
                            itemName: item,
                            category: _category,
                            quantity: qty,
                            estimatedValue: estVal,
                            receivedBy: receiver,
                            notes: notes,
                          );
                        } else {
                          provider.addInKindDonation(
                            donorName: donor,
                            phone: phone,
                            itemName: item,
                            category: _category,
                            quantity: qty,
                            estimatedValue: estVal,
                            receivedBy: receiver,
                            notes: notes,
                            date: _selectedDate,
                          );
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text(
                              isEdit ? '✅ In-Kind donation updated!' : '✅ In-Kind donation ($item) recorded successfully!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'Update In-Kind Entry' : 'Save In-Kind Donation',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      filled: true,
      fillColor: const Color(0xD9081022),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
    );
  }
}

// ==========================================
// 14. IN-KIND DONATION ACTION & VIEW DIALOG
// ==========================================
class InKindActionDialog extends StatelessWidget {
  final InKindDonation item;

  const InKindActionDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.category.color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.category.icon, color: item.category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.quantity} • ${item.category.displayName.split(' (')[0]}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Donor / Sponsor:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(item.donorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (item.phone != null && item.phone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mobile:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(item.phone!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (item.estimatedValue != null && item.estimatedValue! > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Value:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(currency.format(item.estimatedValue!), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Received By:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(item.receivedBy, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(DateFormat('dd MMM yyyy').format(item.date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const Divider(color: AppTheme.glassBorder, height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Notes: ${item.notes}', style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Edit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: const Color(0xFF070D1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Donation Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AddInKindDonationDialog(existing: item),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRose,
                  side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete In-Kind Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmDeleteDialog(
                      title: 'Delete In-Kind Record?',
                      message: 'In-kind contribution "${item.itemName}" from ${item.donorName} will be removed.',
                      onConfirm: () {
                        Provider.of<PujaProvider>(context, listen: false).deleteInKindDonation(item.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 17. BOOK ACTION (View, Edit & Delete) DIALOG
// ==========================================
class BookActionDialog extends StatelessWidget {
  final ChandaBook book;

  const BookActionDialog({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context, listen: false);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final progress = book.totalSlips > 0 ? (book.usedSlips / book.totalSlips) : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book #${book.bookNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Assigned to ${book.assignedTo}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Collected:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(currency.format(book.totalCollected), style: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Slips Range:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text('#${book.startSlip} - #${book.endSlip} (${book.totalSlips} slips)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Usage:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text('${book.usedSlips} used (${(progress * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  if (book.collectorPhone != null && book.collectorPhone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Collector Phone:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(book.collectorPhone!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Edit Book button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: const Color(0xFF070D1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Book Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AddBookDialog(existing: book),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Delete Book button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRose,
                  side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmDeleteDialog(
                      title: 'Delete Book #${book.bookNumber}?',
                      message: 'Book #${book.bookNumber} assigned to ${book.assignedTo} will be permanently removed.',
                      onConfirm: () {
                        provider.deleteBook(book.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 18. ADVANCE ACTION (View, Edit, Delete & Settle) DIALOG
// ==========================================
class AdvanceActionDialog extends StatelessWidget {
  final MemberAdvance advance;

  const AdvanceActionDialog({super.key, required this.advance});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context, listen: false);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isPending = advance.status == 'Pending';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        maxWidth: 480,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wallet, color: AppTheme.goldAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advance.memberName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${advance.category.displayName} • ${DateFormat('dd MMM yyyy').format(advance.dateGiven)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advance Given:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(currency.format(advance.advanceAmount), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPending ? AppTheme.goldAccent.withAlpha(30) : AppTheme.successGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPending ? 'Pending Settlement' : 'Settled',
                          style: TextStyle(
                            color: isPending ? AppTheme.goldAccent : AppTheme.successGreenLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purpose:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advance.purpose,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!isPending && advance.actualSpent != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Actual Spent:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(currency.format(advance.actualSpent!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Settle button if pending
            if (isPending) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreenLight,
                    foregroundColor: const Color(0xFF070D1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.fact_check, size: 18),
                  label: const Text('Settle Advance & Cash Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => SettleAdvanceDialog(advance: advance),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Edit Advance button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: const Color(0xFF070D1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Advance Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => GiveAdvanceDialog(existing: advance),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Delete Advance button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRose,
                  side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Advance Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmDeleteDialog(
                      title: 'Delete Advance Record?',
                      message: 'Advance of ${currency.format(advance.advanceAmount)} to ${advance.memberName} will be permanently removed.',
                      onConfirm: () {
                        provider.deleteAdvance(advance.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BILL / INVOICE IMAGE PREVIEW & ATTACHMENT
// ==========================================

/// Warning confirmation dialog before deleting an attached image/slip/bill photo
Future<bool> showConfirmDeleteImageDialog(
  BuildContext context, {
  String title = 'Delete Photo?',
  String message = 'Are you sure you want to delete this attached photo? This action cannot be undone.',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorderLight),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.dangerRose.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRose, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerRose,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 16),
          label: const Text('Delete Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

class BillImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onDelete;
  final VoidCallback? onReplace;

  const BillImagePreviewDialog({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onDelete,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        maxWidth: 600,
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Zoomable Image Container
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppTheme.primaryBlue),
                              const SizedBox(height: 12),
                              Text(
                                'Loading bill image...',
                                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_rounded, color: AppTheme.dangerRose, size: 40),
                              const SizedBox(height: 8),
                              const Text('Unable to load image', style: TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                imageUrl,
                                style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Actions Bottom Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Open in Browser', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      try {
                        final uri = Uri.parse(imageUrl.trim());
                        bool launched = false;
                        try {
                          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                        if (!launched) {
                          try {
                            launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                          } catch (_) {}
                        }
                        if (!launched) {
                          try {
                            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                          } catch (_) {}
                        }
                        if (!launched && context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: imageUrl.trim()));
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F172A),
                              content: const Row(
                                children: [
                                  Icon(Icons.content_copy, color: AppTheme.primaryBlue, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Could not open browser directly. Link copied to clipboard!',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error launching URL: $e');
                      }
                    },
                  ),
                ),
                if (onReplace != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldAccent,
                      side: const BorderSide(color: AppTheme.goldAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      onReplace!();
                    },
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRose,
                      side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final confirmed = await showConfirmDeleteImageDialog(
                        context,
                        title: 'Delete Attached Photo?',
                        message: 'Are you sure you want to remove this attached photo? This action cannot be undone.',
                      );
                      if (confirmed && context.mounted) {
                        Navigator.pop(context);
                        onDelete!();
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAttachBillModal(
  BuildContext context, {
  required Function(String publicUrl) onUploaded,
  VoidCallback? onDeleted,
  String? existingUrl,
  String title = 'Attach Bill / Invoice Photo',
  String subtitle = 'Photos are auto-compressed (Full HD quality) and saved securely in cloud.',
  String folder = 'bills',
  IconData icon = Icons.receipt_long_rounded,
  String removeTitle = 'Remove Current Bill',
  String removeSubtitle = 'Delete attached receipt from this transaction',
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (modalCtx) => Material(
      color: const Color(0xFF0F172A),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.glassBorderLight),
            left: BorderSide(color: AppTheme.glassBorderLight),
            right: BorderSide(color: AppTheme.glassBorderLight),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Camera Option
              Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  tileColor: const Color(0x1F1E293B),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('Take Photo from Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Capture paper document or invoice directly', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(modalCtx);
                    await handlePickAndUploadBill(
                      context,
                      ImageSource.camera,
                      onUploaded,
                      folder: folder,
                      loadingTitle: folder == 'slips' ? 'Uploading Slip Photo...' : 'Uploading Bill Photo...',
                      successMessage: folder == 'slips' ? '✅ Slip photo attached' : '✅ Bill photo attached',
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Gallery Option
              Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  tileColor: const Color(0x1F1E293B),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Select image or screenshot from device', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(modalCtx);
                    await handlePickAndUploadBill(
                      context,
                      ImageSource.gallery,
                      onUploaded,
                      folder: folder,
                      loadingTitle: folder == 'slips' ? 'Uploading Slip Photo...' : 'Uploading Bill Photo...',
                      successMessage: folder == 'slips' ? '✅ Slip photo attached' : '✅ Bill photo attached',
                    );
                  },
                ),
              ),

              if (existingUrl != null && existingUrl.isNotEmpty && onDeleted != null) ...[
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppTheme.dangerRose.withAlpha(80)),
                    ),
                    tileColor: AppTheme.dangerRose.withAlpha(15),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRose.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose),
                    ),
                    title: Text(removeTitle, style: const TextStyle(color: AppTheme.dangerRose, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(removeSubtitle, style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11)),
                    onTap: () async {
                      final confirmed = await showConfirmDeleteImageDialog(
                        modalCtx,
                        title: removeTitle,
                        message: 'Are you sure you want to remove this attached image?',
                      );
                      if (confirmed && modalCtx.mounted) {
                        Navigator.pop(modalCtx);
                        onDeleted();
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAttachSlipModal(
  BuildContext context, {
  required Function(String publicUrl) onUploaded,
  VoidCallback? onDeleted,
  String? existingUrl,
}) =>
    showAttachBillModal(
      context,
      onUploaded: onUploaded,
      onDeleted: onDeleted,
      existingUrl: existingUrl,
      title: 'Attach Chanda Slip Photo',
      subtitle: 'Slip photo is auto-compressed (Full HD) and saved securely in cloud.',
      folder: 'slips',
      icon: Icons.receipt_rounded,
      removeTitle: 'Remove Attached Slip Photo',
      removeSubtitle: 'Delete attached slip image from this donation',
    );

Future<void> handlePickAndUploadBill(
  BuildContext context,
  ImageSource source,
  Function(String publicUrl) onUploaded, {
  String folder = 'bills',
  String? loadingTitle,
  String? successMessage,
}) async {
  // 1. Pick raw image file from Camera or Gallery
  final pickedFile = await R2StorageService.pickRawImage(source: source);
  if (pickedFile == null) return; // User cancelled picker

  if (!context.mounted) return;

  // 2. Dynamic 2-phase progress dialog state (Compressing -> Uploading)
  final ValueNotifier<String> phaseTitle = ValueNotifier<String>(
    folder == 'slips' ? '⚡ Compressing Slip Photo...' : '⚡ Compressing Bill Photo...',
  );
  final ValueNotifier<String> phaseSubtitle = ValueNotifier<String>(
    'Optimizing resolution to Full HD (JPEG 82%)...',
  );
  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);

  // Show Dynamic Progress Dialog IMMEDIATELY
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (loadingCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: AnimatedBuilder(
          animation: Listenable.merge([phaseTitle, phaseSubtitle, isUploading]),
          builder: (context, _) {
            final uploading = isUploading.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: uploading ? const Color(0xFF10B981) : AppTheme.primaryBlue,
                      ),
                    ),
                    Icon(
                      uploading ? Icons.cloud_upload_rounded : Icons.auto_fix_high_rounded,
                      color: uploading ? const Color(0xFF10B981) : AppTheme.primaryBlue,
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  phaseTitle.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14.5),
                ),
                const SizedBox(height: 8),
                Text(
                  phaseSubtitle.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: uploading ? AppTheme.successGreen : Colors.white.withAlpha(160),
                    fontSize: 12,
                    fontWeight: uploading ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  try {
    // 3. Compress using background isolate (UI never freezes)
    final result = await R2StorageService.compressPickedFile(pickedFile);

    // 4. Switch dialog to Uploading phase with compression savings
    phaseTitle.value = loadingTitle ?? (folder == 'slips' ? 'Uploading Slip to Cloud...' : 'Uploading Bill to Cloud...');
    phaseSubtitle.value = result.summaryLabel;
    isUploading.value = true;

    // 5. Upload to Cloudflare R2
    final publicUrl = await R2StorageService.uploadBillImage(
      imageBytes: result.compressedBytes,
      customFileName: result.fileName,
      folder: folder,
    );

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
      onUploaded(publicUrl);
      final msg = successMessage ?? (folder == 'slips' ? '✅ Slip photo attached' : '✅ Bill photo attached');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: AppTheme.successGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$msg (${result.summaryLabel})',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.dangerRose,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Upload failed: $e', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}



