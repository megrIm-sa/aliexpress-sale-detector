import 'dart:async';
import 'package:aliexpress_sale_detector/backgroundTaskManager.dart';
import 'package:aliexpress_sale_detector/notificationManager.dart';
import 'package:flutter/material.dart';
import 'package:http_query_string/http_query_string.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aliexpress_sale_detector/memoryManager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AliExpress Sale Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AliExpress Sale Detector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _urlController = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool _isLoading = false;

  @override
  void initState() {
    initItems();
    super.initState();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    MyHomePage.flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _requestPermissions();
    BackgroundTaskManger.configureBackgroundFetch(items);
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    var status = await Permission.notification.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No notification permission! Turn on notifications in settings!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  // Get items from memory
  Future<void> initItems() async {
    items = await MemoryManager.loadItemsFromMemory(items);
    setState(() {
    });
  }

  // Get data about item by link
  Future<void> getWebsiteData(String userInput) async {
    setState(() {
      _isLoading = true;
    });

    var querifiedLink = Encoder().convert(<String, dynamic>{
      'link': userInput,
      "search_from": "index_Index_index"
    });
    print(querifiedLink);
    final url = Uri.parse("https://www.aliprice.com/Index/search.html?" +
        querifiedLink as String);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final title = html
        .querySelector(
        'body > div.main.grey-bg > div > div.left-content > div.product-wrap > div.product-info > div.product-title > a')
        ?.innerHtml
        .trim();

    final price = html
        .querySelector(
        'body > div.main.grey-bg > div > div.left-content > div.product-wrap > div.product-info > div.product-price > em')
        ?.innerHtml
        .trim();

    if (title == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch data. Please try again.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } else {
      items.add({'title': title, 'price': price, 'userInput': userInput});
      MemoryManager.saveItemsToMemory(items);
    }

    setState(() {
      _isLoading = false;
    });

    print('Title: ${title}, \nPrice: ${price}');
    print('Items: $items');
  }

  // Delete item from items
  void deleteItem(int index) {
    setState(() {
      items.removeAt(index);
      MemoryManager.saveItemsToMemory(items);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_isLoading)
              Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Enter URL',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      getWebsiteData(_urlController.text);
                      _urlController.clear();
                    },
                    child: const Text('Fetch Data'),
                  ),
                  ElevatedButton(
                    onPressed: NotificationManager.showNotification,
                    child: const Text('Show Notification'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading && items.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          color: Colors.grey[200],
                          child: GestureDetector(
                            onTap: () async {
                              String url = items[index]['userInput'];
                              if (url.isNotEmpty && Uri.tryParse(url) != null) {
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid URL'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: ListTile(
                              title: Text(items[index]['title'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(items[index]['price'] ?? ''),
                                  Text('Link: ${items[index]['userInput'] ?? ''}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteItem(index);
                                },
                              ),
                            ),
                          ),
                        ),
                        if (index != items.length - 1) Divider(color: Colors.red,),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
