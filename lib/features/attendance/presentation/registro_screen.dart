import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header_banner.dart';
import '../../people/data/models/person_model.dart';
import '../../people/presentation/people_controller.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  late final PeopleController _controller;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isNew = false;
  bool _showNotice = true;

  @override
  void initState() {
    super.initState();
    _controller = PeopleController();
    _controller.addListener(_onControllerChange);

    // Auto load people on screen enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchPeople();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthDayController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;

    // Sync form inputs when entering edit mode
    final editingPerson = _controller.editingPerson;
    if (editingPerson != null &&
        (_nameController.text != editingPerson.name ||
            _phoneController.text != editingPerson.phone ||
            _birthDayController.text != editingPerson.birthDay)) {
      _nameController.text = editingPerson.name;
      _phoneController.text = editingPerson.phone;
      _birthDayController.text = editingPerson.birthDay;
      setState(() {
        _isNew = editingPerson.isNew;
      });
    }

    // Show SnackBars for messages
    final success = _controller.successMessage;
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(success)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _controller.clearMessages();
    }

    final error = _controller.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _controller.clearMessages();
    }
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _birthDayController.clear();
    setState(() {
      _isNew = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final day = pickedDate.day.toString().padLeft(2, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');
      final year = pickedDate.year.toString();
      _birthDayController.text = '$day/$month/$year';
    }
  }

  void _onDateInputChanged(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) return;

    var formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (digits.length >= 5) {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    }

    if (formatted != text) {
      _birthDayController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (_controller.isEditing) {
      final success = await _controller.updatePerson(
        name: _nameController.text,
        phone: _phoneController.text,
        birthDay: _birthDayController.text,
        isNew: _isNew,
      );
      if (success) {
        _resetForm();
      }
    } else {
      final success = await _controller.registerPerson(
        name: _nameController.text,
        phone: _phoneController.text,
        birthDay: _birthDayController.text,
        isNew: _isNew,
      );
      if (success) {
        _resetForm();
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleCancelEdit() {
    _controller.cancelEditing();
    _resetForm();
  }

  void _confirmDelete(PersonModel person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${person.name}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.deletePerson(person.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _controller.isEditing;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                AppHeaderBanner(
                  title: isEditing
                      ? '✏️ Editar Persona'
                      : '👥 Registro de Personas',
                  subtitle: isEditing
                      ? 'Modifica la información de la persona seleccionada'
                      : 'Ingresa los datos para registrar un asistente nuevo o recurrente',
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice Banner
                      if (_showNotice) _buildNoticeBanner(),

                      // Form Card
                      _buildFormCard(),
                      const SizedBox(height: 24),

                      // People List Section
                      _buildPeopleListSection(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '¡Nueva opción! Puedes marcar a las personas como "nuevos" si es su primera vez.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
            onPressed: () => setState(() => _showNotice = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final isEditing = _controller.isEditing;
    final isSaving = _controller.isSaving;

    return AppCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          const Text(
            'Nombre completo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ej. Juan Pérez',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Phone Field
          const Text(
            'Teléfono (8 dígitos)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Ej. 88888888',
              counterText: '',
              prefixIcon: const Icon(Icons.phone_android_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Birthday Field
          const Text(
            'Fecha de nacimiento',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _birthDayController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: _onDateInputChanged,
            decoration: InputDecoration(
              hintText: 'dd/mm/aaaa',
              counterText: '',
              prefixIcon: const Icon(Icons.cake_outlined, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF4F46E5),
                ),
                onPressed: _pickDate,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Switch Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              value: _isNew,
              onChanged: (val) => setState(() => _isNew = val),
              title: const Row(
                children: [
                  Text('⭐ ', style: TextStyle(fontSize: 16)),
                  Text(
                    '¿Es nuevo?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
              subtitle: const Text(
                'Marca si es la primera vez que asiste',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              activeThumbColor: const Color(0xFF4F46E5),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 20),

          // Submit / Cancel Buttons
          Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: isSaving ? null : _handleCancelEdit,
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSaving ? null : _handleSubmit,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Persona',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleListSection() {
    final isLoading = _controller.isLoadingPeople;
    final people = _controller.people;
    final dataLoaded = _controller.dataLoaded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📋 Personas Registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            if (dataLoaded)
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
                tooltip: 'Actualizar lista',
                onPressed: () => _controller.fetchPeople(),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // If data not loaded yet
        if (!dataLoaded)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLoading ? null : () => _controller.fetchPeople(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        )
                      : Column(
                          children: const [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 40,
                              color: Color(0xFF4F46E5),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Cargar lista de personas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Toca para ver todas las personas registradas',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          )
        else ...[
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (text) => _controller.filterPeople(text),
            decoration: InputDecoration(
              hintText: '🔍 Buscar por nombre o teléfono...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _controller.filterPeople('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List Body
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            )
          else if (people.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se encontraron personas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'Intenta con otro término de búsqueda'
                          : 'Registra la primera persona arriba',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: people.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final person = people[index];
                return _buildPersonCard(person);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildPersonCard(PersonModel person) {
    final isDeleting = _controller.deletingId == person.id;

    return AppCard(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
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
                        Expanded(
                          child: Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (person.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFCD34D),
                              ),
                            ),
                            child: const Text(
                              'NUEVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          person.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.cake, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          person.birthDay,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: () {
                    _controller.startEditing(person);
                    _scrollToTop();
                  },
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF4F46E5),
                  ),
                  label: const Text(
                    'Editar',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                  onPressed: isDeleting ? null : () => _confirmDelete(person),
                  icon: isDeleting
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
