import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class RecentPosts extends StatelessWidget {
  const RecentPosts({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: _combinedStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) return const SizedBox.shrink();

        final pinnedDocs = snapshot.data![0].docs;
        final recentDocs = snapshot.data![1].docs;

        QueryDocumentSnapshot<Map<String, dynamic>>? pinnedPost;
        if (pinnedDocs.isNotEmpty) {
          pinnedPost = pinnedDocs.first;
        }

        final pinnedIds = pinnedDocs.map((d) => d.id).toSet();
        final nonPinned = recentDocs.where((d) => !pinnedIds.contains(d.id)).take(2).toList();

        final displayDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (pinnedPost != null) displayDocs.add(pinnedPost);
        displayDocs.addAll(nonPinned);

        if (displayDocs.isEmpty) return const SizedBox.shrink();

        return Column(
          children: displayDocs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? '';
            final category = data['category'] ?? '';
            final commentCount = data['commentCount'] ?? 0;
            final isPinned = data['isPinned'] == true;

            return GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(postId: doc.id))),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    if (isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin, size: 12, color: Colors.red),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: BoardCategories.color(category).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(category,
                        style: TextStyle(fontSize: Responsive.sp(context, 10), fontWeight: FontWeight.w600, color: BoardCategories.color(category))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                        style: TextStyle(fontSize: Responsive.sp(context, 13), color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (commentCount > 0) ...[
                      const SizedBox(width: 6),
                      Text('[$commentCount]',
                        style: TextStyle(fontSize: Responsive.sp(context, 11), color: AppColors.theme.primaryColor)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Stream<List<QuerySnapshot<Map<String, dynamic>>>> _combinedStream() {
    final pinnedStream = FirebaseFirestore.instance
        .collection('posts')
        .where('isPinned', isEqualTo: true)
        .orderBy('pinnedAt', descending: true)
        .limit(1)
        .snapshots();

    final recentStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    return pinnedStream.asyncExpand((pinnedSnap) {
      return recentStream.map((recentSnap) => [pinnedSnap, recentSnap]);
    });
  }
}
