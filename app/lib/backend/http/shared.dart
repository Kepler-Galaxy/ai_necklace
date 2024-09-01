import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:friend_private/backend/auth.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/env/env.dart';
import 'package:friend_private/main.dart';
import 'package:http/http.dart' as http;
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:instabug_http_client/instabug_http_client.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void showErrorDialog(String errorMessage) {
  showDialog(
    context: MyApp.navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<String> getAuthHeader() async {
  DateTime? expiry = DateTime.fromMillisecondsSinceEpoch(
      SharedPreferencesUtil().tokenExpirationTime);
  if (SharedPreferencesUtil().authToken == '' ||
      expiry.isBefore(DateTime.now()) ||
      expiry.isAtSameMomentAs(DateTime.fromMillisecondsSinceEpoch(0)) ||
      (expiry.isBefore(DateTime.now().add(const Duration(minutes: 5))) &&
          expiry.isAfter(DateTime.now()))) {
    SharedPreferencesUtil().authToken = await getIdToken() ?? '';
  }
  if (SharedPreferencesUtil().authToken == '') {
    // showErrorDialog("No auth token found");
    throw Exception('No auth token found');
  }
  return 'Bearer ${SharedPreferencesUtil().authToken}';
}

Future<http.Response?> makeApiCall({
  required String url,
  required Map<String, String> headers,
  required String body,
  required String method,
}) async {
  try {
    // var startTime = DateTime.now();
    bool result = await InternetConnection().hasInternetAccess; // 600 ms on avg
    // debugPrint('Internet connection check took: ${DateTime.now().difference(startTime).inMilliseconds} ms');
    if (!result) {
      debugPrint('No internet connection, aborting $method $url');
      return null;
    }
    if (url.contains(Env.apiBaseUrl!)) {
      headers['Authorization'] = await getAuthHeader();
      headers['Provider'] = 'authing';
      // No token skipped the request
      if (headers['Authorization'] == "" || headers["Authorization"] == null) {
        return null;
      }
      // headers['Authorization'] = ''; // set admin key + uid here for testing
    }

    debugPrint('Url $url');
    final client = InstabugHttpClient();

    if (method == 'POST') {
      headers['Content-Type'] = 'application/json';
      return await client.post(Uri.parse(url), headers: headers, body: body);
    } else if (method == 'GET') {
      return await client.get(Uri.parse(url), headers: headers);
    } else if (method == 'DELETE') {
      return await client.delete(Uri.parse(url), headers: headers);
    } else if (method == 'PATCH') {
      return await client.patch(Uri.parse(url), headers: headers);
    } else {
      throw Exception('Unsupported HTTP method: $method');
    }
  } catch (e, stackTrace) {
    debugPrint('HTTP request failed: $e, $stackTrace');
    // showErrorDialog('HTTP request failed: $e');
    CrashReporting.reportHandledCrash(
      e,
      stackTrace,
      userAttributes: {'url': url, 'method': method},
      level: NonFatalExceptionLevel.warning,
    );
    return null;
  } finally {}
}

// Function to extract content from the API response.
dynamic extractContentFromResponse(
  http.Response? response, {
  bool isEmbedding = false,
  bool isFunctionCalling = false,
}) {
  if (response != null && response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (isEmbedding) {
      var embedding = data['data'][0]['embedding'];
      return embedding;
    }
    var message = data['choices'][0]['message'];
    if (isFunctionCalling && message['tool_calls'] != null) {
      debugPrint('message $message');
      debugPrint('message ${message['tool_calls'].runtimeType}');
      return message['tool_calls'];
    }
    return data['choices'][0]['message']['content'];
  } else {
    debugPrint('Error fetching data: ${response?.statusCode}');
    showErrorDialog('Error fetching data: ${response?.statusCode}');
    // TODO: handle error, better specially for script migration
    CrashReporting.reportHandledCrash(
      Exception('Error fetching data: ${response?.statusCode}'),
      StackTrace.current,
      userAttributes: {
        'response_null': (response == null).toString(),
        'response_status_code': response?.statusCode.toString() ?? '',
        'is_embedding': isEmbedding.toString(),
        'is_function_calling': isFunctionCalling.toString(),
      },
      level: NonFatalExceptionLevel.warning,
    );
    return null;
  }
}
