import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';
import 'dialogs.dart';

// ============================================================================
// 1. CREATE / EDIT EVENT DIALOG
// ============================================================================
class CreateEditEventDialog extends StatefulWidget {
  final PujaEvent? existing;

  const CreateEditEventDialog({super.key, this.existing});

  @override
  State<CreateEditEventDialog> createState() => _CreateEditEventDialogState();
}

class _CreateEditEventDialogState extends State<CreateEditEventDialog> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _presetNames = [
    'Durga Puja',
    'Lakshmi Puja',
    'Kali Puja',
    'Saraswati Puja',
    'Jagaddhatri Puja',
    'Kartik Puja',
    'Other / Custom',
  ];

  late String _selectedPreset;
  final _customNameController = TextEditingController();
  final _yearController = TextEditingController();
  final _targetBudgetController = TextEditingController();
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    final ext = widget.existing;
    if (ext != null) {
      if (_presetNames.contains(ext.name)) {
        _selectedPreset = ext.name;
      } else {
        _selectedPreset = 'Other / Custom';
        _customNameController.text = ext.name;
      }
      _yearController.text = ext.year.toString();
      _targetBudgetController.text = ext.targetBudget != null ? ext.targetBudget!.toStringAsFixed(0) : '';
      _status = ext.status;
    } else {
      _selectedPreset = 'Durga Puja';
      _yearController.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _yearController.dispose();
    _targetBudgetController.dispose();
    super.dispose();
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.deepAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.festival, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Festival Event' : 'Create New Event',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Text(
                            'Puja committee details remain same, set event name & year',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Event Preset Selection
                const Text('Event / Festival Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      value: _selectedPreset,
                      items: _presetNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPreset = val);
                      },
                    ),
                  ),
                ),

                if (_selectedPreset == 'Other / Custom') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Custom Festival Name',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12.5),
                      hintText: 'e.g. Kali Puja, Saraswati Puja',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                    ),
                    validator: (v) {
                      if (_selectedPreset == 'Other / Custom' && (v == null || v.trim().isEmpty)) {
                        return 'Please enter festival name';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 14),

                // Year & Target Budget
                Row(
                  children: [
                    // Year
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Year',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 16),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                        ),
                        validator: (v) {
                          if (v == null || int.tryParse(v.trim()) == null) {
                            return 'Valid year required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Target Budget Goal (Optional)
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _targetBudgetController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Target Budget (Optional)',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.bold),
                          hintText: 'e.g. 150000',
                          hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11.5),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Event Status
                const Text('Event Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: ['Active', 'Upcoming', 'Completed'].map((st) {
                    final isSel = _status == st;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _status = st),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.primaryBlue.withAlpha(45) : const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? AppTheme.primaryBlue : AppTheme.glassBorder,
                              width: isSel ? 1.4 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            st,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.white60,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      final provider = Provider.of<PujaProvider>(context, listen: false);

                      final name = _selectedPreset == 'Other / Custom'
                          ? _customNameController.text.trim()
                          : _selectedPreset;
                      final year = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
                      final budget = double.tryParse(_targetBudgetController.text.trim());

                      if (isEditing) {
                        provider.updateEvent(
                          id: widget.existing!.id,
                          name: name,
                          year: year,
                          targetBudget: budget,
                          status: _status,
                        );
                      } else {
                        provider.createEvent(
                          name: name,
                          year: year,
                          targetBudget: budget,
                          status: _status,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Event',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

// ============================================================================
// 2. ADD / EDIT DONATION DIALOG (Direct Collector, Paid/Unpaid/Partial, Date)
// ============================================================================
class AddEditDonationDialog extends StatefulWidget {
  final ChandaSlip? existing;
  final String? initialEventId;
  final DonationType initialDonationType;

  const AddEditDonationDialog({
    super.key,
    this.existing,
    this.initialEventId,
    this.initialDonationType = DonationType.cash,
  });

  @override
  State<AddEditDonationDialog> createState() => _AddEditDonationDialogState();
}

class _AddEditDonationDialogState extends State<AddEditDonationDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEventId;
  DonationType _donationType = DonationType.cash;
  final _donorNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _inKindItemController = TextEditingController();
  final _inKindQuantityController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _collectorController = TextEditingController();
  final _notesController = TextEditingController();

  InKindCategory _inKindCategory = InKindCategory.bhogGroceries;
  DonationStatus _status = DonationStatus.unpaid;
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _selectedDate = DateTime.now();
  String? _slipPhotoUrl;

  final List<int> _quickAmounts = [251, 501, 1001, 2100, 5100, 11000];

  @override
  void initState() {
    super.initState();
    final ext = widget.existing;
    if (ext != null) {
      _donationType = ext.donationType;
      _selectedEventId = ext.eventId;
      _donorNameController.text = ext.donorName;
      _phoneController.text = ext.phone ?? '';
      _addressController.text = ext.address ?? '';
      _totalAmountController.text = ext.amount > 0 ? ext.amount.toStringAsFixed(0) : '';
      _paidAmountController.text = ext.paidAmount > 0 ? ext.paidAmount.toStringAsFixed(0) : '';
      _collectorController.text = ext.collectedBy;
      _notesController.text = ext.notes ?? '';
      _status = ext.status;
      _paymentMode = ext.paymentMode;
      _selectedDate = ext.createdAt;
      _inKindItemController.text = ext.inKindItemName ?? '';
      _inKindQuantityController.text = ext.inKindQuantity ?? '';
      _estimatedValueController.text = (ext.isInKind && ext.amount > 0) ? ext.amount.toStringAsFixed(0) : '';
      _inKindCategory = ext.inKindCategory ?? InKindCategory.bhogGroceries;
      _slipPhotoUrl = ext.slipPhotoUrl;
    } else {
      _donationType = widget.initialDonationType;
      _selectedEventId = widget.initialEventId;
      _paidAmountController.text = '0';
    }
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _inKindItemController.dispose();
    _inKindQuantityController.dispose();
    _estimatedValueController.dispose();
    _collectorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStatusChanged(DonationStatus newStatus) {
    setState(() {
      _status = newStatus;
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
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlue,
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final events = provider.events;
    final collectors = provider.availableCollectors;
    final isEditing = widget.existing != null;

    if (_selectedEventId == null && events.isNotEmpty) {
      _selectedEventId = provider.selectedEventId ?? events.first.id;
    }

    if (_collectorController.text.isEmpty && collectors.isNotEmpty) {
      _collectorController.text = collectors.first;
    }

    final totalAmt = double.tryParse(_totalAmountController.text.trim()) ?? 0.0;
    final paidAmt = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    final remainingAmt = (totalAmt - paidAmt) > 0 ? (totalAmt - paidAmt) : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        maxWidth: 580,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.volunteer_activism,
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
                            isEditing ? 'Edit Chanda / Donation' : 'Record Chanda / Donation',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Text(
                            'Assign direct collector, set paid/unpaid status & date',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Donation Type Selector: Cash vs In-Kind
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1E293B),
                    borderRadius: BorderRadius.circular(16),
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
                                  ? const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)])
                                  : null,
                              color: _donationType == DonationType.cash ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _donationType == DonationType.cash
                                  ? [BoxShadow(color: AppTheme.primaryBlue.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments_rounded, size: 16, color: _donationType == DonationType.cash ? Colors.white : Colors.white60),
                                const SizedBox(width: 6),
                                Text(
                                  '💵 Cash / Money',
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
                                  ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                                  : null,
                              color: _donationType == DonationType.inKind ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _donationType == DonationType.inKind
                                  ? [BoxShadow(color: const Color(0xFF10B981).withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_rounded, size: 16, color: _donationType == DonationType.inKind ? Colors.white : Colors.white60),
                                const SizedBox(width: 6),
                                Text(
                                  '🎁 In-Kind / Samagri',
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

                // Event Selector Dropdown
                if (events.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Event / Festival', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      Text(
                        'Year: ${provider.selectedEvent?.year ?? provider.currentYear}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        value: _selectedEventId,
                        items: events.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Row(
                              children: [
                                const Icon(Icons.festival_outlined, color: AppTheme.primaryBlue, size: 16),
                                const SizedBox(width: 8),
                                Text('${e.name} (${e.year})', style: const TextStyle(color: Colors.white, fontSize: 13)),
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

                // Donor Name (Required)
                TextFormField(
                  controller: _donorNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Donor / Contributor Name *',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    hintText: 'e.g. Subhash Bose, Sharma Family',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11.5),
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 18),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Donor name is required' : null,
                ),
                const SizedBox(height: 10),

                // Phone & Address in a row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone (Optional)',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white60, size: 16),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Address / Flat',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white60, size: 16),
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_donationType == DonationType.cash) ...[
                  // Total Donation Amount
                  TextFormField(
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (val) {
                      final n = double.tryParse(val.trim()) ?? 0.0;
                      if (_status == DonationStatus.paid) {
                        _paidAmountController.text = n > 0 ? n.toStringAsFixed(0) : '';
                      } else if (_status == DonationStatus.unpaid) {
                        _paidAmountController.text = '0';
                      }
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Total Chanda Amount *',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: AppTheme.successGreenLight, fontSize: 18, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                    ),
                    validator: (v) {
                      if (_donationType == DonationType.cash) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n <= 0) return 'Enter a valid amount';
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
                          child: ActionChip(
                            label: Text('₹$amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                            backgroundColor: const Color(0x1F1E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            onPressed: () {
                              _totalAmountController.text = amt.toString();
                              if (_status == DonationStatus.paid) {
                                _paidAmountController.text = amt.toString();
                              } else if (_status == DonationStatus.unpaid) {
                                _paidAmountController.text = '0';
                              }
                              setState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Status Toggle: Paid / Unpaid / Partial
                  const Text('Payment Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: DonationStatus.values.map((st) {
                      final isSel = _status == st;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onStatusChanged(st),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? st.color.withAlpha(40) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? st.color : AppTheme.glassBorder,
                                width: isSel ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(st.icon, size: 16, color: isSel ? st.color : Colors.white60),
                                const SizedBox(height: 4),
                                Text(
                                  st.displayName,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? Colors.white : Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Conditional Paid Amount & Remaining Display
                  if (_status == DonationStatus.partial) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Amount Paid Now',
                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                              prefixText: '₹ ',
                              prefixStyle: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.bold),
                              filled: true,
                              fillColor: const Color(0xD9081022),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                            ),
                            validator: (v) {
                              if (_donationType == DonationType.cash) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n <= 0) return 'Enter paid portion';
                                if (n >= totalAmt) return 'Must be less than total';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending Due', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              Text('₹${remainingAmt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Payment Mode (if Paid or Partial)
                  if (_status != DonationStatus.unpaid) ...[
                    const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildModeChip(PaymentMode.cash, 'Cash', Icons.money),
                        const SizedBox(width: 8),
                        _buildModeChip(PaymentMode.upi, 'UPI / QR', Icons.qr_code),
                        const SizedBox(width: 8),
                        _buildModeChip(PaymentMode.bankTransfer, 'Bank', Icons.account_balance),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ] else ...[
                  // IN-KIND / SAMAGRI FIELDS
                  // Item Name (Required)
                  TextFormField(
                    controller: _inKindItemController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Samagri / Item Name *',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      hintText: 'e.g. 50kg Basmati Rice, Brass Aarti Thali, Silk Saree',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11.5),
                      prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF10B981), size: 18),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981))),
                    ),
                    validator: (v) {
                      if (_donationType == DonationType.inKind && (v == null || v.trim().isEmpty)) {
                        return 'Samagri / Item name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(14),
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
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  const SizedBox(height: 12),

                  // Quantity & Estimated Value
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _inKindQuantityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Quantity / Units *',
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            hintText: 'e.g. 50 kg, 2 sets, 10 L',
                            hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
                            prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFF10B981), size: 16),
                            filled: true,
                            fillColor: const Color(0xD9081022),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981))),
                          ),
                          validator: (v) {
                            if (_donationType == DonationType.inKind && (v == null || v.trim().isEmpty)) {
                              return 'Enter quantity';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _estimatedValueController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Est. Value (₹)',
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            hintText: 'Optional',
                            hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: const Color(0xD9081022),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // In-Kind Status: Received vs Promised vs Partial
                  const Text('Delivery / Offering Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Full Received
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _status = DonationStatus.paid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _status == DonationStatus.paid ? const Color(0xFF10B981).withAlpha(40) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _status == DonationStatus.paid ? const Color(0xFF10B981) : AppTheme.glassBorder,
                                width: _status == DonationStatus.paid ? 1.5 : 1.0,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                SizedBox(height: 3),
                                Text('Received', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('मिल चुकी है', style: TextStyle(fontSize: 9.5, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Promised / Due
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _status = DonationStatus.unpaid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444).withAlpha(40) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _status == DonationStatus.unpaid ? const Color(0xFFEF4444) : AppTheme.glassBorder,
                                width: _status == DonationStatus.unpaid ? 1.5 : 1.0,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(height: 3),
                                Text('Promised', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('देना बाकी है', style: TextStyle(fontSize: 9.5, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Partial
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _status = DonationStatus.partial),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _status == DonationStatus.partial ? const Color(0xFFF59E0B).withAlpha(40) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _status == DonationStatus.partial ? const Color(0xFFF59E0B) : AppTheme.glassBorder,
                                width: _status == DonationStatus.partial ? 1.5 : 1.0,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                                SizedBox(height: 3),
                                Text('Partial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('आंशिक मिला', style: TextStyle(fontSize: 9.5, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_status == DonationStatus.partial) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Received Value / Jama Rashi (₹)',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                        hintText: 'e.g. 500',
                        hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: const Color(0xD9081022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],

                // Direct Collector Attribution
                TextFormField(
                  controller: _collectorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _donationType == DonationType.inKind ? 'Received / Recorded By *' : 'Collector Name *',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    hintText: _donationType == DonationType.inKind ? 'e.g. Puja Secretary, Member' : 'e.g. Rahul Sharma, Amit Das',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11.5),
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 18),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Collector / Receiver name is required' : null,
                ),
                if (collectors.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: collectors.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.person, size: 12, color: Colors.white70),
                            label: Text(c, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            backgroundColor: const Color(0x1F1E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() => _collectorController.text = c);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Date Picker Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_donationType == DonationType.inKind ? 'Receiving Date' : 'Date', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Change Date', style: TextStyle(fontSize: 11.5)),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes / Remarks (Optional)
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notes / Remarks (Optional)',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    hintText: _donationType == DonationType.inKind
                        ? 'e.g. Delivered directly to Puja Mandap, Pure Desi Ghee'
                        : 'e.g. Promised on Maha Ashtami, Society member',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11.5),
                    prefixIcon: const Icon(Icons.notes, color: Colors.white60, size: 18),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  ),
                ),
                const SizedBox(height: 14),

                // Physical Slip Photo Attachment Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Physical Slip / Receipt Photo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    Text(
                      _slipPhotoUrl != null ? 'Attached ✅' : 'Optional',
                      style: TextStyle(
                        fontSize: 11,
                        color: _slipPhotoUrl != null ? AppTheme.successGreen : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                                  title: _donorNameController.text.isNotEmpty ? _donorNameController.text : 'Chanda Slip',
                                  subtitle: 'Attached Physical Slip',
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
                                    'Auto-compressed Full HD • Tap to view',
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
                                    imageUrl: _slipPhotoUrl!,
                                    title: _donorNameController.text.isNotEmpty ? _donorNameController.text : 'Chanda Slip',
                                    subtitle: 'Attached Physical Slip',
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
                                    title: 'Remove Slip Photo?',
                                    message: 'Are you sure you want to remove this attached slip photo?',
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
                                      'Attach Physical Slip / Receipt Photo',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Auto-compressed Full HD • Camera or Gallery',
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

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _donationType == DonationType.inKind ? const Color(0xFF10B981) : AppTheme.primaryBlue,
                      foregroundColor: _donationType == DonationType.inKind ? Colors.white : const Color(0xFF070D1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      final isCash = _donationType == DonationType.cash;
                      final total = isCash
                          ? (double.tryParse(_totalAmountController.text.trim()) ?? 0.0)
                          : (double.tryParse(_estimatedValueController.text.trim()) ?? 0.0);

                      double paid;
                      if (_status == DonationStatus.paid) {
                        paid = total;
                      } else if (_status == DonationStatus.unpaid) {
                        paid = 0.0;
                      } else {
                        paid = isCash
                            ? (double.tryParse(_paidAmountController.text.trim()) ?? 0.0)
                            : total;
                      }

                      if (isEditing) {
                        provider.updateDonation(
                          id: widget.existing!.id,
                          donorName: _donorNameController.text.trim(),
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                          amount: total,
                          paidAmount: paid,
                          status: _status,
                          paymentMode: isCash ? _paymentMode : PaymentMode.cash,
                          collectedBy: _collectorController.text.trim(),
                          date: _selectedDate,
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                          eventId: _selectedEventId,
                          donationType: _donationType,
                          inKindItemName: isCash ? null : _inKindItemController.text.trim(),
                          inKindCategory: isCash ? null : _inKindCategory,
                          inKindQuantity: isCash ? null : _inKindQuantityController.text.trim(),
                          slipPhotoUrl: _slipPhotoUrl,
                          clearSlipPhoto: _slipPhotoUrl == null,
                        );
                      } else {
                        provider.addDonation(
                          donorName: _donorNameController.text.trim(),
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                          amount: total,
                          paidAmount: paid,
                          status: _status,
                          paymentMode: isCash ? _paymentMode : PaymentMode.cash,
                          collectedBy: _collectorController.text.trim(),
                          date: _selectedDate,
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                          eventId: _selectedEventId,
                          donationType: _donationType,
                          inKindItemName: isCash ? null : _inKindItemController.text.trim(),
                          inKindCategory: isCash ? null : _inKindCategory,
                          inKindQuantity: isCash ? null : _inKindQuantityController.text.trim(),
                          slipPhotoUrl: _slipPhotoUrl,
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text(
                      isEditing
                          ? (_donationType == DonationType.inKind ? 'Update In-Kind Offering' : 'Update Donation')
                          : (_donationType == DonationType.inKind ? 'Save In-Kind Offering' : 'Save Donation'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildModeChip(PaymentMode mode, String label, IconData icon) {
    final isSel = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppTheme.primaryBlue.withAlpha(45) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppTheme.primaryBlue : AppTheme.glassBorder,
              width: isSel ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSel ? AppTheme.primaryBlue : Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. RECORD PAYMENT DIALOG (Quickly Settle / Pay Due for Unpaid & Partial)
// ============================================================================
class RecordPaymentDialog extends StatefulWidget {
  final ChandaSlip slip;

  const RecordPaymentDialog({super.key, required this.slip});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _collectorController = TextEditingController();
  final _noteController = TextEditingController();

  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default paying amount to entire remaining pending amount
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
              primary: AppTheme.primaryBlue,
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
      setState(() => _paymentDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final slip = provider.slips.firstWhere((s) => s.id == widget.slip.id, orElse: () => widget.slip);
    final collectors = provider.availableCollectors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        maxWidth: 520,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(100), width: 1.5),
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
                        color: const Color(0xFF10B981).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        slip.isInKind ? Icons.inventory_2_rounded : Icons.price_check,
                        color: const Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slip.isInKind ? 'Receive In-Kind Offering' : 'Record Due Payment',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Donor: ${slip.donorName}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (slip.isInKind) ...[
                  // In-Kind Item Offering Details Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (slip.inKindCategory?.color ?? const Color(0xFF10B981)).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slip.inKindCategory?.icon ?? Icons.inventory_2,
                                size: 16,
                                color: slip.inKindCategory?.color ?? const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slip.inKindItemName ?? 'Samagri Item',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (slip.inKindQuantity != null && slip.inKindQuantity!.isNotEmpty)
                              Text(
                                '📦 Quantity: ${slip.inKindQuantity!}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            if (slip.amount > 0)
                              Text(
                                '💰 Est. ₹${slip.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Cash Balance Breakdown Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 10, color: Colors.white60)),
                            const SizedBox(height: 2),
                            Text('₹${slip.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: AppTheme.glassBorder),
                        Column(
                          children: [
                            const Text('Already Paid', style: TextStyle(fontSize: 10, color: Colors.white60)),
                            const SizedBox(height: 2),
                            Text('₹${slip.paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                        Container(width: 1, height: 28, color: AppTheme.glassBorder),
                        Column(
                          children: [
                            const Text('Pending Due', style: TextStyle(fontSize: 10, color: Colors.white60)),
                            const SizedBox(height: 2),
                            Text('₹${slip.pendingAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (slip.payments.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(
                                'Past Collections (${slip.payments.length})',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...slip.payments.map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy').format(p.date),
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.paymentMode.name.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, color: Colors.white60),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₹${p.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white.withAlpha(20)),
                                      ),
                                      child: PopupMenuButton<String>(
                                        tooltip: 'Options',
                                        icon: const Icon(Icons.sort_rounded, size: 15, color: Colors.white70),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                        color: const Color(0xFF0F172A),
                                        elevation: 12,
                                        offset: const Offset(0, 30),
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
                                              currency: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0),
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
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Payment Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Payment Amount Being Paid *',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: AppTheme.successGreenLight, fontSize: 18, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981))),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      if (n > slip.pendingAmount) {
                        return 'Cannot exceed pending due (₹${slip.pendingAmount.toStringAsFixed(0)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick "Pay Full" chip
                  Align(
                    alignment: Alignment.centerRight,
                    child: ActionChip(
                      avatar: const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                      label: Text('Pay Full Due (₹${slip.pendingAmount.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF10B981).withAlpha(30),
                      side: BorderSide(color: const Color(0xFF10B981).withAlpha(80)),
                      onPressed: () {
                        _amountController.text = slip.pendingAmount.toStringAsFixed(0);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Mode
                  const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildModeChip(PaymentMode.cash, 'Cash', Icons.money),
                      const SizedBox(width: 8),
                      _buildModeChip(PaymentMode.upi, 'UPI / QR', Icons.qr_code),
                      const SizedBox(width: 8),
                      _buildModeChip(PaymentMode.bankTransfer, 'Bank', Icons.account_balance),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Collector / Receiver Who Received
                TextFormField(
                  controller: _collectorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: slip.isInKind ? 'Received / Accepted By *' : 'Received / Collected By *',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 18),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                if (collectors.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: collectors.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.person, size: 12, color: Colors.white70),
                            label: Text(c, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            backgroundColor: const Color(0x1F1E293B),
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() => _collectorController.text = c);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Note / Remarks field
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Remarks / Payment Note (Optional)',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.primaryBlue, size: 18),
                    filled: true,
                    fillColor: const Color(0xD9081022),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment / Receiving Date Picker
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slip.isInKind ? 'Receiving Date' : 'Payment Date', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_paymentDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Change Date', style: TextStyle(fontSize: 11.5)),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      if (slip.isInKind) {
                        provider.updateDonation(
                          id: slip.id,
                          donorName: slip.donorName,
                          phone: slip.phone,
                          address: slip.address,
                          amount: slip.amount,
                          paidAmount: slip.amount > 0 ? slip.amount : 0.0,
                          status: DonationStatus.paid,
                          paymentMode: PaymentMode.cash,
                          collectedBy: _collectorController.text.trim().isNotEmpty
                              ? _collectorController.text.trim()
                              : slip.collectedBy,
                          date: slip.createdAt,
                          notes: _noteController.text.trim().isNotEmpty
                              ? _noteController.text.trim()
                              : slip.notes,
                          dayLabel: slip.dayLabel,
                          eventId: slip.eventId,
                          donationType: slip.donationType,
                          inKindItemName: slip.inKindItemName,
                          inKindCategory: slip.inKindCategory,
                          inKindQuantity: slip.inKindQuantity,
                        );
                      } else {
                        final payingAmt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        provider.recordPayment(
                          slipId: slip.id,
                          payingAmount: payingAmt,
                          paymentMode: _paymentMode,
                          collectedBy: _collectorController.text.trim(),
                          paymentDate: _paymentDate,
                          note: _noteController.text.trim(),
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text(
                      slip.isInKind ? 'Confirm Offering Received' : 'Confirm & Mark Paid',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildModeChip(PaymentMode mode, String label, IconData icon) {
    final isSel = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF10B981).withAlpha(45) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? const Color(0xFF10B981) : AppTheme.glassBorder,
              width: isSel ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSel ? const Color(0xFF10B981) : Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. REUSABLE DELETE CONFIRMATION DIALOG
// ============================================================================
class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        maxWidth: 440,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        border: Border.all(color: AppTheme.dangerRose.withAlpha(90), width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRose.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: AppTheme.dangerRose, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(160)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
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
                    onPressed: () => Navigator.pop(context),
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
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
