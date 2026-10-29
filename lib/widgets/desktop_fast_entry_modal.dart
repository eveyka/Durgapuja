import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/desktop_controller.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class DesktopFastEntryModal extends StatefulWidget {
  final QuickEntryType initialType;

  const DesktopFastEntryModal({super.key, required this.initialType});

  @override
  State<DesktopFastEntryModal> createState() => _DesktopFastEntryModalState();
}

class _DesktopFastEntryModalState extends State<DesktopFastEntryModal> {
  late QuickEntryType _entryType;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _purposeController = TextEditingController();

  // Focus Nodes for Keyboard Navigation
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _noteFocus = FocusNode();

  PaymentMode _paymentMode = PaymentMode.cash;
  ExpenseCategory _expenseCategory = ExpenseCategory.securityMisc;
  bool _autoPrintReceipt = false;
  bool _isSubmitting = false;

  final List<int> _quickAmounts = [101, 251, 501, 1001, 2100, 5001, 11000];

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _purposeController.dispose();
    _nameFocus.dispose();
    _amountFocus.dispose();
    _phoneFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _applyQuickAmount(int amount) {
    _amountController.text = amount.toString();
    _phoneFocus.requestFocus();
  }

  Future<void> _submit(PujaProvider provider, {bool resetForNext = false}) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final activeEvent = provider.selectedEvent;

