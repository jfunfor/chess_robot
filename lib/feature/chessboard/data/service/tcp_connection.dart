import 'dart:async';
import 'dart:io';
import 'dart:convert';

class TcpSocketConnection {
  late String _ipAddress;
  late int _portAddress;
  Socket? _server;
  bool _connected = false;
  bool _logPrintEnabled = false;
  Completer responseCompleter = Completer();

  /// Initializes che class itself
  ///  * @param  ip  the server's ip you are trying to connect to
  ///  * @param  port the servers's port you are trying to connect to
  TcpSocketConnection(String ip, int port) {
    _ipAddress = ip;
    _portAddress = port;
  }

  /// Initializes che class itself
  ///  * @param  the ip  server's ip you are trying to connect to
  ///  * @param  the port servers's port you are trying to connect to
  ///  * @param  enable if set to true, then events will be printed in the console
  TcpSocketConnection.constructorWithPrint(String ip, int port, bool enable) {
    _ipAddress = ip;
    _portAddress = port;
    _logPrintEnabled = enable;
  }

  /// Shows events in the console with print method
  /// * @param  enable if set to true, then events will be printed in the console
  enableConsolePrint(bool enable) {
    _logPrintEnabled = enable;
  }

  /// Initializes the connection. Socket starts listening to server for data
  /// 'callback' function will be called whenever data is received. The developer elaborates the message received however he wants
  /// No separator is used to split message into parts
  ///  * @param  timeOut  the amount of time to attempt the connection in milliseconds
  ///  * @param  callback  the function called when received a message. It must take a 'String' as param which is the message received
  ///  * @param  attempts  the number of attempts before stop trying to connect. Default is 1.
  connect(int timeOut, Function callback, {int attempts = 1}) async {
    int k = 1;
    while (k <= attempts) {
      try {
        _server = await Socket.connect(_ipAddress, _portAddress,
            timeout: Duration(milliseconds: timeOut));
        break;
      } catch (ex) {
        _printData("$k attempt: Socket not connected (Timeout reached)");
        if (k == attempts) {
          return;
        }
      }
      k++;
    }
    _connected = true;
    _printData("Socket successfully connected");
    _server!.listen((List<int> event) async {
      String received = (ascii.decode(event));
      responseCompleter.complete(received);
      _printData("Message received: $received");
      callback(received);
    });
  }

  /// Stops the connection and closes the socket
  void disconnect() {
    if (_server != null) {
      try {
        _server!.close();
        _printData("Socket disconnected successfully");
      } catch (exception) {
        print("ERROR $exception");
      }
    }
    _connected = false;
  }

  /// Checks if the socket is connected
  bool isConnected() {
    return _connected;
  }

  /// Sends a message to server. Make sure to have established a connection before calling this method
  /// Message will be sent as 'message'
  ///  * @param  message  message to send to server
  Future<String> sendMessage(String message) async {
    String response = '';
    print('$message $_server $_connected');
    if (_server != null && _connected) {
      _server!.add(ascii.encode(message));
      response = await responseCompleter.future;
      responseCompleter = Completer();
      _printData("Message sent: $response");
    } else {
      print(
          "Socket not initialized before sending message! Make sure you have already called the method 'connect()'");
    }
    return response;
  }

  /// Test the connection. It will try to connect to the endpoint and if it does, it will disconnect and return 'true' (otherwise false)
  ///  * @param  timeOut  the amount of time to attempt the connection in milliseconds
  ///  * @param  attempts  the number of attempts before stop trying to connect. Default is 1.
  Future<bool> canConnect(int timeOut, {int attempts = 1}) async {
    int k = 1;
    while (k <= attempts) {
      try {
        _server = await Socket.connect(_ipAddress, _portAddress,
            timeout: Duration(milliseconds: timeOut));
        disconnect();
        return true;
      } catch (exception) {
        _printData("$k attempt: Socket not connected (Timeout reached)");
        if (k == attempts) {
          disconnect();
          return false;
        }
      }
      k++;
    }
    disconnect();
    return false;
  }

  void _printData(String data) {
    if (_logPrintEnabled) {
      print(data);
    }
  }
}
