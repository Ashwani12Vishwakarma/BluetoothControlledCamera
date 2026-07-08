import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class TeleprompterController extends GetxController {
  RxString title = "".obs;
  RxString text = "".obs;
  RxBool isActive = false.obs;
  RxBool isPlaying = false.obs;

  ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;
  final double _scrollSpeed = 1.5; // Pixels per tick (50ms)

  void setScript(String newTitle, String newText) {
    title.value = newTitle;
    text.value = newText;
    isActive.value = true;
    isPlaying.value = false;
    _stopScrolling();
    
    // Reset scroll position
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void play() {
    if (!isActive.value) return;
    isPlaying.value = true;
    _startScrolling();
  }

  void pause() {
    isPlaying.value = false;
    _stopScrolling();
  }

  void clear() {
    isActive.value = false;
    isPlaying.value = false;
    title.value = "";
    text.value = "";
    _stopScrolling();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.offset;
        
        if (currentScroll < maxScroll) {
          scrollController.jumpTo(currentScroll + _scrollSpeed);
        } else {
          // Reached the end, stop automatically
          pause();
        }
      }
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
  }

  @override
  void onClose() {
    _scrollTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
