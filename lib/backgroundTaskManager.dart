import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;
import 'package:http_query_string/http_query_string.dart';
import 'package:html/dom.dart' as dom;
import 'package:aliexpress_sale_detector/notificationManager.dart';

class BackgroundTaskManger {
  // Configure background task for fetching
  static Future<void> configureBackgroundFetch(items) async {
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ),
          (String taskId) async {
        // Run your background task here
        print('[Background Fetch] TaskId: $taskId');

        for (var item in items) {
          await checkPrice(items);
        }

        BackgroundFetch.finish(taskId);
      },
          (String taskId) async {
        // Error handling
        print('[Background Fetch] ERROR: TaskId: $taskId');
      },
    );
  }

  // Check price by fetching and call showNotification
  static Future<void> checkPrice(items) async {
    for (var item in items) {
      final String userInput = item['userInput'];
      final String currentPrice = item['price'];

      // Fetch the current price from the website
      final response = await http.get(Uri.parse(
          "https://www.aliprice.com/Index/search.html?" +
              Encoder().convert({'link': userInput, "search_from": "index_Index_index"})));
      final dom.Document html = dom.Document.html(response.body);
      final String? price = html
          .querySelector(
          'body > div.main.grey-bg > div > div.left-content > div.product-wrap > div.product-info > div.product-price > em')
          ?.innerHtml
          .trim();

      if (price != null && price != currentPrice) {
        // If the prices differ, show notification
        await NotificationManager.showNotification();
      } else {
        print("Price not changed");
      }
    }
  }
}