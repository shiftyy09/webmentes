// lib/ui/dialogs/service_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/alap/marka_adatok.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

class ServiceEditorDialog extends StatefulWidget {
  final Szerviz? service;

  const ServiceEditorDialog({super.key, this.service});

  @override
  State<ServiceEditorDialog> createState() => _ServiceEditorDialogState();
}

class _ServiceEditorDialogState extends State<ServiceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _noteController;
  
  final TextEditingController _oilTypeController = TextEditingController();
  final TextEditingController _oilAmountController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedServiceType;
  
  bool _isOilChange = false;
  bool _isVignette = false;

  String? _selectedVignetteType;
  final List<String> _vignetteTypes = ['Heti (10 napos)', 'Havi', 'Éves (Országos)', 'Éves (Megyei)'];

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    String? initialServiceType;
    String initialNote = '';
    String initialOilType = '';
    String initialOilAmount = '';
    String initialBrand = '';
    String? initialVignetteType;

    if (widget.service != null) {
      String description = widget.service!.description;
      
      if (description.startsWith(REMINDER_PREFIX)) {
        description = description.replaceFirst(REMINDER_PREFIX, '');
      }
      
      if (description.contains(' - ')) {
        final parts = description.split(' - ');
        description = parts[0];
        if (parts.length > 1) initialNote = parts[1];
      }

      if (description.contains('(')) {
        final typeParts = description.split(' (');
        initialServiceType = typeParts[0];
        
        final detailsString = typeParts[1].replaceAll(')', '');
        
        if (initialServiceType == 'Pályamatrica') {
          for (var type in _vignetteTypes) {
            if (detailsString.contains(type)) {
              initialVignetteType = type;
              break;
            }
          }
          if (initialVignetteType == null && _vignetteTypes.contains(detailsString)) {
            initialVignetteType = detailsString;
          }
        } else {
          final details = detailsString.split(', ');
          for (var detail in details) {
            if (detail.endsWith('L')) {
              initialOilAmount = detail.replaceAll('L', '');
            } else if (detail.contains('W-') || detail.contains('W')) {
              initialOilType = detail;
            } else {
              if (initialBrand.isEmpty) initialBrand = detail;
              else initialBrand += ' $detail';
            }
          }
        }
      } else {
        initialServiceType = description;
      }
    }

    if (initialServiceType != null && !SERVICE_DEFINITIONS.containsKey(initialServiceType) && initialServiceType != 'Pályamatrica') {
    }

    _selectedServiceType = initialServiceType;
    _isOilChange = _selectedServiceType == 'Olajcsere';
    _isVignette = _selectedServiceType == 'Pályamatrica';
    _selectedVignetteType = initialVignetteType;
    
    _mileageController = TextEditingController(text: widget.service?.mileage.toString() ?? '');
    _costController = TextEditingController(text: widget.service?.cost.toString() ?? '');
    _noteController = TextEditingController(text: initialNote);
    _brandController.text = initialBrand;
    _oilTypeController.text = initialOilType;
    _oilAmountController.text = initialOilAmount;

    if (_isEditing) {
      _selectedDate = widget.service!.date;
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _noteController.dispose();
    _oilTypeController.dispose();
    _oilAmountController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() { _selectedDate = pickedDate; });
    }
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      String description = _selectedServiceType!;
      
      final List<String> details = [];
      
      if (_isVignette && _selectedVignetteType != null) {
        details.add(_selectedVignetteType!);
      } else {
        if (_brandController.text.isNotEmpty && !_isVignette) {
          details.add(_brandController.text);
        }
        if (_isOilChange) {
          if (_oilTypeController.text.isNotEmpty) details.add(_oilTypeController.text);
          if (_oilAmountController.text.isNotEmpty) details.add('${_oilAmountController.text}L');
        }
      }
      
      if (details.isNotEmpty) {
        description += ' (${details.join(', ')})';
      }

      if (_noteController.text.isNotEmpty) {
        description += ' - ${_noteController.text}';
      }

      final updatedService = Szerviz(
        id: widget.service?.id,
        description: description,
        date: _selectedDate,
        mileage: int.tryParse(_mileageController.text) ?? 0,
        cost: double.tryParse(_costController.text) ?? 0,
      );
      Navigator.of(context).pop(updatedService);
    }
  }

  String _getDateLabel(String serviceType) {
    if (serviceType.contains('Műszaki')) return 'Utolsó vizsga dátuma';
    if (serviceType.contains('biztosítás') || serviceType.contains('CASCO')) return 'Évforduló dátuma';
    if (serviceType.contains('matrica')) return 'Érvényesség kezdete';
    return 'Utolsó csere dátuma';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy. MM. dd.');
    final serviceTypes = SERVICE_DEFINITIONS.keys.toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.build_circle, color: theme.colorScheme.secondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isEditing ? 'Szerviz szerkesztése' : 'Szerviz rögzítése',
                    style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: serviceTypes.contains(_selectedServiceType) ? _selectedServiceType : null,
                      items: serviceTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setState(() { 
                        _selectedServiceType = value; 
                        _isOilChange = value == 'Olajcsere';
                        _isVignette = value == 'Pályamatrica';
                      }),
                      decoration: InputDecoration(
                        labelText: 'Szerviz típusa',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        prefixIcon: const Icon(Icons.list),
                      ),
                      validator: (value) => (value == null) ? 'Kötelező választani' : null,
                    ),
                    
                    const SizedBox(height: 16),

                    if (_isVignette) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedVignetteType,
                        items: _vignetteTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (value) => setState(() => _selectedVignetteType = value),
                        decoration: _buildInputDecoration(label: 'Matrica időtartama', icon: Icons.timer, isRequired: true),
                        validator: (value) => (value == null) ? 'Kötelező választani' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedServiceType != null && !_isVignette)
                      LayoutBuilder(
                        builder: (context, constraints) => Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') return const Iterable<String>.empty();
                            final brands = getBrandsForServiceType(_selectedServiceType!);
                            return brands.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _brandController.text = selection;
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            if (textEditingController.text != _brandController.text) {
                                textEditingController.text = _brandController.text;
                            }
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                              onChanged: (val) => _brandController.text = val,
                              decoration: _buildInputDecoration(label: 'Márka (pl. Bosch)', icon: Icons.branding_watermark, isRequired: false),
                            );
                          },
                        ),
                      ),

                    if (_isOilChange) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildModernField(controller: _oilTypeController, label: 'Típus (pl. 5W-30)', icon: Icons.opacity, isRequired: false)),
                            const SizedBox(width: 16),
                            // ITT A VÁLTOZÁS: isDecimal esetén is engedjük a kötőjelet, ha Liter a címke
                            Expanded(child: _buildModernField(controller: _oilAmountController, label: 'Liter', icon: Icons.water_drop, isDecimal: true, isRequired: false)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(dateFormat.format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (!_isVignette)
                          Expanded(child: _buildModernField(controller: _mileageController, label: 'Km óra', suffix: 'km', icon: Icons.speed))
                        else
                          const Spacer(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    _buildModernField(controller: _costController, label: 'Költség', suffix: 'Ft', icon: Icons.payments),
                    
                    const SizedBox(height: 16),
                    _buildModernField(controller: _noteController, label: 'Megjegyzés', icon: Icons.notes, isRequired: false),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Mégse'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('MENTÉS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, bool isRequired = true, String? suffix}) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    bool isDecimal = false,
    bool isRequired = true,
  }) {
    // Regex módosítása: Ha a címke tartalmazza a 'Liter' szót, engedjük a kötőjelet is.
    final bool allowRange = label.contains('Liter');
    final String regexString = allowRange ? r'[0-9.,-]' : (isDecimal ? r'[0-9.,]' : r'[0-9]');

    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(label: label, icon: icon, isRequired: isRequired, suffix: suffix),
      // Ha kötőjelet is engedünk, akkor a billentyűzet inkább szöveges legyen, hogy könnyen elérhető legyen a jel
      keyboardType: allowRange ? TextInputType.text : (isNumber ? TextInputType.numberWithOptions(decimal: isDecimal) : TextInputType.text),
      // JAVÍTVA: A szűrés most már engedi a kötőjelet, ha kell
      inputFormatters: isDecimal || label.contains('Km') || label.contains('Költség') || allowRange
          ? [FilteringTextInputFormatter.allow(RegExp(regexString))] 
          : [],
      validator: (value) => (isRequired && (value?.isEmpty ?? true)) ? 'Kötelező' : null,
    );
  }
  
  // Segédváltozó a keyboardType logikához, mivel a paraméterek között csak isDecimal van
  bool get isNumber => true; // Feltételezzük, hogy ez a metódus számokhoz van, kivéve ha allowRange felülírja
}
