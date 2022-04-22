import 'dart:convert' show jsonDecode;
import 'dart:developer' show log;

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// Created by Andrej
/// April 21, 2022

Future<Map<String, dynamic>> get(
  String url, {
  Duration cacheValidity = const Duration(
    minutes: 10,
  ),
}) async {
  final Box box = Hive.box('cache');

  bool _ = box.containsKey(url);
  if (_ && cacheValidity.inMilliseconds > 0) {
    /// Retrieves the previously cached response from database.
    final Map<String, dynamic> cResponse = Map<String, dynamic>.from(
      box.get(url),
    );

    final DateTime cTime = cResponse['time'];
    final DateTime now = DateTime.now();

    final Duration difference = now.difference(cTime);

    final Map<String, dynamic> cData = Map<String, dynamic>.from(
      cResponse['data'],
    );

    print(
      '[http] Available cached response from ${cTime.day}/${cTime.month}/${cTime.year} at ${cTime.hour}:${cTime.minute}h.',
    );

    /// Returns the previously cached response if it is still valid.
    if (difference.inMilliseconds < cacheValidity.inMilliseconds) {
      print('[http] Returning data from cached response.');
      return cData;
    } else {
      print('[http] Cached response too old.');
      final Map<String, dynamic> data = await fetchURL(url);

      if (data == null) return cData;
      if (data.length > 0) {
        return data;
      }

      return cData;
    }
  }

  final Map<String, dynamic> data = await fetchURL(url);
  return data;
}

Future<Map<String, dynamic>> fetchURL(
  String url,
) async {
  final Uri uri = Uri.parse(url);

  print('[http] Making request to ${uri.host}...');
  log('[http] Full request URL: $url');

  try {
    final http.Response r = await http.get(uri);

    print('[http] Request response: ${r.statusCode} ${r.reasonPhrase}');

    if (r.statusCode == 200) {
      /// Uses the data of the response only if the
      /// request was succesful, if the status code is 200.
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        jsonDecode(r.body),
      );

      /// Save the data into cache before returning for later use.
      await saveIntoCache(url, data);

      return data;
    }

    return const {};
  } catch (e) {
    print('[http] Error while processing request.');
    log('[http] Full request URL: $url');
    print(e);

    return const {};
  }
}

/// Saves the response data into cache.
Future<void> saveIntoCache(
  String url,
  Map<String, dynamic> data,
) async {
  print('[http] Saving response data into cache.');

  await Hive.box('cache').put(
    url,
    {
      'url': url,
      'time': DateTime.now(),
      'data': data,
    },
  );
}
