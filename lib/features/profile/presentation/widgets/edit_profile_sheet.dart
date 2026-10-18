import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../matchmaking/domain/court.dart';
import '../../domain/player_profile.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.loadCourts,
    required this.onSave,
  });

  final PlayerProfile profile;
  final Future<List<Court>> Function() loadCourts;
  final Future<void> Function(String displayName, String? homeCourtId) onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  String? _selectedCourtId;
  List<Court> _courts = const [];
  bool _loadingCourts = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _selectedCourtId = widget.profile.homeCourtId;
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    try {
      final list = await widget.loadCourts();
      if (mounted) {
        setState(() {
          _courts = list;
          _loadingCourts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCourts = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tên hiển thị không được để trống.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(name, _selectedCourtId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Không thể lưu thay đổi. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHỈNH SỬA HỒ SƠ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                          letterSpacing: 1.0,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.loss.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.loss),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              Text('Tên hiển thị', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                maxLength: 40,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên của bạn...',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sân nhà / Sân quen thuộc (Home Court)', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              if (_loadingCourts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: _selectedCourtId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Chưa chọn sân quen (Tự do)'),
                    ),
                    ..._courts.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(
                          c.distanceKm != null ? '${c.name} (${c.distanceKm!.toStringAsFixed(1)} km)' : c.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCourtId = val),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('LƯU THAY ĐỔI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
