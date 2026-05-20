import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_widgets.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Future<void> Function(String path) onSave;

  const ImageViewer({
    super.key,
    required this.imagePaths,
    required this.onSave,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = ValueNotifier(widget.initialIndex);

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? widget.initialIndex;
      if (_currentIndex.value != page) {
        _currentIndex.value = page;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 10) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: widget.imagePaths.length,
              pageController: _pageController,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.imagePaths[index])),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: widget.imagePaths[index],
                  ),
                );
              },
              loadingBuilder: (context, progress) => Center(
                child: CircularProgressIndicator(
                  value: progress == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1),
                  color: primary,
                ),
              ),
            ),
            _backButton(context),
            _downloadButton(),
            // _pageIndicator(),
          ],
        ),
      ),
    );
  }

  Positioned _backButton(BuildContext context) {
    return Positioned(
      top: 30,
      left: 5,
      child: IconButton(
        iconSize: 30,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _downloadButton() {
    return Positioned(
      top: 30,
      right: 8,
      child: ValueListenableBuilder<int>(
        valueListenable: _currentIndex,
        builder: (context, index, _) {
          return IconButton(
            iconSize: 26,
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => widget.onSave(widget.imagePaths[index]),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _CurrentIndexIndicator extends StatelessWidget {
  final ValueNotifier<int> currentIndex;
  final int totalImages;

  const _CurrentIndexIndicator({
    required this.currentIndex,
    required this.totalImages,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentIndex,
      builder: (context, index, _) {
        return Text(
          '${index + 1} / $totalImages',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        );
      },
    );
  }
}
