import 'dart:typed_data';
import 'dart:ui' as ui show Image, ImageByteFormat;
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:task_unical/pages/reorderable_item.dart';
import 'package:task_unical/pages/util.dart';


import '../reorderable_grid_view.dart';
import 'drag_info.dart';

abstract class ReorderableChildPosDelegate {
  const ReorderableChildPosDelegate();

  Offset getPos(int index, Map<int, ReorderableItemViewState> items,
      BuildContext context);
}

mixin ReorderableGridWidgetMixin on StatefulWidget {
  ReorderCallback get onReorder;
  DragWidgetBuilderV2? get dragWidgetBuilder;
  ScrollSpeedController? get scrollSpeedController;
  PlaceholderBuilder? get placeholderBuilder;
  OnDragStart? get onDragStart;
  OnDragUpdate? get onDragUpdate;

  Widget get child;
  Duration? get dragStartDelay;
  bool? get dragEnabled;

  bool? get isSliver;

  bool? get restrictDragScope;
}

mixin ReorderableGridStateMixin<T extends ReorderableGridWidgetMixin>
on State<T>, TickerProviderStateMixin<T> {
  MultiDragGestureRecognizer? _recognizer;
  GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  Duration get dragStartDelay => widget.dragStartDelay ?? kLongPressTimeout;
  bool get dragEnabled => widget.dragEnabled ?? true;
  void startDragRecognizer(int index, PointerDownEvent event,
      MultiDragGestureRecognizer recognizer) {
    setState(() {
      if (_dragIndex != null) {
        _dragReset();
      }

      _dragIndex = index;
      _recognizer = recognizer
        ..onStart = _onDragStart
        ..addPointer(event);
    });
  }

  int? _dragIndex;

  int? _dropIndex;

  int get dropIndex => _dropIndex ?? -1;

  PlaceholderBuilder? get placeholderBuilder => widget.placeholderBuilder;

  OverlayState? getOverlay() {
    return overlayKey.currentState;
  }

  bool containsByIndex(int index) {
    return __items.containsKey(index);
  }

  Offset getPosByOffset(int index, int dIndex) {
    var keys = __items.keys.toList();
    var keyIndex = keys.indexOf(index);
    keyIndex = keyIndex + dIndex;
    if (keyIndex < 0) {
      keyIndex = 0;
    }
    if (keyIndex > keys.length - 1) {
      keyIndex = keys.length - 1;
    }

    return getPosByIndex(keys[keyIndex], safe: true);
  }

  Offset getPosByIndex(int index, {bool safe = true}) {
    if (safe) {
      if (index < 0) {
        index = 0;
      }
    }

    if (index < 0) {
      return Offset.zero;
    }

    var child = __items[index];

    var thisRenderObject = context.findRenderObject();
    // RenderSliverGrid

    if (thisRenderObject is RenderSliverGrid) {
      var renderObject = thisRenderObject;

      final SliverConstraints constraints = renderObject.constraints;
      final SliverGridLayout layout =
      renderObject.gridDelegate.getLayout(constraints);

      final fixedIndex = child!.indexInAll?? child.index;
      final SliverGridGeometry gridGeometry =
      layout.getGeometryForChildIndex(fixedIndex);
      final rst =
      Offset(gridGeometry.crossAxisOffset, gridGeometry.scrollOffset);
      return rst;
    }

    var renderObject = child?.context.findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }
    RenderBox box = renderObject as RenderBox;

    var parentRenderObject = context.findRenderObject() as RenderBox;
    final pos =
    parentRenderObject.globalToLocal(box.localToGlobal(Offset.zero));
    return pos;
  }

  int _calcDropIndex(int defaultIndex) {
    if (_dragInfo == null) {
      return defaultIndex;
    }

    for (var item in __items.values) {
      RenderBox box = item.context.findRenderObject() as RenderBox;
      Offset pos = box.globalToLocal(_dragInfo!.getCenterInGlobal());
      if (pos.dx > 0 &&
          pos.dy > 0 &&
          pos.dx < box.size.width &&
          pos.dy < box.size.height) {
        return item.index;
      }
    }
    return defaultIndex;
  }

  Offset getOffsetInDrag(int index) {
    if (_dragInfo == null || _dropIndex == null || _dragIndex == _dropIndex) {
      return Offset.zero;
    }

    bool inDragRange = false;
    bool isMoveLeft = _dropIndex! > _dragIndex!;

    int minPos = min(_dragIndex!, _dropIndex!);
    int maxPos = max(_dragIndex!, _dropIndex!);

    if (index >= minPos && index <= maxPos) {
      inDragRange = true;
    }

    if (!inDragRange) {
      return Offset.zero;
    } else {
      if (isMoveLeft) {
        if (!containsByIndex(index - 1) || !containsByIndex(index)) {
          return Offset.zero;
        }
        return getPosByIndex(index - 1) - getPosByIndex(index);
      } else {
        if (!containsByIndex(index + 1) || !containsByIndex(index)) {
          return Offset.zero;
        }
        return getPosByIndex(index + 1) - getPosByIndex(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSliver?? false || !(widget.restrictDragScope?? false)) {
      return widget.child;
    }
    return Stack(children: [
      widget.child,
      Overlay(key: overlayKey,)
    ]);
  }

  Drag _onDragStart(Offset position) {
    debug("_onDragStart: $position, __dragIndex: $_dragIndex");
    assert(_dragInfo == null);
    widget.onDragStart?.call(_dragIndex!);

    final ReorderableItemViewState item = __items[_dragIndex!]!;

    _dropIndex = _dragIndex;

    _dragInfo = DragInfo(
      item: item,
      tickerProvider: this,
      overlay: getOverlay(),
      context: context,
      dragWidgetBuilder: widget.dragWidgetBuilder,
      scrollSpeedController: widget.scrollSpeedController,
      onStart: _onDragStart,
      dragPosition: position,
      onUpdate: _onDragUpdate,
      onCancel: _onDragCancel,
      onEnd: _onDragEnd,
      readyCallback: () {
        item.dragging = true;
        item.rebuild();
        updateDragTarget();
      },
    );
    ;
    _startDrag(item);

    return _dragInfo!;
  }

  void _startDrag(ReorderableItemViewState item) async {
    if (_dragInfo == null) {
      return;
    }
    if (widget.dragWidgetBuilder?.isScreenshotDragWidget?? false) {
      ui.Image? screenshot = await takeScreenShot(item);
      ByteData? byteData = await screenshot?.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        _dragInfo?.startDrag(MemoryImage(byteData.buffer.asUint8List()));
      }
    } else {
      _dragInfo?.startDrag(null);
    }
  }

  _onDragUpdate(DragInfo item, Offset position, Offset delta) {
    widget.onDragUpdate?.call(_dragIndex!, position, delta);
    updateDragTarget();
  }

  _onDragCancel(DragInfo item) {
    _dragReset();
    setState(() {});
  }

  _onDragEnd(DragInfo item) {
    widget.onReorder(_dragIndex!, _dropIndex!);
    _dragReset();
  }

  _dragReset() {
    if (_dragIndex != null) {
      if (__items.containsKey(_dragIndex!)) {
        final ReorderableItemViewState item = __items[_dragIndex!]!;
        item.dragging = false;
        item.rebuild();
      }

      _dragIndex = null;
      _dropIndex = null;

      for (var item in __items.values) {
        item.resetGap();
      }
    }

    _recognizer?.dispose();
    _recognizer = null;

    _dragInfo?.dispose();
    _dragInfo = null;
  }

  static ReorderableGridStateMixin of(BuildContext context) {
    return context.findAncestorStateOfType<ReorderableGridStateMixin>()!;
  }

  void reorder(int startIndex, int endIndex) {
    setState(() {
      if (startIndex != endIndex) widget.onReorder(startIndex, endIndex);
    });
  }

  final Map<int, ReorderableItemViewState> __items =
  <int, ReorderableItemViewState>{};

  DragInfo? _dragInfo;

  void registerItem(ReorderableItemViewState item) {
    __items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.rebuild();
    }
  }

  void unRegisterItem(int index, ReorderableItemViewState item) {
    var current = __items[index];
    if (current == item) {
      __items.remove(index);
    }
  }

  Future<void> updateDragTarget() async {
    int newTargetIndex = _calcDropIndex(_dropIndex!);
    if (newTargetIndex != _dropIndex) {
      _dropIndex = newTargetIndex;
      for (var item in __items.values) {
        item.updateForGap(_dropIndex!);
      }
    }
  }
}