      if (_entryType == QuickEntryType.chanda) {
        final slip = provider.addDonation(
          donorName: _nameController.text.trim(),
          amount: amount,
          status: DonationStatus.paid,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          paymentMode: _paymentMode,
          collectedBy: provider.cashierName,
          notes: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          eventId: activeEvent?.id,
        );

        if (_autoPrintReceipt && mounted) {
          ReceiptShareService.printSlipPdf(
            slip: slip,
            pujaName: provider.pujaName,
            currentYear: provider.currentYear,
            cashierName: provider.cashierName,
          );
        }
      } else if (_entryType == QuickEntryType.expense) {
        provider.addExpense(
          payeeName: _nameController.text.trim(),
          amount: amount,
          category: _expenseCategory,
          paymentMode: _paymentMode,
          paidBy: provider.cashierName,
          description: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          eventId: activeEvent?.id,
        );
      } else if (_entryType == QuickEntryType.advance) {
        provider.giveAdvance(
          memberName: _nameController.text.trim(),
          amount: amount,
          originalAmount: amount,
          purpose: _purposeController.text.trim().isNotEmpty ? _purposeController.text.trim() : 'Event Advance',
          category: _expenseCategory,
          paymentMode: _paymentMode,
          eventId: activeEvent?.id,
        );
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(
                  '${_entryType == QuickEntryType.chanda ? "Collection Slip" : _entryType == QuickEntryType.expense ? "Expense Voucher" : "Advance"} saved successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (resetForNext) {
          setState(() {
            _nameController.clear();
            _amountController.clear();
            _phoneController.clear();
            _addressController.clear();
            _noteController.clear();
            _purposeController.clear();
            _isSubmitting = false;
          });
          _nameFocus.requestFocus();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final activeEvent = provider.selectedEvent;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.pop(context),
          ),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _submit(provider, resetForNext: true),
          ),
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar with Type Segmented Control
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _entryType == QuickEntryType.chanda
                                ? AppTheme.successGreen.withAlpha(30)
                                : _entryType == QuickEntryType.expense
                                    ? AppTheme.dangerRose.withAlpha(30)
                                    : AppTheme.goldAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _entryType == QuickEntryType.chanda
                                ? Icons.account_balance_wallet_rounded
                                : _entryType == QuickEntryType.expense
                                    ? Icons.receipt_long_rounded
                                    : Icons.handshake_rounded,
                            color: _entryType == QuickEntryType.chanda
                                ? AppTheme.successGreen
                                : _entryType == QuickEntryType.expense
                                    ? AppTheme.dangerRose
                                    : AppTheme.goldAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'PC Rapid Entry Terminal',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                                    ),
                                    child: const Text('POS Mode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ),
                                ],
                              ),
                              Text(
                                activeEvent != null ? '${activeEvent.name} (${activeEvent.year})' : 'All Festivals',
                                style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Segmented Button for Chanda vs Expense vs Advance
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(QuickEntryType.chanda, 'Collection (F2)', Icons.add_circle_outline_rounded, AppTheme.successGreen),
                          _buildTypeTab(QuickEntryType.expense, 'Expense Voucher (F3)', Icons.remove_circle_outline_rounded, AppTheme.dangerRose),
                          _buildTypeTab(QuickEntryType.advance, 'Advance (F4)', Icons.hourglass_top_rounded, AppTheme.goldAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Form Fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Name and Amount Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _nameController,
                                    focusNode: _nameFocus,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => _amountFocus.requestFocus(),
                                    decoration: InputDecoration(
                                      labelText: _entryType == QuickEntryType.chanda
                                          ? 'Donor / Member Name *'
                                          : _entryType == QuickEntryType.expense
                                              ? 'Payee / Vendor Name *'
                                              : 'Member Name *',
                                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _amountController,
                                    focusNode: _amountFocus,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Amount (₹) *',
                                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Quick Amount Pills
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _quickAmounts.map((amt) {
                                return ActionChip(
                                  label: Text('₹$amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: const Color(0x1F1E293B),
                                  side: BorderSide(color: AppTheme.primaryBlue.withAlpha(50)),
                                  onPressed: () => _applyQuickAmount(amt),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // 2. Category / Phone / Purpose Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_entryType == QuickEntryType.chanda) ...[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _noteFocus.requestFocus(),
                                      decoration: const InputDecoration(
                                        labelText: 'Phone Number (Optional)',
                                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _addressController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Address / Flat / Mohalla',
                                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: DropdownButtonFormField<ExpenseCategory>(
                                      initialValue: _expenseCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                                      ),
                                      items: ExpenseCategory.values.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat.displayName, style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (cat) {
                                        if (cat != null) setState(() => _expenseCategory = cat);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _purposeController,
                                      decoration: InputDecoration(
                                        labelText: _entryType == QuickEntryType.advance ? 'Advance Purpose' : 'Bill / Memo No.',
                                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 3. Payment Mode Selector
                            Row(
                              children: [
                                const Text('Payment Mode: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(width: 10),
                                ...PaymentMode.values.map((mode) {
                                  final isSelected = _paymentMode == mode;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(mode.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      selected: isSelected,
                                      selectedColor: AppTheme.primaryBlue.withAlpha(60),
                                      side: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.white24),
                                      onSelected: (selected) {
                                        if (selected) setState(() => _paymentMode = mode);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Notes / Remarks
                            TextFormField(
                              controller: _noteController,
                              focusNode: _noteFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(provider),
                              decoration: const InputDecoration(
                                labelText: 'Notes / Remarks (Press Enter to Save)',
                                prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                              ),
                            ),

                            if (_entryType == QuickEntryType.chanda) ...[
                              const SizedBox(height: 10),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Auto-print receipt after save', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                value: _autoPrintReceipt,
                                activeColor: AppTheme.primaryBlue,
                                onChanged: (v) => setState(() => _autoPrintReceipt = v ?? false),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shortcuts: Ctrl+Enter (Save & Next) • Enter (Save)',
                          style: TextStyle(fontSize: 10.5, color: Colors.white38),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.glassBorder),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel (Esc)', style: TextStyle(color: Colors.white70)),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primaryBlue.withAlpha(120)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add_task_rounded, size: 16, color: AppTheme.primaryBlue),
                              label: const Text('Save & Next (Ctrl+Enter)', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                              onPressed: _isSubmitting ? null : () => _submit(provider, resetForNext: true),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _entryType == QuickEntryType.chanda
                                    ? AppTheme.successGreen
                                    : _entryType == QuickEntryType.expense
                                        ? AppTheme.dangerRose
                                        : AppTheme.goldAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(_isSubmitting ? 'Saving...' : 'Save Record', style: const TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _isSubmitting ? null : () => _submit(provider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(QuickEntryType type, String label, IconData icon, Color color) {
    final isSelected = _entryType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _entryType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color.withAlpha(120) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
