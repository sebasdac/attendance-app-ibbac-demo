import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MergeDuplicatesModal extends StatefulWidget {
  final VoidCallback onMerged;

  const MergeDuplicatesModal({super.key, required this.onMerged});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onMerged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MergeDuplicatesModal(onMerged: onMerged),
    );
  }

  @override
  State<MergeDuplicatesModal> createState() => _MergeDuplicatesModalState();
}

class _MergeDuplicatesModalState extends State<MergeDuplicatesModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _isProcessing = false;
  String _processingMessage = '';

  // 1. Cross entries (Present in People & Kids)
  List<Map<String, dynamic>> _crossDuplicates = [];

  // 2. Adult duplicate clusters (within 'people')
  List<List<Map<String, dynamic>>> _peopleDuplicates = [];

  // 3. Kid duplicate clusters (within 'kids')
  List<List<Map<String, dynamic>>> _kidsDuplicates = [];

  // Set of already synced / ignored keys
  final Set<String> _syncedKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scanDuplicates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _norm(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _scanDuplicates({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _loading = true);
    }

    try {
      final db = FirebaseFirestore.instance;

      // 0. Fetch already synced / ignored markers
      final syncedSnap = await db.collection('ignoredDuplicates').get();
      _syncedKeys.clear();
      for (final doc in syncedSnap.docs) {
        _syncedKeys.add(doc.id);
      }

      // 1. Fetch from 'people' and 'kids'
      final peopleSnap = await db.collection('people').get();
      final kidsSnap = await db.collection('kids').get();

      final List<Map<String, dynamic>> allPeople = peopleSnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      final List<Map<String, dynamic>> allKids = kidsSnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      // --- Group 1: Cross Matches (People & Kids) ---
      final List<Map<String, dynamic>> cross = [];
      final Map<String, List<Map<String, dynamic>>> kidsByNorm = {};
      for (final kid in allKids) {
        final name = (kid['name'] as String? ?? '').trim();
        if (name.isNotEmpty) {
          kidsByNorm.putIfAbsent(_norm(name), () => []).add(kid);
        }
      }

      for (final person in allPeople) {
        final name = (person['name'] as String? ?? '').trim();
        final normName = _norm(name);
        if (kidsByNorm.containsKey(normName)) {
          for (final kid in kidsByNorm[normName]!) {
            final key1 = '${person['id']}_${kid['id']}';
            final key2 = '${kid['id']}_${person['id']}';
            final isAlreadySynced =
                _syncedKeys.contains(key1) || _syncedKeys.contains(key2);

            cross.add({
              'name': name,
              'person': person,
              'kid': kid,
              'key': key1,
              'isSynced': isAlreadySynced,
            });
          }
        }
      }

      // --- Group 2: Duplicates within 'people' ---
      final Map<String, List<Map<String, dynamic>>> peopleGroups = {};
      for (final person in allPeople) {
        final name = (person['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;
        final normName = _norm(name);
        peopleGroups.putIfAbsent(normName, () => []).add(person);
      }
      final List<List<Map<String, dynamic>>> peopleDups = [];
      for (final entry in peopleGroups.entries) {
        if (entry.value.length > 1) {
          final group = entry.value;
          final ignoreKey = 'people_${entry.key}';
          if (!_syncedKeys.contains(ignoreKey)) {
            peopleDups.add(group);
          }
        }
      }

      // --- Group 3: Duplicates within 'kids' ---
      final Map<String, List<Map<String, dynamic>>> kidsGroups = {};
      for (final kid in allKids) {
        final name = (kid['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;
        final normName = _norm(name);
        kidsGroups.putIfAbsent(normName, () => []).add(kid);
      }
      final List<List<Map<String, dynamic>>> kidsDups = [];
      for (final entry in kidsGroups.entries) {
        if (entry.value.length > 1) {
          final group = entry.value;
          final ignoreKey = 'kids_${entry.key}';
          if (!_syncedKeys.contains(ignoreKey)) {
            kidsDups.add(group);
          }
        }
      }

      if (mounted) {
        setState(() {
          _crossDuplicates = cross;
          _peopleDuplicates = peopleDups;
          _kidsDuplicates = kidsDups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ==========================================
  // SYNC & LINK (KID + PEOPLE = SAME PERSON)
  // ==========================================

  /// Link and synchronize data between People and Kids (keeps both records active)
  Future<void> _linkAndSync(Map<String, dynamic> pair) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Sincronizando datos entre Personas y Kids...';
    });

    try {
      final db = FirebaseFirestore.instance;
      final Map<String, dynamic> person = pair['person'];
      final Map<String, dynamic> kid = pair['kid'];

      final String personId = person['id'];
      final String kidId = kid['id'];
      final String syncKey = pair['key'] as String;

      // 1. Determine best birthday and phone
      String bestBirthDay = (person['birthDay'] ?? '').toString();
      if (bestBirthDay.isEmpty) {
        bestBirthDay = (kid['birthDay'] ?? '').toString();
      }

      String bestPhone = (person['phone'] ?? '').toString();
      if (bestPhone.isEmpty) {
        bestPhone = (kid['phone'] ?? '').toString();
      }

      final rawClasses = kid['classes'] ?? [];
      final List<String> classes = (rawClasses is List)
          ? rawClasses.map((e) => e.toString()).toList()
          : [];

      final batch = db.batch();

      // 2. Update Person document
      batch.set(
        db.collection('people').doc(personId),
        {
          'birthDay': bestBirthDay,
          'phone': bestPhone,
          'isKid': true,
          'classes': classes,
          'linkedKidId': kidId,
          'syncedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Update Kid document
      batch.set(
        db.collection('kids').doc(kidId),
        {
          'birthDay': bestBirthDay,
          if (bestPhone.isNotEmpty) 'phone': bestPhone,
          'linkedPersonId': personId,
          'syncedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Mark as synchronized
      batch.set(
        db.collection('ignoredDuplicates').doc(syncKey),
        {
          'type': 'linked_sync',
          'personId': personId,
          'kidId': kidId,
          'name': pair['name'],
          'syncedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      widget.onMerged();
      await _scanDuplicates(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ¡"${pair['name']}" vinculado y sincronizado en Personas y Kids!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==========================================
  // UNIFY ACTIONS (FOR ACCIDENTAL DUPLICATES)
  // ==========================================

  /// Unify: Keep only in Kids (delete from People)
  Future<void> _mergeCrossKeepKid(Map<String, dynamic> pair) async {
    final confirmed = await _confirmDialog(
      title: 'Mover a solo Kids',
      message:
          'Se conservará a "${pair['name']}" exclusivamente en Kids. '
          'Las asistencias del servicio general se migrarán a Kids y se eliminará de Personas.',
    );
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Migrando asistencias y unificando en Kids...';
    });

    try {
      final db = FirebaseFirestore.instance;
      final Map<String, dynamic> person = pair['person'];
      final Map<String, dynamic> kid = pair['kid'];

      final String personId = person['id'];
      final String kidId = kid['id'];

      // Merge info into kid
      final phone = (person['phone'] ?? '').toString();
      final birthDay = (person['birthDay'] ?? '').toString();

      final updateKid = <String, dynamic>{};
      if (phone.isNotEmpty && (kid['phone'] == null || kid['phone'] == '')) {
        updateKid['phone'] = phone;
      }
      if (birthDay.isNotEmpty &&
          (kid['birthDay'] == null || kid['birthDay'] == '')) {
        updateKid['birthDay'] = birthDay;
      }
      if (updateKid.isNotEmpty) {
        await db.collection('kids').doc(kidId).update(updateKid);
      }

      // Migrate attendance from personId to kidId
      final rawClasses = kid['classes'];
      String? defaultClass;
      if (rawClasses is List && rawClasses.isNotEmpty) {
        defaultClass = rawClasses.first.toString();
      }

      final attSnap = await db
          .collection('attendance')
          .where('personId', isEqualTo: personId)
          .get();

      if (attSnap.docs.isNotEmpty) {
        final batch = db.batch();
        for (final doc in attSnap.docs) {
          final Map<String, dynamic> up = {
            'kidId': kidId,
            'personId': FieldValue.delete(),
          };
          if (defaultClass != null) {
            up['class'] = defaultClass;
          }
          batch.update(doc.reference, up);
        }
        await batch.commit();
      }

      // Delete from people
      await db.collection('people').doc(personId).delete();

      widget.onMerged();
      await _scanDuplicates(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡"${pair['name']}" consolidado solo en Kids!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unificar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Unify: Keep only in People (delete from Kids)
  Future<void> _mergeCrossKeepAdult(Map<String, dynamic> pair) async {
    final confirmed = await _confirmDialog(
      title: 'Mover a solo Personas',
      message:
          'Se conservará a "${pair['name']}" exclusivamente en Personas. '
          'Las asistencias de clases de niños se migrarán a Personas y se eliminará de Kids.',
    );
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Migrando asistencias y unificando en Personas...';
    });

    try {
      final db = FirebaseFirestore.instance;
      final Map<String, dynamic> person = pair['person'];
      final Map<String, dynamic> kid = pair['kid'];

      final String personId = person['id'];
      final String kidId = kid['id'];

      // Merge birthday
      final kidBirth = (kid['birthDay'] ?? '').toString();
      if (kidBirth.isNotEmpty &&
          (person['birthDay'] == null || person['birthDay'] == '')) {
        await db.collection('people').doc(personId).update({
          'birthDay': kidBirth,
        });
      }

      // Migrate attendance from kidId to personId
      final attSnap = await db
          .collection('attendance')
          .where('kidId', isEqualTo: kidId)
          .get();

      if (attSnap.docs.isNotEmpty) {
        final batch = db.batch();
        for (final doc in attSnap.docs) {
          batch.update(doc.reference, {
            'personId': personId,
            'kidId': FieldValue.delete(),
            'class': FieldValue.delete(),
          });
        }
        await batch.commit();
      }

      // Delete from kids
      await db.collection('kids').doc(kidId).delete();

      widget.onMerged();
      await _scanDuplicates(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡"${pair['name']}" consolidado solo en Personas!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unificar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Merge multiple people duplicates into one primary adult
  Future<void> _mergePeopleCluster(List<Map<String, dynamic>> cluster) async {
    if (cluster.length < 2) return;
    final primary = cluster.first;
    final primaryId = primary['id'] as String;
    final primaryName = primary['name'] as String;
    final secondaries = cluster.sublist(1);

    final confirmed = await _confirmDialog(
      title: 'Unificar Adultos Repetidos',
      message:
          'Se unificarán los ${cluster.length} registros repetidos de "$primaryName" en uno solo. '
          'Todas las asistencias se vincularán al registro principal y los duplicados serán eliminados.',
    );
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Unificando registros de personas y asistencias...';
    });

    try {
      final db = FirebaseFirestore.instance;

      String bestPhone = (primary['phone'] ?? '').toString();
      String bestBirthDay = (primary['birthDay'] ?? '').toString();

      for (final sec in secondaries) {
        final p = (sec['phone'] ?? '').toString();
        final b = (sec['birthDay'] ?? '').toString();
        if (bestPhone.isEmpty && p.isNotEmpty) bestPhone = p;
        if (bestBirthDay.isEmpty && b.isNotEmpty) bestBirthDay = b;
      }

      final updateData = <String, dynamic>{};
      if (bestPhone.isNotEmpty &&
          (primary['phone'] == null || primary['phone'] == '')) {
        updateData['phone'] = bestPhone;
      }
      if (bestBirthDay.isNotEmpty &&
          (primary['birthDay'] == null || primary['birthDay'] == '')) {
        updateData['birthDay'] = bestBirthDay;
      }
      if (updateData.isNotEmpty) {
        await db.collection('people').doc(primaryId).update(updateData);
      }

      for (final sec in secondaries) {
        final secId = sec['id'] as String;

        final attSnap = await db
            .collection('attendance')
            .where('personId', isEqualTo: secId)
            .get();

        if (attSnap.docs.isNotEmpty) {
          final batch = db.batch();
          for (final doc in attSnap.docs) {
            batch.update(doc.reference, {'personId': primaryId});
          }
          await batch.commit();
        }

        await db.collection('people').doc(secId).delete();
      }

      widget.onMerged();
      await _scanDuplicates(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Registros de "$primaryName" unificados con éxito!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unificar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Merge multiple kid duplicates into one primary kid
  Future<void> _mergeKidsCluster(List<Map<String, dynamic>> cluster) async {
    if (cluster.length < 2) return;
    final primary = cluster.first;
    final primaryId = primary['id'] as String;
    final primaryName = primary['name'] as String;
    final secondaries = cluster.sublist(1);

    final confirmed = await _confirmDialog(
      title: 'Unificar Niños Repetidos',
      message:
          'Se unificarán los ${cluster.length} registros repetidos de "$primaryName" en uno solo. '
          'Se combinarán todas sus clases y asistencias en el registro principal.',
    );
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Unificando registros de niños y clases...';
    });

    try {
      final db = FirebaseFirestore.instance;

      final Set<String> combinedClasses = {};
      final rawPrimaryClasses = primary['classes'];
      if (rawPrimaryClasses is List) {
        combinedClasses.addAll(rawPrimaryClasses.map((e) => e.toString()));
      }

      String bestBirthDay = (primary['birthDay'] ?? '').toString();
      String bestComments = (primary['comments'] ?? '').toString();

      for (final sec in secondaries) {
        final rawC = sec['classes'];
        if (rawC is List) {
          combinedClasses.addAll(rawC.map((e) => e.toString()));
        }
        final b = (sec['birthDay'] ?? '').toString();
        final c = (sec['comments'] ?? '').toString();
        if (bestBirthDay.isEmpty && b.isNotEmpty) bestBirthDay = b;
        if (bestComments.isEmpty && c.isNotEmpty) bestComments = c;
      }

      await db.collection('kids').doc(primaryId).update({
        'classes': combinedClasses.toList(),
        if (bestBirthDay.isNotEmpty) 'birthDay': bestBirthDay,
        if (bestComments.isNotEmpty) 'comments': bestComments,
      });

      for (final sec in secondaries) {
        final secId = sec['id'] as String;

        final attSnap = await db
            .collection('attendance')
            .where('kidId', isEqualTo: secId)
            .get();

        if (attSnap.docs.isNotEmpty) {
          final batch = db.batch();
          for (final doc in attSnap.docs) {
            batch.update(doc.reference, {'kidId': primaryId});
          }
          await batch.commit();
        }

        await db.collection('kids').doc(secId).delete();
      }

      widget.onMerged();
      await _scanDuplicates(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Registros de niños de "$primaryName" unificados con éxito!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unificar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.merge_type_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  // ==========================================
  // UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔗 Unificar o Vincular Registros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Sincroniza alumnos presentes en Personas y Kids',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loading || _isProcessing ? null : _scanDuplicates,
                  tooltip: 'Volver a escanear',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF4F46E5),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Personas y Kids (${_crossDuplicates.length})'),
              Tab(text: 'Personas Repetidas (${_peopleDuplicates.length})'),
              Tab(text: 'Kids Repetidos (${_kidsDuplicates.length})'),
            ],
          ),

          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFEEF2FF),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _processingMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCrossList(),
                      _buildPeopleDupsList(),
                      _buildKidsDupsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text(
              '¡Todo al día!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Cross List (People & Kids) ---
  Widget _buildCrossList() {
    if (_crossDuplicates.isEmpty) {
      return _buildEmptyState(
        'No hay miembros compartidos entre Personas y Kids.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _crossDuplicates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final pair = _crossDuplicates[index];
        final name = pair['name'] as String;
        final person = pair['person'] as Map<String, dynamic>;
        final kid = pair['kid'] as Map<String, dynamic>;
        final bool isSynced = pair['isSynced'] as bool? ?? false;
        final classes = (kid['classes'] as List?)?.join(', ') ?? 'Sin clase';

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSynced
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSynced
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isSynced ? '✓ 👤👶' : '👤👶',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            isSynced
                                ? 'Vinculado en Personas y en Kids'
                                : 'Registrado en Personas y en Kids',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSynced
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              fontWeight: isSynced
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Text(
                          'Sincronizado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• En Personas: Tel: ${person['phone'] ?? 'N/A'}, Cumple: ${person['birthDay'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• En Kids: Clases: $classes, Cumple: ${kid['birthDay'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Botón Principal: Vincular y Sincronizar en ambos lados
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _linkAndSync(pair),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSynced
                          ? const Color(0xFF059669)
                          : const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    icon: Icon(
                      isSynced ? Icons.check_circle_rounded : Icons.sync_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isSynced
                          ? 'Volver a Sincronizar Datos'
                          : '🔗 Vincular y Sincronizar (Conservar en ambos)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Opciones secundarias si fuera un error
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _mergeCrossKeepKid(pair),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          'Mover solo a Kids',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _mergeCrossKeepAdult(pair),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          'Mover solo a Personas',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Tab 2: Duplicate People List ---
  Widget _buildPeopleDupsList() {
    if (_peopleDuplicates.isEmpty) {
      return _buildEmptyState(
        'No se encontraron personas repetidas en el listado general.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _peopleDuplicates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final cluster = _peopleDuplicates[index];
        final name = cluster.first['name'] as String;

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cluster.length} copias',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < cluster.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${i == 0 ? "👑 Principal" : "• Duplicado"}: ID ${cluster[i]['id']} (Tel: ${cluster[i]['phone'] ?? 'N/A'}, Cumple: ${cluster[i]['birthDay'] ?? 'N/A'})',
                      style: TextStyle(
                        fontSize: 12,
                        color: i == 0
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF64748B),
                        fontWeight:
                            i == 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _mergePeopleCluster(cluster),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.merge_type_rounded, size: 14),
                    label: const Text(
                      'Unificar en 1 solo registro',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Tab 3: Duplicate Kids List ---
  Widget _buildKidsDupsList() {
    if (_kidsDuplicates.isEmpty) {
      return _buildEmptyState(
        'No se encontraron niños repetidos en el listado de Kids.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _kidsDuplicates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final cluster = _kidsDuplicates[index];
        final name = cluster.first['name'] as String;

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cluster.length} copias',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < cluster.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${i == 0 ? "👑 Principal" : "• Duplicado"}: ID ${cluster[i]['id']} (Clases: ${(cluster[i]['classes'] as List?)?.join(', ') ?? 'N/A'})',
                      style: TextStyle(
                        fontSize: 12,
                        color: i == 0
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF64748B),
                        fontWeight:
                            i == 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _mergeKidsCluster(cluster),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.merge_type_rounded, size: 14),
                    label: const Text(
                      'Unificar en 1 solo niño',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
