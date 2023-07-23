import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  List<String> buffers = List<String>.filled(20, "", growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  List<String> currentVal = [];
  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
                  ? Text('Live chat with ' + serverName)
                  : Text('Chat log with ' + serverName))),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ...buffers.map((message) {
                      return Row(
                        children: <Widget>[
                          Container(
                            child: Text(
                                (text) {
                                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                                }(message.trim()),
                                style: TextStyle(color: Colors.black)),
                            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                ...List.generate(
                  currentVal.length,
                  (index) => Switch(
                      // thumb color (round icon)
                      activeColor: Colors.amber,
                      activeTrackColor: Colors.cyan,
                      inactiveThumbColor: Colors.blueGrey.shade600,
                      inactiveTrackColor: Colors.grey.shade400,
                      splashRadius: 50.0,
                      // boolean variable value
                      value: currentVal[index] == "0",
                      // changes the state of the switch
                      onChanged: (value) {
                        String message = "#";
                        for (int i = 0; i < currentVal.length; i++) {
                          if (i == index) {
                            message += currentVal[index] == "0" ? "1" : "0";
                          } else {
                            message += currentVal[i];
                          }
                          if (i != currentVal.length - 1) {
                            message += ",";
                          }
                        }
                        print(currentVal);
                        _sendMessage(message);
                      }),
                ),
                // Switch(
                //   // thumb color (round icon)
                //     activeColor: Colors.amber,
                //     activeTrackColor: Colors.cyan,
                //     inactiveThumbColor: Colors.blueGrey.shade600,
                //     inactiveTrackColor: Colors.grey.shade400,
                //     splashRadius: 50.0,
                //     // boolean variable value
                //     value: currentVal[0] == "0",
                //     // changes the state of the switch
                //     onChanged: (value) {
                //       _sendMessage("#${currentVal[0] == "0" ? "1" : "0"},0,0,0,0,0,0,0");
                //     }),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    List<String> filteredLines = dataString
        .split("\n")
        .where((line) => line.startsWith("#") && line.split(",").length == 8)
        .toList();
    if (filteredLines.isNotEmpty) {
      setState(() {
        buffers.insert(0, filteredLines[0]);
        currentVal = buffers[0].substring(1).split(",");
      });
      buffers.removeLast();
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    print(text);
    if (text.isNotEmpty) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
        await connection!.output.allSent;
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
