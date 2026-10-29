import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

// ============================================================================
// 1. ADD / EDIT COLLECTION ACCOUNT DIALOG
// Fields: Account Name, Collection Area Name, Collector Name (Optional), Target
// ============================================================================
class AddCollectionAccountDialog extends StatefulWidget {
  final CollectionAccount? existing;
  final String? initialEventId;

  const AddCollectionAccountDialog({super.key, this.existing, this.initialEventId});

  @override
  State<AddCollectionAccountDialog> createState() => _AddCollectionAccountDialogState();
}

class _AddCollectionAccountDialogState extends State<AddCollectionAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  final _accountNameController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _collectorNameController = TextEditingController();
  final _collectorPhoneController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _notesController = TextEditingController();

  // Chanda Book & Serial Number Range Controllers
  final _bookNumberController = TextEditingController();
  final _startSlipController = TextEditingController();
  final _endSlipController = TextEditingController();

  final List<String> _quickPresets = [
    'Main Market Collection',
    'Ward No. 4 Residential',
    'VIP Road & Complex',
    'Station Road Commercial',
    'North Para Door-to-Door',
    'Youth Committee Drive',
  ];

  final List<Map<String, dynamic>> _slipPresets = [
    {'label': '1 - 50 (50 Slips)', 'start': 1, 'end': 50},
    {'label': '1 - 100 (100 Slips)', 'start': 1, 'end': 100},
    {'label': '51 - 100 (50 Slips)', 'start': 51, 'end': 100},
    {'label': '101 - 150 (50 Slips)', 'start': 101, 'end': 150},
    {'label': '101 - 200 (100 Slips)', 'start': 101, 'end': 200},
    {'label': '151 - 200 (50 Slips)', 'start': 151, 'end': 200},
  ];

  @override
  void initState() {
    super.initState();
    final ext = widget.existing;
    if (ext != null) {
      _accountNameController.text = ext.accountName;
      _areaNameController.text = ext.areaName;
      _collectorNameController.text = ext.collectorName ?? '';
      _collectorPhoneController.text = ext.collectorPhone ?? '';
      _targetAmountController.text = ext.targetAmount != null ? ext.targetAmount!.toStringAsFixed(0) : '';
      _bookNumberController.text = (ext.bookNumber ?? 1).toString();
      _startSlipController.text = (ext.startSlip ?? 1).toString();
      _endSlipController.text = (ext.endSlip ?? 50).toString();
      _notesController.text = ext.notes ?? '';
    } else {
      _startSlipController.text = '1';
      _endSlipController.text = '50';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<PujaProvider>(context, listen: false);
          _bookNumberController.text = provider.getNextSuggestedBookNumber().toString();
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _areaNameController.dispose();
    _collectorNameController.dispose();
    _collectorPhoneController.dispose();
    _targetAmountController.dispose();
    _bookNumberController.dispose();
    _startSlipController.dispose();
    _endSlipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _accountNameController.text = preset;
      if (preset.contains('Market') || preset.contains('Commercial')) {
        _areaNameController.text = 'Market Complex';
      } else if (preset.contains('Road')) {
        _areaNameController.text = 'Main Road Belt';
      } else if (preset.contains('Ward')) {
        _areaNameController.text = 'Ward Area';
      } else if (preset.contains('Para')) {
        _areaNameController.text = 'North Para Sector';
      }
    });
  }

  void _applySlipPreset(int start, int end) {
    setState(() {
      _startSlipController.text = start.toString();
      _endSlipController.text = end.toString();
    });
  }

  int get _calculatedTotalSlips {
    final s = int.tryParse(_startSlipController.text.trim()) ?? 1;
    final e = int.tryParse(_endSlipController.text.trim()) ?? 50;
    return (e >= s) ? (e - s + 1) : 0;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PujaProvider>(context, listen: false);
    final targetAmt = double.tryParse(_targetAmountController.text.trim());
    final bookNum = int.tryParse(_bookNumberController.text.trim()) ?? 1;
    final startSlip = int.tryParse(_startSlipController.text.trim()) ?? 1;
    final endSlip = int.tryParse(_endSlipController.text.trim()) ?? 50;

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        accountName: _accountNameController.text.trim(),
        areaName: _areaNameController.text.trim(),
        collectorName: _collectorNameController.text.trim().isNotEmpty ? _collectorNameController.text.trim() : null,
        collectorPhone: _collectorPhoneController.text.trim().isNotEmpty ? _collectorPhoneController.text.trim() : null,
        targetAmount: targetAmt,
        bookNumber: bookNum,
        startSlip: startSlip,
        endSlip: endSlip,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        clearCollector: _collectorNameController.text.trim().isEmpty,
      );
      provider.updateCollectionAccount(updated);
      Navigator.pop(context, updated);
    } else {
      final created = provider.addCollectionAccount(
        accountName: _accountNameController.text.trim(),
        areaName: _areaNameController.text.trim(),
        collectorName: _collectorNameController.text.trim().isNotEmpty ? _collectorNameController.text.trim() : null,
        collectorPhone: _collectorPhoneController.text.trim().isNotEmpty ? _collectorPhoneController.text.trim() : null,
        targetAmount: targetAmt,
        bookNumber: bookNum,
        startSlip: startSlip,
        endSlip: endSlip,
        eventId: widget.initialEventId ?? provider.selectedEventId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(120), width: 1.4),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withAlpha(70),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Collection A/C' : 'Add Collection A/C',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Area & Collector Chanda Book Account',
                            style: TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Presets (Horizontal Chips)
                if (!isEditing) ...[
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickPresets.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(preset, style: const TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: const Color(0x221E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            onPressed: () => _applyPreset(preset),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. Account Name (Required)
                const Text(
                  'Account Name *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Main Market Collection, Ward 4, VIP Road',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 13),
                    prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF10B981), size: 19),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an account name' : null,
                ),
                const SizedBox(height: 14),

                // 2. Collection Area Name (Required)
                const Text(
                  'Collection Area Name *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _areaNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Station Road, North Para, Sector 5, Bazar Area',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 13),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF10B981), size: 19),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter collection area name' : null,
                ),
                const SizedBox(height: 16),

                // ============================================================
                // BOOK NO. AND SERIAL NUMBER (SL NO.) ALLOCATION SECTION
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x1F0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(80), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 17),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chanda Book & SL. No. Range *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Set Book Number and Receipt Serial (SL) Range',
                                  style: TextStyle(fontSize: 10.5, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          // Live allocation count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
                            ),
                            child: Text(
                              '$_calculatedTotalSlips Slips',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Range Presets
                      const Text(
                        'Quick SL Presets:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _slipPresets.map((preset) {
                            final isSel = _startSlipController.text == preset['start'].toString() &&
                                _endSlipController.text == preset['end'].toString();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => _applySlipPreset(preset['start'], preset['end']),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF10B981).withAlpha(45) : const Color(0x221E293B),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF10B981) : AppTheme.glassBorder,
                                    ),
                                  ),
                                  child: Text(
                                    preset['label'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Book Number, Start SL, End SL Inputs
                      Row(
                        children: [
                          // Book Number
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Book No. *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _bookNumberController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: '1',
                                    prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF10B981), size: 16),
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Start SL No.
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start SL *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _startSlipController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: '1',
                                    prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white54, size: 16),
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // End SL No.
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End SL *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _endSlipController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: '50',
                                    prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white54, size: 16),
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    final s = int.tryParse(_startSlipController.text.trim()) ?? 1;
                                    final e = int.tryParse(val.trim()) ?? 0;
                                    if (e < s) return 'Must be >= Start';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Collector Name (Optional - clearly highlighted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collector Name',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                      child: const Text(
                        'OPTIONAL',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _collectorNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul Sharma, Amit Das (Optional)',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 19),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Collector Phone (Optional) & Target Goal
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collector Phone',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _collectorPhoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Mobile No.',
                              hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.phone_rounded, color: Colors.white60, size: 17),
                              filled: true,
                              fillColor: const Color(0xD9081022),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Goal (₹)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'e.g. 50000',
                              hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 17),
                              filled: true,
                              fillColor: const Color(0xD9081022),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Notes / Description
                const Text(
                  'Remarks / Notes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Additional details or guidelines for this collection area...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.glassBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _save,
                        child: Text(
                          isEditing ? 'Update Account' : 'Create Account',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ADD / EDIT EXPENDITURE ACCOUNT DIALOG
// Fields: Account Name, Category, In-Charge (Optional), Budget
// ============================================================================
class AddExpenditureAccountDialog extends StatefulWidget {
  final ExpenditureAccount? existing;
  final String? initialEventId;

  const AddExpenditureAccountDialog({super.key, this.existing, this.initialEventId});

  @override
  State<AddExpenditureAccountDialog> createState() => _AddExpenditureAccountDialogState();
}

class _AddExpenditureAccountDialogState extends State<AddExpenditureAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  final _accountNameController = TextEditingController();
  final _inChargeNameController = TextEditingController();
  final _allocatedBudgetController = TextEditingController();
  final _notesController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.pandal;

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Mandap & Pandal Decor', 'cat': ExpenseCategory.pandal},
    {'name': 'Lighting & Electric Setup', 'cat': ExpenseCategory.lighting},
    {'name': 'Pooja Samagri & Purohit', 'cat': ExpenseCategory.pujaSamagri},
    {'name': 'Bhog, Prasad & Catering', 'cat': ExpenseCategory.bhogCatering},
    {'name': 'Sound & DJ Management', 'cat': ExpenseCategory.soundDhaki},
    {'name': 'Idol / Pratima Nirman', 'cat': ExpenseCategory.murti},
  ];

  @override
  void initState() {
    super.initState();
    final ext = widget.existing;
    if (ext != null) {
      _accountNameController.text = ext.accountName;
      _category = ext.category;
      _inChargeNameController.text = ext.inChargeName ?? '';
      _allocatedBudgetController.text = ext.allocatedBudget != null ? ext.allocatedBudget!.toStringAsFixed(0) : '';
      _notesController.text = ext.notes ?? '';
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _inChargeNameController.dispose();
    _allocatedBudgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PujaProvider>(context, listen: false);
    final budgetAmt = double.tryParse(_allocatedBudgetController.text.trim());

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        accountName: _accountNameController.text.trim(),
        category: _category,
        inChargeName: _inChargeNameController.text.trim().isNotEmpty ? _inChargeNameController.text.trim() : null,
        allocatedBudget: budgetAmt,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      provider.updateExpenditureAccount(updated);
      Navigator.pop(context, updated);
    } else {
      final created = provider.addExpenditureAccount(
        accountName: _accountNameController.text.trim(),
        category: _category,
        inChargeName: _inChargeNameController.text.trim().isNotEmpty ? _inChargeNameController.text.trim() : null,
        allocatedBudget: budgetAmt,
        eventId: widget.initialEventId ?? provider.selectedEventId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: const Color(0xFFF43F5E).withAlpha(120), width: 1.4),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBE123C).withAlpha(70),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Expenditure A/C' : 'Add Expenditure A/C',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Department & Expense Head Account',
                            style: TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Presets
                if (!isEditing) ...[
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(p['name'] as String, style: const TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: const Color(0x221E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            onPressed: () {
                              setState(() {
                                _accountNameController.text = p['name'] as String;
                                _category = p['cat'] as ExpenseCategory;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. Account Name
                const Text(
                  'Expenditure Account Name *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Mandap & Decoration A/C, Bhog Committee A/C',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 13),
                    prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFFF43F5E), size: 19),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter account name' : null,
                ),
                const SizedBox(height: 14),

                // 2. Category Dropdown
                const Text(
                  'Expense Category *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<ExpenseCategory>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF43F5E))),
                  ),
                  items: ExpenseCategory.values.map((cat) {
                    return DropdownMenuItem<ExpenseCategory>(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 14),

                // 3. In-Charge Name & Allocated Budget
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('In-Charge Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                              Text('Optional', style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(120))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _inChargeNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. Amit Das',
                              hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white60, size: 17),
                              filled: true,
                              fillColor: const Color(0xD9081022),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF43F5E))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Allocated Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                              Text('Optional', style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(120))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _allocatedBudgetController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'e.g. 50000',
                              hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFF43F5E), size: 17),
                              filled: true,
                              fillColor: const Color(0xD9081022),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF43F5E))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Notes
                const Text('Remarks / Scope of Work', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Vendor agreement details, notes, etc...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF43F5E))),
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.glassBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _save,
                        child: Text(
                          isEditing ? 'Update Account' : 'Create Account',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. ADD CONTRIBUTOR DIALOG (Inside Collection Account)
// Allows adding "Ek ek insan kitna diya, kitna paid, kitna unpaid"
// ============================================================================
class AddContributorDialog extends StatefulWidget {
  final CollectionAccount account;
  final ChandaSlip? existingSlip;

  const AddContributorDialog({super.key, required this.account, this.existingSlip});

  @override
  State<AddContributorDialog> createState() => _AddContributorDialogState();
}

class _AddContributorDialogState extends State<AddContributorDialog> {
  final _formKey = GlobalKey<FormState>();

  final _donorNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _collectorController = TextEditingController();
  final _notesController = TextEditingController();

  // Book No. & SL No. (Receipt Serial Number) System
  int _bookNumber = 1;
  int _selectedSlipNumber = 1;
  final _slipNumberController = TextEditingController();
  bool _showAllSlipsGrid = false;
  Set<int> _usedSlipsSet = {};
  Map<int, String> _slipDonorMap = {};

  // In-Kind / Samagri Fields
  DonationType _donationType = DonationType.cash;
  final _inKindItemController = TextEditingController();
  final _inKindQuantityController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  InKindCategory _inKindCategory = InKindCategory.bhogGroceries;
  bool _showMoreDetails = false;

  DonationStatus _status = DonationStatus.unpaid;
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _selectedDate = DateTime.now();

  final List<int> _quickAmounts = [251, 501, 1001, 2100, 5100, 11000];

  @override
  void initState() {
    super.initState();
    _bookNumber = widget.existingSlip?.bookNumber ?? widget.account.bookNumber ?? 1;

    final s = widget.existingSlip;
    if (s != null) {
      _selectedSlipNumber = s.slipNumber;
      _slipNumberController.text = s.slipNumber.toString();
      _donorNameController.text = s.donorName;
      _phoneController.text = s.phone ?? '';
      _addressController.text = s.address ?? '';
      if ((s.phone != null && s.phone!.isNotEmpty) || (s.address != null && s.address!.isNotEmpty)) {
        _showMoreDetails = true;
      }
      _totalAmountController.text = s.amount > 0 ? s.amount.toStringAsFixed(0) : '';
      _paidAmountController.text = s.paidAmount > 0 ? s.paidAmount.toStringAsFixed(0) : '0';
      _collectorController.text = s.collectedBy;
      _notesController.text = s.notes ?? '';
      _status = s.status;
      _paymentMode = s.paymentMode;
      _selectedDate = s.createdAt;
      _donationType = s.donationType;
      _inKindItemController.text = s.inKindItemName ?? '';
      _inKindQuantityController.text = s.inKindQuantity ?? '';
      if (s.inKindCategory != null) {
        _inKindCategory = s.inKindCategory!;
      }
      if (s.amount > 0) {
        _estimatedValueController.text = s.amount.toStringAsFixed(0);
      }
    } else {
      _collectorController.text = widget.account.collectorName ?? '';
      _paidAmountController.text = '0';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<PujaProvider>(context, listen: false);
        final slips = provider.getAccountSlips(widget.account.id);
        final usedMap = <int, String>{};
        for (final slip in slips) {
          if (widget.existingSlip == null || slip.id != widget.existingSlip!.id) {
            usedMap[slip.slipNumber] = slip.donorName;
          }
        }
        _slipDonorMap = usedMap;
        _usedSlipsSet = usedMap.keys.toSet();

        if (widget.existingSlip == null) {
          final nextSlip = provider.getNextAvailableSlipForAccount(widget.account);
          _selectedSlipNumber = nextSlip;
          _slipNumberController.text = nextSlip.toString();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _collectorController.dispose();
    _notesController.dispose();
    _slipNumberController.dispose();
    _inKindItemController.dispose();
    _inKindQuantityController.dispose();
    _estimatedValueController.dispose();
    super.dispose();
  }

  void _onTotalAmountChanged(String val) {
    setState(() {
      final total = double.tryParse(val.trim()) ?? 0.0;
      if (_status == DonationStatus.paid) {
        _paidAmountController.text = total > 0 ? total.toStringAsFixed(0) : '';
      } else if (_status == DonationStatus.unpaid) {
        _paidAmountController.text = '0';
      }
    });
  }

  void _onEstimatedValueChanged(String val) {
    setState(() {
      final est = double.tryParse(val.trim()) ?? 0.0;
      if (_status == DonationStatus.paid) {
        _paidAmountController.text = est > 0 ? est.toStringAsFixed(0) : '0';
      } else if (_status == DonationStatus.unpaid) {
        _paidAmountController.text = '0';
      } else if (_status == DonationStatus.partial) {
        final curPaid = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
        if (curPaid > est || curPaid == 0) {
          _paidAmountController.text = est > 0 ? (est / 2).toStringAsFixed(0) : '0';
        }
      }
    });
  }

  void _setStatus(DonationStatus newStatus) {
    setState(() {
      _status = newStatus;
      if (_donationType == DonationType.inKind) {
        final est = double.tryParse(_estimatedValueController.text.trim()) ?? 0.0;
        if (_status == DonationStatus.paid) {
          _paidAmountController.text = est > 0 ? est.toStringAsFixed(0) : '0';
        } else if (_status == DonationStatus.unpaid) {
          _paidAmountController.text = '0';
        } else if (_status == DonationStatus.partial) {
          if (_paidAmountController.text == '0' || _paidAmountController.text.isEmpty) {
            _paidAmountController.text = est > 0 ? (est / 2).toStringAsFixed(0) : '0';
          }
        }
      } else {
        final total = double.tryParse(_totalAmountController.text.trim()) ?? 0.0;
        if (_status == DonationStatus.paid) {
          _paidAmountController.text = total > 0 ? total.toStringAsFixed(0) : '';
        } else if (_status == DonationStatus.unpaid) {
          _paidAmountController.text = '0';
        } else if (_status == DonationStatus.partial) {
          if (_paidAmountController.text == '0' || _paidAmountController.text.isEmpty) {
            _paidAmountController.text = (total / 2).toStringAsFixed(0);
          }
        }
      }
    });
  }

  void _pickSlipNumber(int slipNum) {
    setState(() {
      _selectedSlipNumber = slipNum;
      _slipNumberController.text = slipNum.toString();
    });
  }

  double get _currentTotal => _donationType == DonationType.inKind
      ? (double.tryParse(_estimatedValueController.text.trim()) ?? 0.0)
      : (double.tryParse(_totalAmountController.text.trim()) ?? 0.0);

  double get _currentPaid {
    if (_donationType == DonationType.inKind) {
      final est = double.tryParse(_estimatedValueController.text.trim()) ?? 0.0;
      if (_status == DonationStatus.paid) return est;
      if (_status == DonationStatus.unpaid) return 0.0;
      final p = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
      return p > est && est > 0 ? est : p;
    } else {
      return double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    }
  }

  double get _currentUnpaid => (_currentTotal - _currentPaid) > 0 ? (_currentTotal - _currentPaid) : 0.0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PujaProvider>(context, listen: false);
    final chosenSlip = int.tryParse(_slipNumberController.text.trim()) ?? _selectedSlipNumber;

    if (_donationType == DonationType.inKind) {
      final estVal = double.tryParse(_estimatedValueController.text.trim()) ?? 0.0;
      double paidAmt = 0.0;
      if (_status == DonationStatus.paid) {
        paidAmt = estVal;
      } else if (_status == DonationStatus.unpaid) {
        paidAmt = 0.0;
      } else if (_status == DonationStatus.partial) {
        paidAmt = double.tryParse(_paidAmountController.text.trim()) ?? (estVal > 0 ? estVal / 2 : 0.0);
        if (paidAmt > estVal && estVal > 0) paidAmt = estVal;
      }

      if (widget.existingSlip != null) {
        provider.updateDonation(
          id: widget.existingSlip!.id,
          donorName: _donorNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          amount: estVal,
          paidAmount: paidAmt,
          status: _status,
          paymentMode: PaymentMode.cash,
          collectedBy: _collectorController.text.trim().isNotEmpty ? _collectorController.text.trim() : 'Admin',
          slipNumber: chosenSlip,
          bookNumber: _bookNumber,
          date: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          eventId: widget.account.eventId,
          donationType: DonationType.inKind,
          inKindItemName: _inKindItemController.text.trim(),
          inKindCategory: _inKindCategory,
          inKindQuantity: _inKindQuantityController.text.trim().isNotEmpty ? _inKindQuantityController.text.trim() : null,
        );
      } else {
        provider.addDonation(
          donorName: _donorNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          amount: estVal,
          paidAmount: paidAmt,
          status: _status,
          paymentMode: PaymentMode.cash,
          collectedBy: _collectorController.text.trim().isNotEmpty ? _collectorController.text.trim() : (widget.account.collectorName ?? 'Admin'),
          slipNumber: chosenSlip,
          bookNumber: _bookNumber,
          date: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          eventId: widget.account.eventId,
          accountId: widget.account.id,
          accountName: widget.account.accountName,
          donationType: DonationType.inKind,
          inKindItemName: _inKindItemController.text.trim(),
          inKindCategory: _inKindCategory,
          inKindQuantity: _inKindQuantityController.text.trim().isNotEmpty ? _inKindQuantityController.text.trim() : null,
        );
      }
    } else {
      final total = _currentTotal;
      final paid = _currentPaid;

      DonationStatus finalStatus = _status;
      if (paid >= total && total > 0) {
        finalStatus = DonationStatus.paid;
      } else if (paid <= 0) {
        finalStatus = DonationStatus.unpaid;
      } else {
        finalStatus = DonationStatus.partial;
      }

      if (widget.existingSlip != null) {
        provider.updateDonation(
          id: widget.existingSlip!.id,
          donorName: _donorNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          amount: total,
          paidAmount: paid,
          status: finalStatus,
          paymentMode: _paymentMode,
          collectedBy: _collectorController.text.trim().isNotEmpty ? _collectorController.text.trim() : 'Admin',
          slipNumber: chosenSlip,
          bookNumber: _bookNumber,
          date: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          eventId: widget.account.eventId,
          donationType: DonationType.cash,
        );
      } else {
        provider.addDonation(
          donorName: _donorNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          amount: total,
          paidAmount: paid,
          status: finalStatus,
          paymentMode: _paymentMode,
          collectedBy: _collectorController.text.trim().isNotEmpty ? _collectorController.text.trim() : (widget.account.collectorName ?? 'Admin'),
          slipNumber: chosenSlip,
          bookNumber: _bookNumber,
          date: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          eventId: widget.account.eventId,
          accountId: widget.account.id,
          accountName: widget.account.accountName,
          donationType: DonationType.cash,
        );
      }
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isEditing = widget.existingSlip != null;
    final int startSlip = widget.account.startSlip ?? 1;
    final int endSlip = widget.account.endSlip ?? (startSlip + 49);
    final int totalSlips = (endSlip >= startSlip) ? (endSlip - startSlip + 1) : 50;

    // List of available upcoming slips for quick select
    final List<int> quickUpcomingSlips = [];
    for (int i = startSlip; i <= endSlip && quickUpcomingSlips.length < 10; i++) {
      if (!_usedSlipsSet.contains(i)) {
        quickUpcomingSlips.add(i);
      }
    }

    final isEnteredUsed = _usedSlipsSet.contains(_selectedSlipNumber);
    final isEnteredOutOfRange = _selectedSlipNumber < startSlip || _selectedSlipNumber > endSlip;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 540,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(
          color: _donationType == DonationType.inKind
              ? const Color(0xFF8B5CF6).withAlpha(140)
              : const Color(0xFF10B981).withAlpha(120),
          width: 1.4,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _donationType == DonationType.inKind
                            ? const Color(0xFF8B5CF6).withAlpha(30)
                            : const Color(0xFF10B981).withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _donationType == DonationType.inKind
                              ? const Color(0xFF8B5CF6).withAlpha(80)
                              : const Color(0xFF10B981).withAlpha(80),
                        ),
                      ),
                      child: Icon(
                        _donationType == DonationType.inKind
                            ? Icons.inventory_2_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: _donationType == DonationType.inKind
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Contributor Entry'
                                : (_donationType == DonationType.inKind
                                    ? 'Add Kind Offering (Samagri)'
                                    : 'Add Contributor Chanda'),
                            style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.account.accountName,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _donationType == DonationType.inKind
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Donation Type Selector: Cash vs In-Kind
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
                          onTap: () => setState(() => _donationType = DonationType.cash),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: _donationType == DonationType.cash
                                  ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                                  : null,
                              color: _donationType == DonationType.cash ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _donationType == DonationType.cash
                                  ? [BoxShadow(color: const Color(0xFF10B981).withAlpha(80), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments_rounded, size: 16, color: _donationType == DonationType.cash ? Colors.white : Colors.white60),
                                const SizedBox(width: 6),
                                Text(
                                  '💵 Cash Chanda',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _donationType == DonationType.cash ? FontWeight.bold : FontWeight.w500,
                                    color: _donationType == DonationType.cash ? Colors.white : Colors.white70,
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
                          onTap: () => setState(() => _donationType = DonationType.inKind),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: _donationType == DonationType.inKind
                                  ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
                                  : null,
                              color: _donationType == DonationType.inKind ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _donationType == DonationType.inKind
                                  ? [BoxShadow(color: const Color(0xFF8B5CF6).withAlpha(80), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_rounded, size: 16, color: _donationType == DonationType.inKind ? Colors.white : Colors.white60),
                                const SizedBox(width: 6),
                                Text(
                                  '🎁 Kind (Samagri)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _donationType == DonationType.inKind ? FontWeight.bold : FontWeight.w500,
                                    color: _donationType == DonationType.inKind ? Colors.white : Colors.white70,
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
                const SizedBox(height: 14),

                // ============================================================
                // SYSTEMATIC, SLIM & STRUCTURED BOOK NO. & SL NO. BOX
                // ============================================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF062A1F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withAlpha(100),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ROW 1: Header Meta (Book # Badge, Range/Usage Stats, All Slips Toggle Button)
                      Row(
                        children: [
                          // Fixed Book Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 11.5, color: Color(0xFF34D399)),
                                const SizedBox(width: 3.5),
                                Text(
                                  'Book #$_bookNumber',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Range & Usage Stats
                          Expanded(
                            child: Text(
                              'Range: $startSlip - $endSlip • ${_usedSlipsSet.length}/$totalSlips used',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.white.withAlpha(160),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Grid Toggle Button (Fixed Size)
                          InkWell(
                            onTap: () => setState(() => _showAllSlipsGrid = !_showAllSlipsGrid),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 25,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: _showAllSlipsGrid ? const Color(0xFF10B981) : const Color(0x1F1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _showAllSlipsGrid ? const Color(0xFF10B981) : AppTheme.glassBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showAllSlipsGrid ? Icons.close_rounded : Icons.grid_view_rounded,
                                    size: 11.5,
                                    color: _showAllSlipsGrid ? Colors.black : Colors.white70,
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    _showAllSlipsGrid ? 'Close' : 'All Slips ($startSlip-$endSlip)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _showAllSlipsGrid ? Colors.black : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ROW 2: Structured SL Control Strip (Fixed Direct SL Input + Auto Next + Horizontal Quick Slips)
                      Row(
                        children: [
                          // 1. Fixed SL Input Box (Width: 100, Height: 35)
                          SizedBox(
                            width: 100,
                            height: 35,
                            child: TextFormField(
                              controller: _slipNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (val) {
                                final n = int.tryParse(val.trim());
                                if (n != null) {
                                  setState(() => _selectedSlipNumber = n);
                                }
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'SL No.',
                                hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.tag_rounded, color: Color(0xFF38BDF8), size: 14),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 35),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0x3338BDF8)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0x4438BDF8)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 2. Auto-Next Button (Fixed Width: 74, Height: 35)
                          InkWell(
                            onTap: () {
                              final provider = Provider.of<PujaProvider>(context, listen: false);
                              final next = provider.getNextAvailableSlipForAccount(widget.account);
                              _pickSlipNumber(next);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 35,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF34D399)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Next',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 3. Quick Available Slips (Scrollable horizontally in remaining space, Height: 35)
                          Expanded(
                            child: SizedBox(
                              height: 35,
                              child: quickUpcomingSlips.isEmpty
                                  ? Center(
                                      child: Text(
                                        'All book slips used',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120), fontStyle: FontStyle.italic),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: quickUpcomingSlips.length,
                                      separatorBuilder: (context, index) => const SizedBox(width: 4),
                                      itemBuilder: (context, idx) {
                                        final slipNo = quickUpcomingSlips[idx];
                                        final isSelected = _selectedSlipNumber == slipNo;
                                        return InkWell(
                                          onTap: () => _pickSlipNumber(slipNo),
                                          borderRadius: BorderRadius.circular(7),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 140),
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0x1F1E293B),
                                              borderRadius: BorderRadius.circular(7),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF10B981)
                                                    : Colors.white.withAlpha(25),
                                              ),
                                            ),
                                            child: Text(
                                              '#$slipNo',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                                color: isSelected ? Colors.black : Colors.white70,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // Optional: All Slips Full Grid (if expanded)
                      if (_showAllSlipsGrid) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(70),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withAlpha(15)),
                          ),
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: List.generate(totalSlips, (idx) {
                                final slipNum = startSlip + idx;
                                final isUsed = _usedSlipsSet.contains(slipNum);
                                final isSelected = _selectedSlipNumber == slipNum;

                                return Tooltip(
                                  message: isUsed
                                      ? 'SL #$slipNum (Used by: ${_slipDonorMap[slipNum] ?? 'Donor'})'
                                      : 'SL #$slipNum (Available)',
                                  child: InkWell(
                                    onTap: isUsed ? null : () => _pickSlipNumber(slipNum),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 40,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : (isUsed ? Colors.white.withAlpha(8) : const Color(0xFF10B981).withAlpha(18)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF10B981)
                                              : (isUsed ? Colors.white.withAlpha(15) : const Color(0xFF10B981).withAlpha(60)),
                                        ),
                                      ),
                                      child: Text(
                                        '$slipNum',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: (isSelected || isUsed) ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.black : (isUsed ? Colors.white30 : Colors.white),
                                          decoration: isUsed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        // Legend
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGridLegend(const Color(0xFF10B981), 'Selected'),
                              const SizedBox(width: 12),
                              _buildGridLegend(const Color(0xFF10B981).withAlpha(90), 'Available'),
                              const SizedBox(width: 12),
                              _buildGridLegend(Colors.white30, 'Used'),
                            ],
                          ),
                        ),
                      ],

                      // Warnings (Single slim line)
                      if (isEnteredUsed) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 11.5, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'SL #$_selectedSlipNumber is already used by "${_slipDonorMap[_selectedSlipNumber] ?? 'another contributor'}"',
                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isEnteredOutOfRange) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 11.5, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'SL #$_selectedSlipNumber is outside account range ($startSlip - $endSlip)',
                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Contributor / Person Name (Required)
                const Text(
                  'Contributor Name (Insan ka Naam) *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _donorNameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Ramesh Chandra, Sunita Roy',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 13),
                    prefixIcon: Icon(
                      Icons.person,
                      color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                      size: 19,
                    ),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter contributor name' : null,
                ),
                const SizedBox(height: 14),

                // 2. Phone & Address (Hidden by default, shown on "+ More Details")
                if (!_showMoreDetails) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => setState(() => _showMoreDetails = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _donationType == DonationType.inKind
                              ? const Color(0xFF8B5CF6).withAlpha(20)
                              : const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _donationType == DonationType.inKind
                                ? const Color(0xFF8B5CF6).withAlpha(60)
                                : const Color(0xFF10B981).withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 14,
                              color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '+ More Details (Phone No. & Address)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phone No. (WhatsApp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: '10 digits mobile',
                                hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                                prefixIcon: const Icon(Icons.phone_rounded, color: Colors.white60, size: 17),
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Address / Shop No.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _addressController,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'House/Flat/Shop',
                                hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12.5),
                                prefixIcon: const Icon(Icons.home_outlined, color: Colors.white60, size: 17),
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _donationType == DonationType.inKind ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                if (_donationType == DonationType.cash) ...[
                  // 3. Total Chanda Amount (Chanda Diya)
                  const Text(
                    'Total Chanda Amount (Kitna Chanda Diya) *',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    onChanged: _onTotalAmountChanged,
                    decoration: InputDecoration(
                      hintText: '₹ Amount',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 14),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 20),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                    ),
                    validator: (val) {
                      if (_donationType == DonationType.cash) {
                        if (val == null || val.trim().isEmpty) return 'Enter chanda amount';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Amount Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickAmounts.map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              _totalAmountController.text = amt.toString();
                              _onTotalAmountChanged(amt.toString());
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x221E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: Text(
                                '+₹$amt',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Payment Status Segmented Control (Paid / Unpaid / Partial)
                  const Text(
                    'Payment Status (Kitna Paid / Unpaid)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        // Full Paid
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.paid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.paid ? const Color(0xFF10B981).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.paid ? const Color(0xFF10B981) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: _status == DonationStatus.paid ? const Color(0xFF10B981) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Full Paid',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.paid ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.paid ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),

                        // Unpaid (Pending)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.unpaid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_top_rounded, size: 14, color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unpaid / Due',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.unpaid ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.unpaid ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),

                        // Partial Paid
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.partial),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.partial ? const Color(0xFFF59E0B).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.partial ? const Color(0xFFF59E0B) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pie_chart_outline_rounded, size: 14, color: _status == DonationStatus.partial ? const Color(0xFFF59E0B) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Partial',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.partial ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.partial ? Colors.white : Colors.white70,
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
                  const SizedBox(height: 12),

                  // If Partial, show specific Paid input
                  if (_status == DonationStatus.partial) ...[
                    const Text('Paid Amount (Jama Kiya) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Amount paid now',
                        prefixIcon: const Icon(Icons.check, color: Color(0xFF10B981), size: 17),
                        filled: true,
                        fillColor: const Color(0xD9081022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5. Grand Systematic Financial Summary Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1F0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _currentUnpaid > 0 ? const Color(0xFFEF4444).withAlpha(60) : const Color(0xFF10B981).withAlpha(60),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('CHANDA DIYA', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(currency.format(_currentTotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                          ],
                        ),
                        Container(height: 24, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Text('PAID (JAMA)', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(currency.format(_currentPaid), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                          ],
                        ),
                        Container(height: 24, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Text('UNPAID (DUE)', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              currency.format(_currentUnpaid),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _currentUnpaid > 0 ? const Color(0xFFEF4444) : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Payment Mode & Collector Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<PaymentMode>(
                              isExpanded: true,
                              initialValue: _paymentMode,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              ),
                              items: PaymentMode.values.map((m) {
                                return DropdownMenuItem<PaymentMode>(
                                  value: m,
                                  child: Text(
                                    m == PaymentMode.bankTransfer ? 'BANK TRANSFER' : m.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 11.5),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _paymentMode = val);
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
                            const Text('Collector Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _collectorController,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Collector',
                                prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white60, size: 16),
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // IN-KIND / SAMAGRI FORM FIELDS
                  const Text(
                    'Samagri / Item Name *',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _inKindItemController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. 50kg Basmati Rice, Brass Aarti Thali, Silk Saree',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 12.5),
                      prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF8B5CF6), size: 19),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
                    ),
                    validator: (v) {
                      if (_donationType == DonationType.inKind && (v == null || v.trim().isEmpty)) {
                        return 'Please enter Samagri / Item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Samagri Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      Text(
                        _inKindCategory.displayName.split(' (')[0],
                        style: TextStyle(fontSize: 11, color: _inKindCategory.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xD9081022),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InKindCategory>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        value: _inKindCategory,
                        items: InKindCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat.displayName,
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _inKindCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity & Estimated Value
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity / Units *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _inKindQuantityController,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'e.g. 50 kg, 2 sets',
                                hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                                prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFF8B5CF6), size: 17),
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
                              ),
                              validator: (v) {
                                if (_donationType == DonationType.inKind && (v == null || v.trim().isEmpty)) {
                                  return 'Enter quantity';
                                }
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
                            const Text('Est. Value (₹ Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _estimatedValueController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 13.5, fontWeight: FontWeight.bold),
                              onChanged: _onEstimatedValueChanged,
                              decoration: InputDecoration(
                                hintText: '₹ Value',
                                hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 16),
                                filled: true,
                                fillColor: const Color(0xD9081022),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // In-Kind Status Segmented Control (Paid / Unpaid / Partial)
                  const Text(
                    'Offering Status (Samagri Status: Mila / Baki)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        // Full Received (Paid)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.paid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.paid ? const Color(0xFF10B981).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.paid ? const Color(0xFF10B981) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: _status == DonationStatus.paid ? const Color(0xFF10B981) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Full Received',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.paid ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.paid ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),

                        // Unpaid / Promised (Baki)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.unpaid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_top_rounded, size: 14, color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Promised / Due',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.unpaid ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.unpaid ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),

                        // Partial Received
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setStatus(DonationStatus.partial),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _status == DonationStatus.partial ? const Color(0xFFF59E0B).withAlpha(45) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: _status == DonationStatus.partial ? const Color(0xFFF59E0B) : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pie_chart_outline_rounded, size: 14, color: _status == DonationStatus.partial ? const Color(0xFFF59E0B) : Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Partial',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _status == DonationStatus.partial ? FontWeight.bold : FontWeight.normal,
                                      color: _status == DonationStatus.partial ? Colors.white : Colors.white70,
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
                  const SizedBox(height: 12),

                  // If Partial and Est. Value exists, show Partial Paid input
                  if (_status == DonationStatus.partial) ...[
                    const Text('Received Value (₹ Jama Hua) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Value or amount received now (₹)',
                        prefixIcon: const Icon(Icons.check, color: Color(0xFF10B981), size: 17),
                        filled: true,
                        fillColor: const Color(0xD9081022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Grand Systematic Financial Summary Strip (when Est. Value > 0)
                  if (_currentTotal > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _currentUnpaid > 0 ? const Color(0xFFEF4444).withAlpha(60) : const Color(0xFF10B981).withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('EST. VALUE', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(currency.format(_currentTotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                          Container(height: 24, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('RECEIVED (JAMA)', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(currency.format(_currentPaid), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                            ],
                          ),
                          Container(height: 24, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('UNPAID (BAKI)', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                currency.format(_currentUnpaid),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _currentUnpaid > 0 ? const Color(0xFFEF4444) : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dynamic Offering Confirmation Badge based on selected status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _status == DonationStatus.paid
                          ? const Color(0xFF10B981).withAlpha(18)
                          : (_status == DonationStatus.unpaid
                              ? const Color(0xFFEF4444).withAlpha(18)
                              : const Color(0xFFF59E0B).withAlpha(18)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _status == DonationStatus.paid
                            ? const Color(0xFF10B981).withAlpha(60)
                            : (_status == DonationStatus.unpaid
                                ? const Color(0xFFEF4444).withAlpha(60)
                                : const Color(0xFFF59E0B).withAlpha(60)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _status == DonationStatus.paid
                              ? Icons.verified_rounded
                              : (_status == DonationStatus.unpaid
                                  ? Icons.hourglass_top_rounded
                                  : Icons.pie_chart_outline_rounded),
                          color: _status == DonationStatus.paid
                              ? const Color(0xFF10B981)
                              : (_status == DonationStatus.unpaid
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B)),
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _status == DonationStatus.paid
                                    ? 'Samagri / Item received directly in full for Puja usage.'
                                    : (_status == DonationStatus.unpaid
                                        ? 'Samagri promised / pledged by contributor (Pending delivery).'
                                        : 'Samagri partially received (Remaining delivery/value pending).'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withAlpha(220),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _status == DonationStatus.paid
                                    ? 'सामग्री प्राप्त हो चुकी है (Full Received)'
                                    : (_status == DonationStatus.unpaid
                                        ? 'सामग्री देना बाकी है (Promised / Due)'
                                        : 'सामग्री आंशिक रूप से प्राप्त हुई है (Partial Received)'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _status == DonationStatus.paid
                                      ? const Color(0xFF34D399)
                                      : (_status == DonationStatus.unpaid
                                          ? const Color(0xFFFB7185)
                                          : const Color(0xFFFBBF24)),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Collector / Receiver Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _collectorController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Receiver Name',
                          prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white60, size: 16),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.glassBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _donationType == DonationType.inKind
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _save,
                        child: Text(
                          isEditing
                              ? 'Update Entry'
                              : (_donationType == DonationType.inKind ? 'Save Kind Offering' : 'Save Contributor'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

// ============================================================================
// HELPER: CONFIRM & DELETE PAYMENT TRANSACTION
// ============================================================================
Future<void> showDeletePaymentConfirmation({
  required BuildContext context,
  required PujaProvider provider,
  required ChandaSlip slip,
  required SlipPayment payment,
  required NumberFormat currency,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRose, size: 22),
          SizedBox(width: 8),
          Text('Delete Transaction?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this payment of ${currency.format(payment.amount)} collected on ${DateFormat('dd MMM yyyy').format(payment.date)}?\n\nThe contributor\'s paid and due balances will be updated automatically.',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerRose,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    provider.deleteSlipPayment(
      slipId: slip.id,
      paymentId: payment.id,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted payment of ${currency.format(payment.amount)}'),
        backgroundColor: AppTheme.dangerRose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _showDeletePaymentConfirmation({
  required BuildContext context,
  required PujaProvider provider,
  required ChandaSlip slip,
  required SlipPayment payment,
  required NumberFormat currency,
}) => showDeletePaymentConfirmation(
  context: context,
  provider: provider,
  slip: slip,
  payment: payment,
  currency: currency,
);

// ============================================================================
// EDIT SLIP PAYMENT TRANSACTION DIALOG
// ============================================================================
class EditSlipPaymentDialog extends StatefulWidget {
  final ChandaSlip slip;
  final SlipPayment payment;

  const EditSlipPaymentDialog({
    super.key,
    required this.slip,
    required this.payment,
  });

  @override
  State<EditSlipPaymentDialog> createState() => _EditSlipPaymentDialogState();
}

class _EditSlipPaymentDialogState extends State<EditSlipPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _collectorController;
  late final TextEditingController _noteController;
  late PaymentMode _paymentMode;
  late DateTime _paymentDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payment.amount.toStringAsFixed(0));
    _collectorController = TextEditingController(text: widget.payment.collectedBy);
    _noteController = TextEditingController(text: widget.payment.note ?? '');
    _paymentMode = widget.payment.paymentMode;
    _paymentDate = widget.payment.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _collectorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F172A)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _paymentDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _paymentDate.hour == 0 ? now.hour : _paymentDate.hour,
          _paymentDate.minute == 0 ? now.minute : _paymentDate.minute,
        );
      });
    }
  }

  void _save() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final provider = Provider.of<PujaProvider>(context, listen: false);
    provider.updateSlipPayment(
      slipId: widget.slip.id,
      paymentId: widget.payment.id,
      amount: amt,
      date: _paymentDate,
      paymentMode: _paymentMode,
      collectedBy: _collectorController.text.trim().isNotEmpty
          ? _collectorController.text.trim()
          : widget.payment.collectedBy,
      note: _noteController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Updated payment of ₹${amt.toStringAsFixed(0)}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          border: Border.all(color: AppTheme.goldAccent.withAlpha(120), width: 1.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppTheme.goldAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Payment Transaction',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${widget.slip.donorName} • Slip #${widget.slip.slipNumber}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Field
              const Text('Payment Amount (₹) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor: const Color(0xD9081022),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                ),
              ),
              const SizedBox(height: 12),

              // Date and Mode Row
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collection Date *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xD9081022),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 17, color: AppTheme.goldAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_paymentDate),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Mode Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mode *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<PaymentMode>(
                          initialValue: _paymentMode,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xD9081022),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          ),
                          items: PaymentMode.values.map((m) {
                            return DropdownMenuItem<PaymentMode>(
                              value: m,
                              child: Text(m.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMode = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Collector Name
              const Text('Collector Name', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _collectorController,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Collector name',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 17, color: AppTheme.goldAccent),
                  filled: true,
                  fillColor: const Color(0xD9081022),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                ),
              ),
              const SizedBox(height: 12),

              // Note / Remarks
              const Text('Remarks / Note', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'e.g. 2nd installment, cash received',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 17, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xD9081022),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: const Color(0xFF0B1426),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded, size: 17),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
}

// ============================================================================
// 4. COLLECT DUE MODAL DIALOG
// Enhanced with Date Picker, Note field, and Past Collection History List
// ============================================================================
class CollectDueDialog extends StatefulWidget {
  final ChandaSlip slip;

  const CollectDueDialog({super.key, required this.slip});

  @override
  State<CollectDueDialog> createState() => _CollectDueDialogState();
}

class _CollectDueDialogState extends State<CollectDueDialog> {
  final _amountController = TextEditingController();
  final _collectorController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();
  bool _isHistoryExpanded = true;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.slip.pendingAmount.toStringAsFixed(0);
    _collectorController.text = widget.slip.collectedBy;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _collectorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F172A)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _paymentDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  void _submit() {
    final paying = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (paying <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final provider = Provider.of<PujaProvider>(context, listen: false);
    provider.recordPayment(
      slipId: widget.slip.id,
      payingAmount: paying,
      paymentMode: _paymentMode,
      collectedBy: _collectorController.text.trim().isNotEmpty
          ? _collectorController.text.trim()
          : widget.slip.collectedBy,
      paymentDate: _paymentDate,
      note: _noteController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Recorded ₹${paying.toStringAsFixed(0)} on ${DateFormat('dd MMM yyyy').format(_paymentDate)}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currentSlip = provider.slips.firstWhere((s) => s.id == widget.slip.id, orElse: () => widget.slip);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pastPayments = currentSlip.payments;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(120), width: 1.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collect Due Amount',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${currentSlip.donorName} • Slip #${currentSlip.slipNumber}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Due Info Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Chanda', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                                Text(currency.format(currentSlip.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Already Paid', style: TextStyle(fontSize: 10.5, color: Color(0xFF10B981))),
                                Text(currency.format(currentSlip.paidAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Current Due', style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                Text(currency.format(currentSlip.pendingAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Past Collection History Accordion ("kaab kitna collect kiya wo saab ek jaga")
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0x1F0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _isHistoryExpanded = !_isHistoryExpanded),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                child: Row(
                                  children: [
                                    const Icon(Icons.history_rounded, size: 16, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Collection History (${pastPayments.length})',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Paid: ${currency.format(currentSlip.paidAmount)}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _isHistoryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: Colors.white60,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isHistoryExpanded) ...[
                              const Divider(height: 1, color: Colors.white12),
                              if (pastPayments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: Text(
                                      'No collection payments recorded yet.',
                                      style: TextStyle(fontSize: 11.5, color: Colors.white54),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(10),
                                  itemCount: pastPayments.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                                  itemBuilder: (context, idx) {
                                    final p = pastPayments[idx];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0x1F1E293B),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: Colors.white.withAlpha(15)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withAlpha(30),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${idx + 1}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      DateFormat('dd MMM yyyy, hh:mm a').format(p.date),
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withAlpha(15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        p.paymentMode.name.toUpperCase(),
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (p.note != null && p.note!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    p.note!,
                                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                if (p.collectedBy.isNotEmpty) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    'Collector: ${p.collectedBy}',
                                                    style: const TextStyle(fontSize: 9.5, color: Colors.white38),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                currency.format(p.amount),
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.white.withAlpha(20)),
                                                ),
                                                child: PopupMenuButton<String>(
                                                  tooltip: 'Options',
                                                  icon: const Icon(Icons.sort_rounded, size: 16, color: Colors.white70),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  color: const Color(0xFF0F172A),
                                                  elevation: 12,
                                                  offset: const Offset(0, 32),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: const BorderSide(color: AppTheme.glassBorder),
                                                  ),
                                                  onSelected: (val) {
                                                    if (val == 'edit') {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => EditSlipPaymentDialog(slip: currentSlip, payment: p),
                                                      );
                                                    } else if (val == 'delete') {
                                                      _showDeletePaymentConfirmation(
                                                        context: context,
                                                        provider: provider,
                                                        slip: currentSlip,
                                                        payment: p,
                                                        currency: currency,
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (ctx) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      height: 38,
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit_rounded, size: 15, color: Color(0xFF38BDF8)),
                                                          SizedBox(width: 8),
                                                          Text('Edit Transaction', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuDivider(height: 1),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      height: 38,
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRose),
                                                          SizedBox(width: 8),
                                                          Text('Delete Transaction', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12, fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Title: Record New Collection
                      const Row(
                        children: [
                          Icon(Icons.add_card_rounded, size: 15, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text('Record New Collection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Paying Amount Now
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paying Amount Now (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          if (currentSlip.pendingAmount > 0)
                            InkWell(
                              onTap: () {
                                _amountController.text = currentSlip.pendingAmount.toStringAsFixed(0);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                                ),
                                child: const Text('Pay Full Due', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Collection Date & Payment Mode Row ("Date set krne ka system")
                      Row(
                        children: [
                          // Collection Date Selector
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Collection Date *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xD9081022),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.glassBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_rounded, size: 17, color: Color(0xFF10B981)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(_paymentDate),
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white38),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Payment Mode
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mode *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<PaymentMode>(
                                  initialValue: _paymentMode,
                                  dropdownColor: const Color(0xFF0F172A),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                  ),
                                  items: PaymentMode.values.map((m) {
                                    return DropdownMenuItem<PaymentMode>(
                                      value: m,
                                      child: Text(m.name.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentMode = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Collector Name & Remarks
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Collector Name', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _collectorController,
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Collector',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 17, color: Color(0xFF10B981)),
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Remarks / Note', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _noteController,
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 2nd installment',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                    prefixIcon: const Icon(Icons.note_alt_outlined, size: 17, color: Colors.white54),
                                    filled: true,
                                    fillColor: const Color(0xD9081022),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.glassBorder)),
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
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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
}

// ============================================================================
// 5. CONTRIBUTOR PAYMENT HISTORY DIALOG
// Displays full chronological collection history for a specific contributor
// ============================================================================
class ContributorPaymentHistoryDialog extends StatelessWidget {
  final ChandaSlip slip;

  const ContributorPaymentHistoryDialog({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currentSlip = provider.slips.firstWhere((s) => s.id == slip.id, orElse: () => slip);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final payments = currentSlip.payments;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          border: Border.all(color: const Color(0xFF38BDF8).withAlpha(100), width: 1.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contributor Payment History',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${currentSlip.donorName} • Slip #${currentSlip.slipNumber}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Contributor Summary Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1F0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Chanda', style: TextStyle(fontSize: 10, color: Colors.white60)),
                        const SizedBox(height: 3),
                        Text(currency.format(currentSlip.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('Paid (Jama)', style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                        const SizedBox(height: 3),
                        Text(currency.format(currentSlip.paidAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('Due (Baki)', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                        const SizedBox(height: 3),
                        Text(currency.format(currentSlip.pendingAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Header
              Row(
                children: [
                  const Text('All Recorded Installments', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8).withAlpha(50)),
                    ),
                    child: Text(
                      '${payments.length} Payments',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Installment List
              Flexible(
                child: payments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.white.withAlpha(50)),
                              const SizedBox(height: 10),
                              const Text('No payments recorded yet for this slip.', style: TextStyle(fontSize: 12.5, color: Colors.white54)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final p = payments[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(20)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(25),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${idx + 1}',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
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
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(p.date),
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(15),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              p.paymentMode.name.toUpperCase(),
                                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white70),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (p.note != null && p.note!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          p.note!,
                                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                                        ),
                                      ],
                                      if (p.collectedBy.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 11, color: Colors.white38),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Collector: ${p.collectedBy}',
                                              style: const TextStyle(fontSize: 10, color: Colors.white38),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      currency.format(p.amount),
                                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withAlpha(20)),
                                      ),
                                      child: PopupMenuButton<String>(
                                        tooltip: 'Transaction Options',
                                        icon: const Icon(Icons.sort_rounded, size: 18, color: Colors.white70),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        color: const Color(0xFF0F172A),
                                        elevation: 14,
                                        offset: const Offset(0, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: AppTheme.glassBorder),
                                        ),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            showDialog(
                                              context: context,
                                              builder: (_) => EditSlipPaymentDialog(slip: currentSlip, payment: p),
                                            );
                                          } else if (val == 'delete') {
                                            showDeletePaymentConfirmation(
                                              context: context,
                                              provider: provider,
                                              slip: currentSlip,
                                              payment: p,
                                              currency: currency,
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            height: 38,
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, size: 15, color: Color(0xFF38BDF8)),
                                                SizedBox(width: 9),
                                                Text('Edit Transaction', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(height: 1),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            height: 38,
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRose),
                                                SizedBox(width: 9),
                                                Text('Delete Transaction', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  if (currentSlip.pendingAmount > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => CollectDueDialog(slip: currentSlip),
                          );
                        },
                        icon: const Icon(Icons.payments_rounded, size: 16),
                        label: const Text('Collect Due', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. ACCOUNT TRANSACTIONS & ALL COLLECTION LOG MODAL
// Shows all Chanda collection installments across the entire book/account
// ============================================================================
class AccountTransactionsDialog extends StatefulWidget {
  final CollectionAccount account;
  final List<ChandaSlip> slips;

  const AccountTransactionsDialog({
    super.key,
    required this.account,
    required this.slips,
  });

  @override
  State<AccountTransactionsDialog> createState() => _AccountTransactionsDialogState();
}

class _AccountTransactionsDialogState extends State<AccountTransactionsDialog> {
  final _searchController = TextEditingController();
  PaymentMode? _modeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final accountSlips = provider.slips.where((s) => s.accountId == widget.account.id).toList();
    final effectiveSlips = accountSlips.isNotEmpty ? accountSlips : widget.slips;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Flatten all SlipPayment instances
    final allRecords = <_TxnRecord>[];
    for (final slip in effectiveSlips) {
      for (final p in slip.payments) {
        allRecords.add(_TxnRecord(slip: slip, payment: p));
      }
    }

    // Sort newest date first
    allRecords.sort((a, b) => b.payment.date.compareTo(a.payment.date));

    // Filter by query and mode
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allRecords.where((r) {
      if (_modeFilter != null && r.payment.paymentMode != _modeFilter) return false;
      if (query.isEmpty) return true;
      return r.slip.donorName.toLowerCase().contains(query) ||
          (r.slip.phone != null && r.slip.phone!.contains(query)) ||
          r.payment.collectedBy.toLowerCase().contains(query) ||
          (r.payment.note != null && r.payment.note!.toLowerCase().contains(query));
    }).toList();

    final totalCollected = allRecords.fold(0.0, (acc, r) => acc + r.payment.amount);
    final cashCollected = allRecords
        .where((r) => r.payment.paymentMode == PaymentMode.cash)
        .fold(0.0, (acc, r) => acc + r.payment.amount);
    final digitalCollected = totalCollected - cashCollected;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(100), width: 1.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collection Transactions Log',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${widget.account.accountName} • All Partial & Full Chanda Collections',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // KPI Stats Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x1F0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('TOTAL TRANSACTIONS', style: TextStyle(fontSize: 9.5, color: Colors.white60, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${allRecords.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    Container(height: 22, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('TOTAL COLLECTED', style: TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(currency.format(totalCollected), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ],
                    ),
                    Container(height: 22, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('CASH', style: TextStyle(fontSize: 9.5, color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(currency.format(cashCollected), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
                      ],
                    ),
                    Container(height: 22, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('ONLINE / BANK', style: TextStyle(fontSize: 9.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(currency.format(digitalCollected), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter & Search Toolbar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search contributor, phone, collector...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white54),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mode Filter Chips
                  _buildModeFilterChip(null, 'All'),
                  const SizedBox(width: 4),
                  _buildModeFilterChip(PaymentMode.cash, 'Cash'),
                  const SizedBox(width: 4),
                  _buildModeFilterChip(PaymentMode.upi, 'UPI'),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List
              Flexible(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 38, color: Colors.white.withAlpha(50)),
                              const SizedBox(height: 10),
                              const Text('No collection transactions found.', style: TextStyle(fontSize: 13, color: Colors.white54)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 7),
                        itemBuilder: (context, idx) {
                          final rec = filtered[idx];
                          final p = rec.payment;
                          final slip = rec.slip;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(16)),
                            ),
                            child: Row(
                              children: [
                                // Date & Time Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM').format(p.date),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        DateFormat('hh:mm a').format(p.date),
                                        style: const TextStyle(fontSize: 9.5, color: Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Contributor & Collector Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              slip.donorName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Slip #${slip.slipNumber}',
                                              style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: p.paymentMode == PaymentMode.cash
                                                  ? const Color(0xFFFBBF24).withAlpha(25)
                                                  : const Color(0xFF38BDF8).withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              p.paymentMode.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: p.paymentMode == PaymentMode.cash
                                                    ? const Color(0xFFFBBF24)
                                                    : const Color(0xFF38BDF8),
                                              ),
                                            ),
                                          ),
                                          if (p.collectedBy.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              'By ${p.collectedBy}',
                                              style: const TextStyle(fontSize: 10.5, color: Colors.white54),
                                            ),
                                          ],
                                          if (p.note != null && p.note!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                '• ${p.note}',
                                                style: const TextStyle(fontSize: 10.5, color: Colors.white54),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Amount Collected & Options Menu
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      currency.format(p.amount),
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(12),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(color: Colors.white.withAlpha(20)),
                                      ),
                                      child: PopupMenuButton<String>(
                                        tooltip: 'Options',
                                        icon: const Icon(Icons.sort_rounded, size: 17, color: Colors.white70),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                        color: const Color(0xFF0F172A),
                                        elevation: 12,
                                        offset: const Offset(0, 34),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: AppTheme.glassBorder),
                                        ),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            showDialog(
                                              context: context,
                                              builder: (_) => EditSlipPaymentDialog(slip: slip, payment: p),
                                            );
                                          } else if (val == 'delete') {
                                            showDeletePaymentConfirmation(
                                              context: context,
                                              provider: provider,
                                              slip: slip,
                                              payment: p,
                                              currency: currency,
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            height: 38,
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, size: 15, color: Color(0xFF38BDF8)),
                                                SizedBox(width: 9),
                                                Text('Edit Transaction', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(height: 1),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            height: 38,
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRose),
                                                SizedBox(width: 9),
                                                Text('Delete Transaction', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 14),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: AppTheme.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeFilterChip(PaymentMode? mode, String label) {
    final isSelected = _modeFilter == mode;
    return InkWell(
      onTap: () => setState(() => _modeFilter = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TxnRecord {
  final ChandaSlip slip;
  final SlipPayment payment;
  _TxnRecord({required this.slip, required this.payment});
}

// ============================================================================
// 10. CHANDA SLIP / CONTRIBUTOR DETAILS SHEET & DIALOG
// Systematic, comprehensive contributor details modal with direct actions
// ============================================================================
void showChandaSlipDetails(BuildContext context, ChandaSlip slip, {CollectionAccount? account}) {
  final isDesktop = MediaQuery.of(context).size.width > 700;
  if (isDesktop) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: ChandaSlipDetailSheet(slip: slip, account: account, isDialog: true),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChandaSlipDetailSheet(slip: slip, account: account, isDialog: false),
    );
  }
}

class ChandaSlipDetailSheet extends StatelessWidget {
  final ChandaSlip slip;
  final CollectionAccount? account;
  final bool isDialog;

  const ChandaSlipDetailSheet({
    super.key,
    required this.slip,
    this.account,
    this.isDialog = false,
  });

  void _confirmDelete(BuildContext context, PujaProvider provider, ChandaSlip currentSlip) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Delete Contributor Slip?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete slip #${currentSlip.slipNumber} for "${currentSlip.donorName}"? This action cannot be undone.',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(160)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        provider.deleteDonation(currentSlip.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showPdfOptions(BuildContext context, PujaProvider provider, ChandaSlip currentSlip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.glassBorder),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chanda Receipt PDF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${currentSlip.donorName} • Slip #${currentSlip.slipNumber}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                tileColor: const Color(0x1F1E293B),
                leading: const Icon(Icons.print_rounded, color: Color(0xFF38BDF8), size: 22),
                title: const Text('View & Print / Save PDF', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Preview receipt with Print & Save options', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  ReceiptShareService.printSlipPdf(
                    slip: currentSlip,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                tileColor: const Color(0x1F1E293B),
                leading: const Icon(Icons.share_rounded, color: Color(0xFF10B981), size: 22),
                title: const Text('Share PDF File', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Send PDF via WhatsApp, Email, Drive, etc.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  ReceiptShareService.shareSlipPdf(
                    slip: currentSlip,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currentSlip = provider.slips.firstWhere((s) => s.id == slip.id, orElse: () => slip);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final isPaid = currentSlip.isFullyPaid;
    final isPartial = currentSlip.isPartial;
    final statusColor = isPaid
        ? const Color(0xFF10B981)
        : (isPartial ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    final percent = currentSlip.amount > 0
        ? ((currentSlip.paidAmount / currentSlip.amount) * 100).clamp(0.0, 100.0)
        : 0.0;

    final parentAccount = account ??
        provider.collectionAccounts.where((a) => a.id == currentSlip.accountId).firstOrNull;

    final content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1128),
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(80), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: isDialog ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Drag handle on mobile bottomsheet
          if (!isDialog) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Top Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 10),
            child: Row(
              children: [
                // Serial Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withAlpha(120), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag_rounded, size: 13, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 2),
                      Text(
                        'SL #${currentSlip.slipNumber}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Book number
                if (currentSlip.bookNumber > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Text(
                      'Book #${currentSlip.bookNumber}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(90)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(currentSlip.status.icon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        currentSlip.status.displayName.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x2238BDF8)),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Donor Profile Card
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    border: Border.all(color: statusColor.withAlpha(70), width: 1.2),
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withAlpha(20),
                        const Color(0x1F0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Row(
                      children: [
                        // Large Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withAlpha(35),
                            border: Border.all(color: statusColor.withAlpha(120), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              currentSlip.donorName.isNotEmpty ? currentSlip.donorName[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Contact
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSlip.donorName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 4),

                              // Phone & Actions
                              if (currentSlip.phone != null && currentSlip.phone!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.phone_rounded, size: 12, color: Colors.white.withAlpha(160)),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentSlip.phone!,
                                      style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 8),

                                    // Quick Call Button
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () => launchUrl(Uri.parse('tel:${currentSlip.phone}')),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.call_rounded, size: 13, color: Color(0xFF34D399)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Quick WhatsApp Share Button
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () => ReceiptShareService.sendOnWhatsApp(
                                        slip: currentSlip,
                                        pujaName: provider.pujaName,
                                        currentYear: provider.currentYear,
                                        cashierName: provider.cashierName,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF25D366).withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF25D366)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                              ],

                              // Address / Area
                              if (currentSlip.address != null && currentSlip.address!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 11.5, color: Colors.white.withAlpha(140)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        currentSlip.address!,
                                        style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(160)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                              // Collection Account tag
                              if (parentAccount != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '📁 ${parentAccount.accountName}',
                                  style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(130), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Financial Overview (Systematic 3-Pillar Card)
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    border: Border.all(color: AppTheme.glassBorderLight.withAlpha(70), width: 1.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FINANCIAL BREAKDOWN',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // Total Chanda
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withAlpha(14)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOTAL CHANDA', style: TextStyle(fontSize: 9.5, color: Colors.white60, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currency.format(currentSlip.amount),
                                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Paid (Jama)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PAID (JAMA)', style: TextStyle(fontSize: 9.5, color: Color(0xFF34D399), fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currency.format(currentSlip.paidAmount),
                                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Unpaid (Baki)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: currentSlip.pendingAmount > 0
                                      ? const Color(0xFFEF4444).withAlpha(20)
                                      : Colors.white.withAlpha(6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: currentSlip.pendingAmount > 0
                                        ? const Color(0xFFEF4444).withAlpha(50)
                                        : Colors.white.withAlpha(10),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UNPAID (BAKI)',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: currentSlip.pendingAmount > 0 ? const Color(0xFFFB7185) : Colors.white38,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currency.format(currentSlip.pendingAmount),
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        color: currentSlip.pendingAmount > 0 ? const Color(0xFFFB7185) : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPaid
                                  ? '100% Fully Settled'
                                  : (isPartial ? '${percent.toStringAsFixed(1)}% Collected' : 'Payment Pending'),
                              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: statusColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentSlip.amount > 0 ? (currentSlip.paidAmount / currentSlip.amount).clamp(0.0, 1.0) : 0.0,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // In-Kind Samagri Card (if in-kind)
                  if (currentSlip.isInKind) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (currentSlip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (currentSlip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentSlip.inKindCategory?.icon ?? Icons.inventory_2_rounded,
                            size: 24,
                            color: currentSlip.inKindCategory?.color ?? const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSlip.inKindItemName ?? 'Samagri Item',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Category: ${currentSlip.inKindCategory?.displayName.split(' (')[0] ?? 'In-Kind'} • Quantity: ${currentSlip.inKindQuantity ?? '1 Unit'}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(170)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 3. Metadata Grid (Payment Mode, Date, Collector, Notes)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          icon: Icons.payment_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          label: 'Payment Mode',
                          value: currentSlip.isInKind ? 'IN-KIND SAMAGRI' : currentSlip.paymentMode.name.toUpperCase(),
                        ),
                        const Divider(height: 16, color: Colors.white12),
                        _buildMetaRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF10B981),
                          label: 'Collection Date',
                          value: DateFormat('dd MMM yyyy, hh:mm a').format(currentSlip.paymentDate ?? currentSlip.createdAt),
                        ),
                        const Divider(height: 16, color: Colors.white12),
                        _buildMetaRow(
                          icon: Icons.person_rounded,
                          iconColor: AppTheme.primaryBlue,
                          label: 'Collected By',
                          value: currentSlip.collectedBy.isNotEmpty ? currentSlip.collectedBy : 'Committee',
                        ),
                        if (currentSlip.dayLabel != null && currentSlip.dayLabel!.isNotEmpty) ...[
                          const Divider(height: 16, color: Colors.white12),
                          _buildMetaRow(
                            icon: Icons.event_note_rounded,
                            iconColor: AppTheme.goldAccent,
                            label: 'Day / Occasion',
                            value: currentSlip.dayLabel!,
                          ),
                        ],
                        if (currentSlip.notes != null && currentSlip.notes!.isNotEmpty) ...[
                          const Divider(height: 16, color: Colors.white12),
                          _buildMetaRow(
                            icon: Icons.notes_rounded,
                            iconColor: Colors.white70,
                            label: 'Notes / Remarks',
                            value: currentSlip.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 4. Installment Payment History (if multiple payments or history exists)
                  if (currentSlip.payments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PAYMENT HISTORY (${currentSlip.payments.length})',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 0.6),
                        ),
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => ContributorPaymentHistoryDialog(slip: currentSlip),
                          ),
                          child: const Text(
                            'View Full Log',
                            style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Column(
                        children: List.generate(currentSlip.payments.length, (idx) {
                          final p = currentSlip.payments[idx];
                          final isLast = idx == currentSlip.payments.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 12, color: Color(0xFF34D399)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency.format(p.amount),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        '${DateFormat('dd MMM yyyy, hh:mm a').format(p.date)} • ${p.paymentMode.name.toUpperCase()}',
                                        style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (p.note != null && p.note!.isNotEmpty)
                                  Text(
                                    p.note!,
                                    style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120), fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0x2238BDF8)),

          // Bottom Action Bar (Collect Due, PDF, Edit, Delete)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                // Primary Action Button: Collect Due (if unpaid/partial)
                if (!isPaid) ...[
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 17),
                      label: const Text('Collect Due', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => CollectDueDialog(slip: currentSlip),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // PDF Receipt Action
                Expanded(
                  flex: isPaid ? 3 : 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      backgroundColor: const Color(0xFF38BDF8).withAlpha(18),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('PDF Receipt', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _showPdfOptions(context, provider, currentSlip),
                  ),
                ),

                const SizedBox(width: 8),

                // Edit Button
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    if (parentAccount != null) {
                      showDialog(
                        context: context,
                        builder: (_) => AddContributorDialog(account: parentAccount, existingSlip: currentSlip),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldAccent.withAlpha(80)),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.goldAccent),
                  ),
                ),

                const SizedBox(width: 6),

                // Delete Button
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _confirmDelete(context, provider, currentSlip),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRose.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dangerRose.withAlpha(80)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRose),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return content;
  }

  Widget _buildMetaRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

