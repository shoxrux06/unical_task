import 'package:flutter/material.dart';
import 'demo/demo_custom.dart';
import 'demo/demo_item_rebuild.dart';
import 'demo/demo_page_view.dart';

void main() {
  runApp(MyApp());
}

typedef Next = Widget Function();

class Item {
  String name = "";
  Next next;

  Item(this.name, this.next);
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final items = [
    Item("Custom", () => const DemoCustom()),
    Item("Item Rebuild", () => const DemoItemRebuild()),
    Item("PageView", () => const DemoPageView()),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: const Text("Demo App"),
            ),
            body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: Text(item.name),
                                  ),
                                  body: item.next(),
                                )));
                      },
                      child: ListTile(title: Text(item.name)));
                })));
  }
}


