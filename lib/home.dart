import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_db/main.dart';
import 'package:local_db/model/todo_model.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum TodoFilter { ALL, COMPLETED, INCOMPLETED }

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController detailController = TextEditingController();

  late Box<ToDoModel> todoBox;

  List popupMenuItems = ['All', 'Completed', 'Incompleted'];

  TodoFilter filter = TodoFilter.ALL;

  @override
  void initState() {
    todoBox = Hive.box<ToDoModel>(todoBoxName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local DB with Hive'),
        actions: [
          PopupMenuButton<String>(
              onSelected: (value) {
                if (value.compareTo(popupMenuItems[0]) == 0) {
                  setState(() {
                    filter = TodoFilter.ALL;
                  });
                } else if (value.compareTo(popupMenuItems[1]) == 0) {
                  setState(() {
                    filter = TodoFilter.COMPLETED;
                  });
                } else {
                  setState(() {
                    filter = TodoFilter.INCOMPLETED;
                  });
                }
              },
              itemBuilder: (context) => popupMenuItems
                  .map(
                    (options) => PopupMenuItem<String>(
                      child: Text(options),
                      value: options,
                    ),
                  )
                  .toList()),
        ],
      ),
      body: Container(
        child: ValueListenableBuilder(
            valueListenable: todoBox.listenable(),
            builder: (context, Box<ToDoModel> todos, _) {
              List<int> keys;

              if (filter == TodoFilter.ALL) {
                keys = todos.keys.cast<int>().toList();
              } else if (filter == TodoFilter.COMPLETED) {
                keys = todos.keys
                    .cast<int>()
                    .where((element) => todos.get(element)!.isCompleted!)
                    .toList();
              } else {
                keys = todos.keys
                    .cast<int>()
                    .where((element) => !todos.get(element)!.isCompleted!)
                    .toList();
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final int key = keys[index];
                      final ToDoModel? todoItem = todos.get(key);

                      return Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(todoItem!.title!),
                              subtitle: Text(todoItem.detail!),
                              leading: Text("$key"),
                              trailing: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Icon(
                                  Icons.check,
                                  color: todoItem.isCompleted!
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: ElevatedButton(
                                            child: Text('Mark as Completed'),
                                            onPressed: () {
                                              ToDoModel mTodo = ToDoModel(
                                                  title: todoItem.title,
                                                  detail: todoItem.detail,
                                                  isCompleted: true);
                                              todoBox.put(key, mTodo);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              titleController.text = todoItem.title ?? '';
                              detailController.text = todoItem.detail ?? '';
                              buildDialog(onPressed: (){
                                final String title = titleController.text;
                                final String detail = detailController.text;

                                ToDoModel todo = ToDoModel(
                                    title: title, detail: detail, isCompleted: false);
                                todoBox.put(key, todo);
                                Navigator.pop(context);
                                titleController.clear();
                                detailController.clear();
                              });
                            },
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(onPressed: (){
                            todoBox.delete(key);
                          }, icon: Icon(Icons.delete),),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: keys.length),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          buildDialog(
              onPressed: (){
            final String title = titleController.text;
            final String detail = detailController.text;

            ToDoModel todo = ToDoModel(
                title: title, detail: detail, isCompleted: false);
            todoBox.add(todo);
            Navigator.pop(context);
            titleController.clear();
            detailController.clear();
          });
        },
        tooltip: 'Dialog',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  buildDialog({
    required onPressed
}){
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          margin: EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Title'),
                controller: titleController,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(hintText: 'Detail'),
                controller: detailController,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  onPressed();
                },
                child: Text('Add Todo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
