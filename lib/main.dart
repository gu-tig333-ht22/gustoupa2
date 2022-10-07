import "package:flutter/material.dart";

import "/nyVy.dart";
import "modell.dart";
import "ny_todo.dart";
import "todo_listan.dart";
import "package:http/http.dart" as http;
import "dart:convert";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          toolbarTextStyle: TextStyle(fontSize: 4),
          titleTextStyle: TextStyle(fontSize: 19),
        ),
      ),
      title: "It Högskolan Flutter App",
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isLoading = false;
  List<Modellen> helaTodoListan = [];

  var filterBy = "alla";

  void startTodo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => GestureDetector(
        child: NyTodo(adderaNyTodo),
      ),
    );
  }

  void adderaNyTodo(Modellen modellen) async {
    var response = await http
        .post(
      Uri.parse(
          "https://nytt-objekt-flutter-default-rtdb.firebaseio.com/todoTask.json"),
      body: jsonEncode(
        {
          "todo": modellen.titel,
          "kommentar": modellen.kommentar,
          "bool": modellen.favorite
        },
      ),
    )
        .then((response) {
      final newToDo = Modellen(
          titel: modellen.titel,
          kommentar: modellen.kommentar,
          id: json.decode(response.body)["name"] as String,
          favorite: modellen.favorite);

      setState(() {
        helaTodoListan.add(newToDo);
      });
    });
  }

  void showAlla() {
    setState(() {
      filterBy = "alla";
      filtrera(helaTodoListan, filterBy) as List<Modellen>;
    });
  }

  void showDone() {
    setState(() {
      filterBy = "done";
      filtrera(helaTodoListan, filterBy) as List<Modellen>;
    });
  }

  void showUndone() {
    setState(() {
      filterBy = "undone";
      filtrera(helaTodoListan, filterBy) as List<Modellen>;
    });
  }

  List<Modellen>? filtrera(List list, filterBy) {
    if (filterBy == "alla") {
      return list as List<Modellen>;
    }
    if (filterBy == "done") {
      return helaTodoListan.where((todo) => todo.favorite == true).toList();
    }
    if (filterBy == "undone") {
      return helaTodoListan.where((todo) => todo.favorite == false).toList();
    }
    return null;
  }

  void delete(String id) {
    setState(() {
      final url = Uri.parse(
          "https://nytt-objekt-flutter-default-rtdb.firebaseio.com/todoTask/$id.json");
      http.delete(url);
      helaTodoListan.removeWhere((element) => element.id == id);
    });
  }

  void done(String id) {
    setState(() {
      final existingIndex =
          helaTodoListan.indexWhere((element) => element.id == id);
      if (helaTodoListan[existingIndex].favorite == true) {
        helaTodoListan[existingIndex].favorite = false;
        final url = Uri.parse(
            "https://nytt-objekt-flutter-default-rtdb.firebaseio.com/todoTask/$id.json");
        http.put(url,
            body: jsonEncode({
              "todo": helaTodoListan[existingIndex].titel,
              "kommentar": helaTodoListan[existingIndex].kommentar,
              "id": id,
              "favorite": false
            }));
      } else {
        helaTodoListan[existingIndex].favorite = true;
        final url = Uri.parse(
            "https://nytt-objekt-flutter-default-rtdb.firebaseio.com/todoTask/$id.json");
        http.put(url,
            body: jsonEncode({
              "todo": helaTodoListan[existingIndex].titel,
              "kommentar": helaTodoListan[existingIndex].kommentar,
              "id": id,
              "favorite": true
            }));
      }
    });
  }

  bool isTodoDone(String id) {
    final existingIndex =
        helaTodoListan.indexWhere((element) => element.id == id);
    return helaTodoListan[existingIndex].favorite == true;
  }

  void _doStuff() async {
    var result = await fetchInternetStuff();
  }

  Future<Object?> fetchInternetStuff() async {
    setState(() {
      isLoading = true;
    });
    http.Response response = await http.get(
      Uri.parse(
          "https://nytt-objekt-flutter-default-rtdb.firebaseio.com/todoTask.json"),
    );

    var jsonData = response.body;
    var obj = jsonDecode(jsonData);
    if (obj == null) {
      setState(() {
        isLoading = false;
      });
    } else {
      var tom = [];
      setState(() {
        obj.forEach((prodId, prodData) {
          tom.add(
            Modellen(
                id: prodId,
                titel: prodData["todo"],
                kommentar: prodData["kommentar"],
                favorite: prodData["favorite"]),
          );
        });

        tom.forEach(
          (element) {
            var element_modellen = element as Modellen;
            if (helaTodoListan.any((el) => el.id == element_modellen.id)) {
              return null;
            } else {
              helaTodoListan.add(element_modellen);
            }
          },
        );
        ;
      });

      setState(() {
        isLoading = false;
      });

      return tom;
    }
  }

  @override
  void initState() {
    _doStuff();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: Icon(Icons.check_box), onPressed: showDone),
          IconButton(
            icon: Icon(Icons.check_box_outline_blank),
            onPressed: showUndone,
          ),
          IconButton(
            icon: Icon(Icons.all_inclusive),
            onPressed: showAlla,
          )
        ],
        title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 0),
              ),
              Text("To do app"),
            ]),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : helaTodoListan.isEmpty
              ? Center(
                  child: Text(
                    "Tom",
                    style: TextStyle(fontSize: 40),
                  ),
                )
              : TodoList(filtrera(helaTodoListan, filterBy) as List<Modellen>,
                  delete, done, isTodoDone),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NyVy(adderaNyTodo),
              ),
            );
          }),
    );
  }
}
