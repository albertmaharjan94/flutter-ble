import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:car2/MainPage.dart';
import 'package:flutter/material.dart';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'SelectBondedDevicePage.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(new ExampleApplication());
}

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        themeMode: ThemeMode.dark,
        home: MainPage());
  }
}
//
// class SocketBuffer extends StatefulWidget {
//   const SocketBuffer({Key? key}) : super(key: key);
//
//   @override
//   State<SocketBuffer> createState() => _SocketBufferState();
// }
//
// class StreamSocket {
//   final _socketResponse = StreamController<String>();
//
//   void Function(String) get addResponse => _socketResponse.sink.add;
//
//   Stream<String> get getResponse => _socketResponse.stream;
//
//   void dispose() {
//     _socketResponse.close();
//   }
// }
//
// class _SocketBufferState extends State<SocketBuffer> {
//   Socket? socket;
//   bool socket_connected = false;
//   String response = "";
//   Future<void> create_socket(String ip, int port) async {
//     if (socket_connected == false) {
//       try {
//         socket = await Socket.connect(ip, port);
//         socket!.listen(_onSocketReceived);
//       } on Exception {
//         print("Exception -> socket");
//       }
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     create_socket("172.21.0.92", 65432);
//   }
//
//   List<String> socket_buffers = List<String>.filled(20, "", growable: true);
//
//   List<String> socket_current_val = [];
//
//   void _onSocketReceived(Uint8List data) {
//     // Allocate buffer for parsed data
//     int backspacesCounter = 0;
//     for (var byte in data) {
//       if (byte == 8 || byte == 127) {
//         backspacesCounter++;
//       }
//     }
//     Uint8List buffer = Uint8List(data.length - backspacesCounter);
//     int bufferIndex = buffer.length;
//
//     // Apply backspace control character
//     backspacesCounter = 0;
//     for (int i = data.length - 1; i >= 0; i--) {
//       if (data[i] == 8 || data[i] == 127) {
//         backspacesCounter++;
//       } else {
//         if (backspacesCounter > 0) {
//           backspacesCounter--;
//         } else {
//           buffer[--bufferIndex] = data[i];
//         }
//       }
//     }
//
//     // Create message if there is new line character
//     String dataString = String.fromCharCodes(buffer);
//     List<String> filteredLines = dataString
//         .split("\n")
//         .where((line) => line.startsWith("#"))
//         .toList();
//     if (filteredLines.isNotEmpty) {
//       setState(() {
//         socket_buffers.insert(0, filteredLines[0]);
//         socket_current_val = socket_buffers[0].substring(1).split(",");
//       });
//       socket_buffers.removeLast();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print(socket_current_val[1].toString());
//     if (socket == null) {
//       return Container();
//     }
//     return SafeArea(
//         child: Scaffold(
//       body: Container(),
//       // body: StreamBuilder(
//       //   stream: socket,
//       //   builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
//       //     if(snapshot.data!=null){
//       //       String data = String.fromCharCodes(snapshot.data);
//       //       List<dynamic> spl = (data.split("#"));
//       //       print(spl[0]);
//       //     }
//       //     return Container();
//       //   },
//       // ),
//     ));
//   }
// }
