import 'package:flutter/material.dart';
import 'package:flutter_chat_socket/src/pages/home/home_page.dart';
import 'package:flutter_chat_socket/src/pages/home/messages.dart';

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Messages();
  }
}
