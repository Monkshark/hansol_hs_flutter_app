import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class ReportsTab extends StatefulWidget {
  @override
  State<ReportsTab> createState() => ReportsTabState();
}

class ReportsTabState extends State<ReportsTab> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetch() =>
      FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).get();

  void _refresh() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('신고가 없습니다',
              style: TextStyle(color: AppColors.theme.darkGreyColor))),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final reason = data['reason'] ?? '';
            final postId = data['postId'] ?? '';
            final time = (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(reason, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                      ),
                      const Spacer(),
                      if (time != null)
                        Text('${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))),
                          child: Text('글 보기', style: TextStyle(
                            fontSize: 13, color: AppColors.theme.primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          try {
                            final comments = await FirebaseFirestore.instance
                                .collection('posts').doc(postId).collection('comments').get();
                            for (var c in comments.docs) await c.reference.delete();
                            await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                          } catch (_) {}
                          await docs[index].reference.delete();
                          _refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('글 삭제', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () { docs[index].reference.delete(); _refresh(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.theme.darkGreyColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('무시', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
