import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/board/widgets/post_card.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';

class BoardSearchBody extends StatelessWidget {
  final String searchQuery;
  final bool searchLoading;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> searchResults;
  final List<String> searchHistory;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCommitHistory;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearAllHistory;
  final Future<void> Function(String) onRunSearch;
  final VoidCallback onPostReturned;

  const BoardSearchBody({
    required this.searchQuery,
    required this.searchLoading,
    required this.searchResults,
    required this.searchHistory,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCommitHistory,
    required this.onRemoveHistory,
    required this.onClearAllHistory,
    required this.onRunSearch,
    required this.onPostReturned,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isEmpty) {
      if (searchHistory.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, size: 40, color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.board_searchEmptyQuery,
                style: TextStyle(color: AppColors.theme.darkGreyColor)),
          ]),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AppLocalizations.of(context)!.board_recentSearches,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.theme.darkGreyColor)),
                const Spacer(),
                TextButton(
                  onPressed: onClearAllHistory,
                  child: Text(AppLocalizations.of(context)!.board_clearAllSearches,
                      style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: searchHistory
                  .map((q) => InputChip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          searchController.text = q;
                          searchController.selection = TextSelection.fromPosition(
                              TextPosition(offset: q.length));
                          onSearchChanged(q);
                        },
                        onDeleted: () => onRemoveHistory(q),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 40, color: AppColors.theme.darkGreyColor),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.board_searchNoResults,
              style: TextStyle(color: AppColors.theme.darkGreyColor)),
        ]),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 80),
      itemCount: searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return PostCard(
          doc: searchResults[index],
          onTap: () async {
            onCommitHistory(searchQuery);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: searchResults[index].id),
              ),
            );
            onPostReturned();
          },
        );
      },
    );
  }
}
