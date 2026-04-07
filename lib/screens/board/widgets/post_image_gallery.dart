import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 게시글 본문 인라인 이미지 리스트
///
/// - 각 이미지를 [CachedNetworkImage]로 lazy load
/// - placeholder는 [Shimmer] skeleton
/// - 탭하면 [FullscreenImageViewer]로 swipe + pinch-zoom 제공
/// - Hero animation으로 본문 ↔ 풀스크린 부드럽게 전환
class PostImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final String heroTagPrefix;

  const PostImageGallery({
    required this.imageUrls,
    required this.heroTagPrefix,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < imageUrls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  pageBuilder: (_, __, ___) => FullscreenImageViewer(
                    imageUrls: imageUrls,
                    initialIndex: i,
                    heroTagPrefix: heroTagPrefix,
                  ),
                ),
              ),
              child: Hero(
                tag: '$heroTagPrefix-$i',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    placeholder: (_, __) => const _ShimmerBox(height: 200),
                    errorWidget: (_, __, ___) => const _ErrorBox(height: 200),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 풀스크린 이미지 뷰어 (PageView로 swipe, InteractiveViewer로 pinch-zoom)
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  const FullscreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
    super.key,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.imageUrls.length > 1
            ? Text('${_index + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: '${widget.heroTagPrefix}-$i',
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF252830) : const Color(0xFFEAEAEA),
      highlightColor: isDark ? const Color(0xFF34373F) : const Color(0xFFF5F5F5),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final double height;
  const _ErrorBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252830)
          : const Color(0xFFEAEAEA),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
    );
  }
}
