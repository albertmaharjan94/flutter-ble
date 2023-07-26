import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'dart:math' as math;

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
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(27.706077808805556, 85.33040797869828),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  void initState() {
    initializeDateFormatting();
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

    create_socket("192.168.42.224", 65432);
  }

  Socket? socket;
  bool socket_connected = false;
  String response = "";
  Future<void> create_socket(String ip, int port) async {
    if (socket_connected == false) {
      try {
        socket = await Socket.connect(ip, port);
        socket!.listen(_onSocketReceived);
      } catch(e){
        print(e);
        print("Exception -> socket");
      }
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      socket?.destroy();

      socket_connected = false;
      socket = null;
      connection = null;
    }

    super.dispose();
  }

  int idx = 0;
  List<String> currentVal = [];

  List<String> socket_buffers = List<String>.filled(20, "", growable: true);

  List<String> socket_current_val = [];

  void _onSocketReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    for (var byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
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
    List<String> filteredLines =
        dataString.split("\n").where((line) => line.startsWith("#")).toList();
    if (filteredLines.isNotEmpty) {
      setState(() {
        socket_buffers.insert(0, filteredLines[0]);
        socket_current_val = socket_buffers[0].substring(1).split(",");
      });
      socket_buffers.removeLast();
    }
  }

  FlutterTts flutterTts = FlutterTts();
  FlutterTts flutterTtsSk = FlutterTts();
  bool playing = false;
  Future _speak(String text) async {
    print(playing);
    if (playing == false) {
      setState(() {
        playing = true;
      });
      try{

        var result = await flutterTts.speak(text);
        await flutterTts.awaitSpeakCompletion(true);
      }catch(e){
        print(e);
      }
    }
    setState(() {
      playing = false;
    });
  }

  int indicator = 0;
  int light = 0;

  @override
  Widget build(BuildContext context) {
    var now_date = DateTime.now();
    var format = DateFormat('MMMMd');
    var dateString = format.format(now_date);
    var timeFormat = DateFormat('jm');
    var timeString = timeFormat.format(now_date);
    final serverName = widget.server.name ?? "Unknown";

    Color background = Color(0XFF0a0e19);
    // ff0800
    if (!playing && socket_current_val.isNotEmpty && socket_current_val[3].trim() == "True") {
      _speak("Please look straight");
    }

    if (!playing &&  socket_current_val.isNotEmpty && socket_current_val[1].trim() == "True") {
      _speak("Please wake up");

    }
    return Scaffold(
      backgroundColor: now_date.second % 2 == 0 &&
              (socket_current_val.isNotEmpty && socket_current_val[3].trim() == "True")
          // || indicator == 3
          ? Color(0XFFff0800)
          : Color(0XFF0a0e19),
      // appBar: AppBar(
      //     title: (isConnecting
      //         ? Text('Connecting chat to ' + serverName + '...')
      //         : isConnected
      //             ? Text('Live chat with ' + serverName)
      //             : Text('Chat log with ' + serverName))),
      drawer: Drawer(
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(10),
            child: isConnected ? buildDrawer() : Container(),
          ),
        ),
      ),
      body: SafeArea(
        child: isConnecting
            ? Text('Connecting')
            : isConnected && currentVal.isNotEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Hello",
                            style: TextStyle(
                                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600),
                          )),
                      GestureDetector(
                        onVerticalDragEnd: (DragEndDetails details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! > 0) {
                              print("Swipe down");

                              // User swiped Left
                            } else if (details.primaryVelocity! < 0) {
                              // User swiped Right
                              setState(() {
                                indicator = 0;
                              });
                            }
                          }
                        },
                        onHorizontalDragEnd: (DragEndDetails details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! > 0) {
                              print("Swipe left");
                              setState(() {
                                indicator = 2;
                              });
                              // User swiped Left
                            } else if (details.primaryVelocity! < 0) {
                              // User swiped Right
                              setState(() {
                                indicator = 1;
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: Container(
                            height: 420,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.asset(
                                    "assets/54-544278_car-png-top-transparent-car-top-car-top.png",
                                    height: double.infinity,
                                  ),
                                ),
                                if (indicator == 1)
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Lottie.asset(
                                        'assets/swipe.json',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.fill,
                                      )),

                                if (indicator == 2)
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(math.pi),
                                        child: Lottie.asset(
                                          'assets/swipe.json',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.fill,
                                        ),
                                      )),
                                // Align(
                                //   alignment: Alignment.topRight,
                                //   child: Ink(
                                //     decoration: ShapeDecoration(
                                //       color: Colors.white.withOpacity(0.5),
                                //       shape: CircleBorder(),
                                //     ),
                                //     child: IconButton(
                                //         onPressed: () {},
                                //         iconSize: 50,
                                //         icon: Icon(
                                //           Icons.lightbulb_sharp,
                                //           color: Colors.yellow,
                                //         )),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              timeString,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              dateString,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_queue_outlined,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  currentVal[10] + " °c",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                bool active = light == 1;
                                return Ink(
                                  decoration: ShapeDecoration(
                                    color: !active ? Colors.white : Colors.transparent,
                                    shape: CircleBorder(),
                                  ),
                                   child: SizedBox(
                                    height: 50.0,
                                    width: 50,
                                    child: IconButton(
                                        onPressed: (){
                                          setState(() {
                                            if(light == 1){

                                              light =0;
                                            }else{

                                              light =1;
                                            }
                                          });
                                        }, icon: Icon(
                                      Icons.highlight,  size: 30, color: !active ? Colors.black : Colors.white)),
                                ),
                                 );
                              }
                            ),
                             SizedBox(width: 50,),
                            Builder(
                              builder: (context) {
                                bool active = indicator == 3;
                                return Ink(
                                  decoration: ShapeDecoration(
                                    color: active ? Colors.white : Colors.transparent,
                                    shape: CircleBorder(),
                                  ),
                                   child: SizedBox(
                                    height: 50.0,
                                    width: 50,
                                    child: IconButton(
                                        onPressed: (){
                                          setState(() {
                                            if(indicator == 3){
                                              indicator = 0;
                                            }else{
                                              indicator = 3;
                                            }
                                          });
                                        }, icon: Icon(
                                      Icons.emergency_outlined,  size: 30, color: active ? Colors.black : Colors.white)),
                                ),
                                 );
                              }
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: ToggleSwitch(
                          minWidth: double.infinity,
                          minHeight: 60.0,
                          initialLabelIndex: idx,
                          cornerRadius: 0,
                          activeFgColor: Colors.white,
                          inactiveBgColor: Color(0xFF16263d).withOpacity(0.5),
                          inactiveFgColor: Colors.white,
                          totalSwitches: 5,
                          fontSize: 20,
                          labels: ['P', 'R', 'N', 'D', 'L'],
                          iconSize: 25.0,
                          activeBgColors: [
                            [Color(0xFF429DC4), Color(0xff0077f2)],
                            [Color(0xFF429DC4), Color(0xff0077f2)],
                            [Color(0xFF429DC4), Color(0xff0077f2)],
                            [Color(0xFF429DC4), Color(0xff0077f2)],
                            [Color(0xFF429DC4), Color(0xff0077f2)],
                          ],
                          onToggle: (index) {
                            setState(() {
                              idx = index!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 0,
                      )
                    ],
                  )
                : Text("Disconnected"),
      ),
    );
  }

  SingleChildScrollView buildDrawer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Text("Debugger"),
          ),
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
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            child: Text("Socket"),
          ),
          Container(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ...socket_buffers.map((message) {
                    return Row(
                      children: <Widget>[
                        Container(
                          child: Text(
                              (text) {
                                return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                              }(message.trim()),
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          currentVal.length == 0
              ? Container()
              : Column(
                  children: [
                    ...List.generate(
                      10,
                      (index) => Row(
                        children: [
                          Text("Relay ${index + 1}"),
                          Switch(
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
                                for (int i = 0; i < 10; i++) {
                                  if (i == index) {
                                    message += currentVal[index] == "0" ? "1" : "0";
                                  } else {
                                    message += currentVal[i];
                                  }
                                  if (i != 10 - 1) {
                                    message += ",";
                                  }
                                }
                                print(currentVal);
                                _sendMessage(message);
                              }),
                        ],
                      ),
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
                ),
        ],
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
        .where((line) => line.startsWith("#") && line.split(",").length == 12)
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
