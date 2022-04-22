import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http_request_caching/unix_timestamp.dart';

import 'package:path_provider/path_provider.dart' as provider;
import 'package:http_request_caching/credentials.dart' as credentials;
import 'package:http_request_caching/cached_http.dart' as http;

Future<void> main() async {
  /// This project uses the Hive database to store data.
  /// Read more: https://pub.dev/packages/hive
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    final dir = await provider.getApplicationDocumentsDirectory();
    final path = dir.path;

    Hive.init(path);
  }

  runApp(
    App(),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Http request caching',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic> data;

  Future<bool> initializeHiveDb() async {
    try {
      await Hive.openBox('cache');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  final String url =
      'https://api.openweathermap.org/data/2.5/weather?lat=${credentials.LAT}&lon=${credentials.LON}&appid=${credentials.API_KEY}&units=metric';

  Future<void> fetchWeatherData() async {
    setState(() => data = null);

    final Map<String, dynamic> _data = await http.get(
      url,
      cacheValidity: const Duration(minutes: 5),
    );
    setState(() => data = _data);
  }

  String formatMinute(int minute) =>
      minute > 9 ? minute.toString() : '0$minute';

  double get temperature => data['main']['temp'];
  double get temperatureFeelsLike => data['main']['feels_like'];

  String get location => data['name'];

  DateTime get date => UnixTimestamp.fromInt(
        data['dt'],
      ).toDate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: initializeHiveDb(),
        builder: (
          BuildContext context,
          AsyncSnapshot snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: fetchWeatherData,
                  child: const Text(
                    'Fetch data',
                  ),
                ),
                SizedBox(
                  height: 100.0,
                  child: data == null
                      ? const SizedBox()
                      : Column(
                          children: <Widget>[
                            Text(
                              '${date.hour}:${formatMinute(date.minute)}, ${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              'Temperature: $temperature °C',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              'Feels like: $temperatureFeelsLike °C',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              'Location: $location',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
