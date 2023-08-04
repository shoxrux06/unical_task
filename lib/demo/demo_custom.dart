import 'package:flutter/material.dart';

import '../pages/reorderable_item.dart';
import '../pages/reorderable_wrapper_widget.dart';

class DemoCustom extends StatefulWidget {
  const DemoCustom({Key? key}) : super(key: key);

  @override
  State<DemoCustom> createState() => _DemoCustomState();
}

class _DemoCustomState extends State<DemoCustom> {
  final data = List<int>.generate(50, (index) => index);

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
            builder: (builder) => ReorderableWrapperWidget(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                      itemCount: data.length * 2,
                      itemBuilder: (context, index) {
                        if (index % 2 == 0) {
                          return const Card(
                            color: Colors.black12,
                            child: Text("Sticky"),
                          );
                        } else {
                          var realIndex = (index / 2).floor();
                          var itemData = data[realIndex];
                          return ReorderableItemView(
                              key: ValueKey(realIndex),
                              index: realIndex,
                              child: Card(
                                child: Text("R $itemData"),
                              ));
                        }
                      }),
                  onReorder: (dragIndex, dropIndex) {
                    setState(() {
                      var item = data.removeAt(dragIndex);
                      data.insert(dropIndex, item);
                    });
                  },
                ))
      ],
    );
  }
}
