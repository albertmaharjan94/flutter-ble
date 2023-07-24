import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'MainPage.dart';

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
    return MaterialApp(home: MainPage());
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
//   StreamSocket streamSocket = StreamSocket();
//
//   late Socket socket;
//
//   bool connected = false;
//   String b64 = "";
//   Future<void> create_socket(String ip, int port) async {
//     if (connected == false) {
//       try {
//         socket = await Socket.connect(ip, port);
//         // print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
//         socket.listen((Uint8List data) async {
//
//           await Future.delayed(Duration(seconds: 1));
//           setState(() {
//             b64 = (String.fromCharCodes(data));
//           });
//
//         }, onError: (error) {
//           print(error);
//           // _destroy(ip, port);
//           socket.close();
//           create_socket(ip, port);
//           connected = false;
//         }, onDone: () {
//           socket.close();
//           create_socket(ip, port);
//           connected = false;
//         });
//       } on Exception {
//         print("Exception -> socket");
//       }
//     }
//   }
//
// //STEP2: Add this function in main function in main.dart file and add incoming data to the stream
//   Future<void> connectAndListen() async {
//     print("Connecting");
//     final wsUrl = Uri.parse('ws://192.168.42.143:65432/');
//     final channel = WebSocketChannel.connect(wsUrl);
//
//     await channel.ready;
//
//     channel.stream.listen((message) {
//       channel.sink.add('received!');
//       channel.sink.close(status.goingAway);
//     });
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       create_socket("192.168.42.143", 65432);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (socket == null) {
//       return Container();
//     }
//     return SafeArea(
//       child: Scaffold(
//           // body: StreamBuilder(builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  },)
//           body: StreamBuilder(
//               stream: socket.asBroadcastStream(),
//               builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
//                 print(snapshot.data);
//                 return Container(
//                   child: Text("")
//                 );
//               })
//       ),
//     );
//   }
// }
