import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class PopupNoticeManager extends StatefulWidget {
  final Color cardColor;
  const PopupNoticeManager({required this.cardColor});

  @override
  State<PopupNoticeManager> createState() => PopupNoticeManagerState();
}

class PopupNoticeManagerState extends State<PopupNoticeManager> {
  bool _active = false;
  String _type = 'notice';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _dismissible = true;
  bool _loading = true;
  bool _saving = false;

  static const _types = ['emergency', 'notice', 'event'];
  static const _typeLabels = {'emergency': '긴급', 'notice': '공지', 'event': '이벤트'};
  static const _typeColors = {'emergency': Colors.red, 'notice': Color(0xFF3F72AF), 'event': Color(0xFF4CAF50)};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('app_config').doc('popup').get();
    if (doc.exists) {
      final d = doc.data()!;
      if (!mounted) return;
      setState(() {
        _active = d['active'] ?? false;
        _type = d['type'] ?? 'notice';
        _titleController.text = d['title'] ?? '';
        _contentController.text = d['content'] ?? '';
        _startController.text = d['startDate'] ?? '';
        _endController.text = d['endDate'] ?? '';
        _dismissible = d['dismissible'] ?? true;
      });
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('app_config').doc('popup').set({
      'active': _active,
      'type': _type,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'startDate': _startController.text.trim(),
      'endDate': _endController.text.trim(),
      'dismissible': _dismissible,
    });
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);

    if (_loading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('팝업 활성화', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Switch.adaptive(
                value: _active,
                activeColor: Colors.red,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: _types.map((t) {
              final selected = _type == t;
              final color = _typeColors[t] ?? AppColors.theme.primaryColor;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : AppColors.theme.darkGreyColor),
                    ),
                    child: Text(_typeLabels[t] ?? t, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.theme.darkGreyColor)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '제목', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
              filled: true, fillColor: fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '내용', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
              filled: true, fillColor: fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => _pickDate(_startController),
                child: AbsorbPointer(child: TextField(
                  controller: _startController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '시작일', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    filled: true, fillColor: fillColor, prefixIcon: Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => _pickDate(_endController),
                child: AbsorbPointer(child: TextField(
                  controller: _endController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '종료일', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    filled: true, fillColor: fillColor, prefixIcon: Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )),
              )),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text('"오늘 안 보기" 허용', style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
              const Spacer(),
              Switch.adaptive(value: _dismissible, activeColor: AppColors.theme.primaryColor,
                onChanged: (v) => setState(() => _dismissible = v)),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _typeColors[_type] ?? Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
