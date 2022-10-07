import "package:flutter/material.dart";
import '/ny_todo.dart';

class NyVy extends StatelessWidget {
  final Function addTodo;

  NyVy(this.addTodo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lägg till todo")),
      body: NyTodo(
        addTodo,
      ),
    );
  }
}
