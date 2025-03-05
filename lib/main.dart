import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Chat',
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  final _messages = <String>[];
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();
  late final IO.Socket socket;

  @override
  void initState() {
    // Establish connection
    _createConnection();
    super.initState();
  }

  void _createConnection() async {
    // Dart client
    socket = IO.io(
        'http://localhost:3000',
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .build());
    socket.onConnect((_) {
      print('connect');
    });
    socket.on('chat message', (data) {
      setState(() {
        _messages.add(data);
        _scrollToBottom();
      });
    });
    socket.onDisconnect((_) => print('disconnect'));
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  void _send() {
    if (_messageController.text.isNotEmpty) {
      socket.emit('chat message', _messageController.text);
      _messageController.text = '';
    }
    _messageFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChatBubblesScrollView(
              scrollController: _scrollController,
              messages: _messages,
            ),
          ),
          ChatMessageSubmitForm(
              messageFocus: _messageFocus,
              messageController: _messageController,
              send: () => _send())
        ],
      ),
    ));
  }
}

class ChatMessageSubmitForm extends StatelessWidget {
  const ChatMessageSubmitForm({
    super.key,
    required this.messageFocus,
    required this.messageController,
    required this.send,
  });

  final FocusNode messageFocus;
  final TextEditingController messageController;
  final void Function() send;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: TextField(
              focusNode: messageFocus,
              decoration: const InputDecoration(label: Text('Message')),
              controller: messageController,
              onSubmitted: (_) => send(),
            )),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => send(), child: const Text('Send')),
          ],
        ),
      ),
    );
  }
}

/// Scrollable view that list all messages as bubbles
class ChatBubblesScrollView extends StatelessWidget {
  const ChatBubblesScrollView({
    super.key,
    required ScrollController scrollController,
    required List<String> messages,
  })  : _scrollController = scrollController,
        _messages = messages;

  final ScrollController _scrollController;
  final List<String> _messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _messages.length,
      controller: _scrollController,
      itemBuilder: (context, index) => Bubble(_messages[index]),
    );
  }
}

/// Container that displays the message text
class Bubble extends StatelessWidget {
  const Bubble(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(message),
          )),
    );
  }
}
