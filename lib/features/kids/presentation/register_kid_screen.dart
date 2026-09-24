import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header_banner.dart';
import '../data/models/kid_model.dart';
import 'register_kid_controller.dart';

class RegisterKidScreen extends StatefulWidget {
  const RegisterKidScreen({super.key});

  @override
  State<RegisterKidScreen> createState() => _RegisterKidScreenState();
}

class _RegisterKidScreenState extends State<RegisterKidScreen> {
  late final RegisterKidController _controller;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _searchNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RegisterKidController();
    _controller.loadKids();
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (!mounted) return;

    // Show error snackbar if error message updated
    if (_controller.errorMessage != null) {
      final msg = _controller.errorMessage!;
      _controller.clearErrorMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Show success snackbar if success message updated
    if (_controller.successMessage != null) {
      final msg = _controller.successMessage!;
      _controller.clearSuccessMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _birthDayController.dispose();
    _commentsController.dispose();
    _searchNameController.dispose();
    super.dispose();
  }

  void _syncFormWithController() {
    _nameController.text = _controller.name;
    _birthDayController.text = _controller.birthDay;
    _commentsController.text = _controller.comments;
  }

  void _clearFormControllers() {
    _nameController.clear();
    _birthDayController.clear();
    _commentsController.clear();
    _controller.clearForm();
  }

  void _onStartEditing(KidModel kid) {
    _controller.startEditing(kid);
    _syncFormWithController();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_birthDayController.text.length == 10) {
      final parts = _birthDayController.text.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          initialDate = DateTime(year, month, day);
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      final formatted = '$day/$month/$year';
      _birthDayController.text = formatted;
      _controller.setBirthDay(formatted);
    }
  }

  void _showClassSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final classes = _controller.classes;
                final selected = _controller.selectedClasses;

                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.5,
                  minChildSize: 0.3,
                  maxChildSize: 0.85,
                  builder: (_, scrollController) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Seleccionar Clases',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Elige una o más clases para el niño',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: classes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay clases disponibles',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: classes.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = classes[index];
                                      final isSelected = selected.contains(
                                        item.name,
                                      );

