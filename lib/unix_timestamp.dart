class UnixTimestamp {
  /// This class handles unix timestamps,
  /// it allows converting unix timestamp to
  /// DateTime. It was created to handle
  /// timestamps provided by the OpenWeatherMap api.
  final int timestamp;
  UnixTimestamp.fromInt(this.timestamp);

  DateTime get date => this.toDate();
  int get millisecondsSinceEpoch => this.timestamp * 1000;

  DateTime toDate() =>
      DateTime.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch);
}
