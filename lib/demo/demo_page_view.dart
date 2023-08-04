import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/entities/order_update_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:task_unical/demo/demo_item_rebuild.dart';

import '../reorderable_grid_view.dart';


class DemoPageView extends StatefulWidget {
  const DemoPageView({Key? key}) : super(key: key);

  @override
  State<DemoPageView> createState() => _DemoPageViewState();
}

class _DemoPageViewState extends State<DemoPageView> {
  final widgets = List<Widget>.generate(10, (index) => Item(no: index));
  double scrollSpeedVariable = 5;
  var gridKey = GlobalKey();

  void add() {
    setState(() {
      widgets.add(Item(no: widgets.length));
    });
  }

  Widget _buildList(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            children: widgets.map((e) => e).toList(),
          ),
        ),
        const SizedBox(
          height: 100,
        )
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return ReorderableGridView.count(
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 3,
      childAspectRatio: 0.6,
      scrollSpeedController:
          (int timeInMilliSecond, double overSize, double itemSize) {
        if (timeInMilliSecond > 1500) {
          scrollSpeedVariable = 15;
        } else {
          scrollSpeedVariable = 5;
        }
        return scrollSpeedVariable;
      },
      // option
      onDragStart: (dragIndex) {
        log("onDragStart $dragIndex");
      },
      onReorder: (oldIndex, newIndex) {
        // print("reorder: $oldIndex -> $newIndex");
        setState(() {
          final element = widgets.removeAt(oldIndex);
          widgets.insert(newIndex, element);
        });
      },
      // option
      dragWidgetBuilder: (index, child) {
        return child;
      },
      header: [
        Card(
          child: InkWell(
            onTap: () {
              add();
            },
            child: const Center(child: Icon(Icons.add)),
          ),
        ),
      ],
      footer: [
        Card(
          child: InkWell(
            onTap: () {
              if (widgets.isNotEmpty) {
                setState(() {
                  widgets.removeLast();
                });
              }
            },
            child: const Center(child: Icon(Icons.delete)),
          ),
        ),
      ],
      // 0 < childAspectRatio <= 1.0
      children:
          widgets.map((e) => Container(key: ValueKey(e), child: e)).toList(),
    );
  }

  ReorderableBuilder _useFlutterReorderable() {
    return ReorderableBuilder(
      onReorder: (List<OrderUpdateEntity> orderUpdateEntities) {
        setState(() {
          for (final orderUpdateEntity in orderUpdateEntities) {
            final fruit = widgets.removeAt(orderUpdateEntity.oldIndex);
            widgets.insert(orderUpdateEntity.newIndex, fruit);
          }
        });
      },
      children: widgets
          .map((e) => Container(
                key: Key(e.hashCode.toString()),
                child: e,
              ))
          .toList(),
      builder: (children) => GridView(
          key: gridKey,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          children: children));
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: _buildGrid(context)),
        _buildList(context)
      ],
    );
  }

  Widget buildItem(int index) {
    return Card(
      key: ValueKey(index),
      child: Text(index.toString()),
    );
  }
}