                                      return CheckboxListTile(
                                        value: isSelected,
                                        activeColor: const Color(0xFF4F46E5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        title: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        onChanged: (_) {
                                          _controller.toggleClassSelection(
                                            item.name,
                                          );
                                          setModalState(() {});
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Listo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(KidModel kid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar niño'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${kid.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteKid(kid.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _controller.loadKids(),
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Banner
                  AppHeaderBanner(
                    title: _controller.isEditing
                        ? '✏️ Editar información'
                        : '👶 Nuevo Registro',
                    subtitle: _controller.isEditing
                        ? 'Modifica los datos del niño y guarda los cambios'
                        : 'Ingresa los datos para agregar un niño al sistema',
                    onBack: () => Navigator.pop(context),
                  ),

                  // 2. Quick Stats Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            label: 'Total',
                            value: '${_controller.totalKidsCount}',
                            color: const Color(0xFF4F46E5),
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            label: 'Filtrados',
                            value: '${_controller.filteredKidsCount}',
                            color: const Color(0xFFF59E0B),
                            icon: Icons.filter_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            label: 'Nuevos',
                            value: '${_controller.newKidsCount}',
                            color: const Color(0xFF10B981),
                            icon: Icons.fiber_new_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Form Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AppCard(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _controller.isEditing
                                    ? 'Formulario de Edición'
                                    : 'Datos del Niño',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (!_controller.isEditing)
                                TextButton.icon(
                                  onPressed: _showLinkPersonModal,
                                  icon: const Icon(
                                    Icons.link_rounded,
                                    size: 16,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  label: const Text(
                                    'Vincular Persona',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name Input
                          TextFormField(
                            controller: _nameController,
                            onChanged: (val) => _controller.setName(val),
                            decoration: InputDecoration(
                              labelText: 'Nombre Completo *',
                              hintText: 'Ej: Juan Pérez',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF6366F1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Birthday Input
                          TextFormField(
                            controller: _birthDayController,
                            keyboardType: TextInputType.datetime,
                            onChanged: (val) =>
                                _controller.setBirthDayFormatted(val),
                            decoration: InputDecoration(
                              labelText: 'Fecha de Nacimiento (dd/mm/aaaa) *',
                              hintText: 'Ej: 15/08/2015',
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: Color(0xFF6366F1),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF6366F1),
                                ),
                                onPressed: () => _selectDate(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Class Selection Trigger
                          const Text(
                            'Clases Asignadas *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _showClassSelectionBottomSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    color: Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _controller.selectedClasses.isEmpty
                                        ? const Text(
                                            'Seleccionar clases...',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: _controller
                                                .selectedClasses
                                                .map(
                                                  (c) => Chip(
                                                    label: Text(
                                                      c,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFF6366F1),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Is New Switch
                          SwitchListTile(
                            value: _controller.isNew,
                            onChanged: (val) => _controller.setIsNew(val),
                            activeTrackColor: const Color(0xFF6366F1),
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '¿Es nuevo?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            subtitle: const Text(
                              'Marca esta opción si es su primera vez',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Comments Input
                          TextFormField(
                            controller: _commentsController,
                            maxLines: 3,
                            onChanged: (val) => _controller.setComments(val),
                            decoration: InputDecoration(
                              labelText: 'Comentarios / Observaciones',
                              hintText: 'Alergias, tutor, notas especiales...',
                              alignLabelWithHint: true,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(
                                  Icons.comment_outlined,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit & Cancel Buttons
                          Row(
                            children: [
                              if (_controller.isEditing) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _clearFormControllers,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF94A3B8),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _controller.isLoading
                                      ? null
                                      : () async {
                                          final success = await _controller
                                              .saveKid();
                                          if (success) {
                                            _clearFormControllers();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _controller.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _controller.isEditing
                                              ? 'Guardar Cambios'
                                              : 'Registrar Niño',
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
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Search & Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 Niños Registrados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Search by name input
                            Expanded(
                              child: TextField(
                                controller: _searchNameController,
                                onChanged: (val) =>
                                    _controller.setSearchName(val),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF64748B),
                                  ),
                                  suffixIcon: _controller.searchName.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchNameController.clear();
                                            _controller.setSearchName('');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Class Filter Dropdown
                            DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  value: _controller.searchClass.isEmpty
                                      ? null
                                      : _controller.searchClass,
                                  hint: const Text(
                                    'Clase',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.filter_list,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('Todas las clases'),
                                    ),
                                    ..._controller.classes.map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.name,
                                        child: Text(c.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    _controller.setSearchClass(val ?? '');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Registered Kids List
                  if (_controller.isLoadingKids)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    )
                  else if (_controller.filteredKids.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron niños',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Intenta cambiar el término de búsqueda o filtro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (_controller.searchName.isNotEmpty ||
                              _controller.searchClass.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                _searchNameController.clear();
                                _controller.clearFilters();
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Limpiar filtros'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _controller.filteredKids.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final kid = _controller.filteredKids[index];
                          return _buildKidCard(kid);
                        },
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidCard(KidModel kid) {
    final initials = kid.name.trim().isNotEmpty
        ? kid.name
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : '?';

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Circle
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kid.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (kid.isNew) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: const Text(
                          'Nuevo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Birthday
                Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nacimiento: ${kid.birthDay.isEmpty ? "No registrado" : kid.birthDay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Classes Chips
                if (kid.classes.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: kid.classes
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                if (kid.comments.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '💬 ${kid.comments}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions (Edit / Delete)
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                tooltip: 'Editar',
                onPressed: () => _onStartEditing(kid),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'Eliminar',
                onPressed: () => _confirmDelete(kid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkPersonModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _LinkPersonModal(
          onPersonSelected: (name, birthDay) {
            _nameController.text = name;
            _birthDayController.text = birthDay;
            _controller.setName(name);
            _controller.setBirthDayFormatted(birthDay);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

class _LinkPersonModal extends StatefulWidget {
  final void Function(String name, String birthDay) onPersonSelected;

  const _LinkPersonModal({required this.onPersonSelected});

  @override
  State<_LinkPersonModal> createState() => _LinkPersonModalState();
}

class _LinkPersonModalState extends State<_LinkPersonModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _persons = [];
  List<Map<String, dynamic>> _filteredPersons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPersons();
  }

  Future<void> _fetchPersons() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('persons').get();
      final list = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? '',
          'birthDay': data['birthDay'] as String? ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _persons = list;
          _filteredPersons = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filter(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredPersons = _persons);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredPersons = _persons
            .where((p) => p['name'].toString().toLowerCase().contains(q))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🔍 Seleccionar Persona Registrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige un miembro para importar sus datos sin duplicarlo',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      )
                    : _filteredPersons.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron personas',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filteredPersons.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final p = _filteredPersons[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(
                                p['name'].isNotEmpty
                                    ? p['name'][0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              p['birthDay'].isNotEmpty
                                  ? 'Cumpleaños: ${p['birthDay']}'
                                  : 'Sin fecha de nacimiento',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF4F46E5),
                            ),
                            onTap: () => widget.onPersonSelected(
                              p['name'],
                              p['birthDay'],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
