class Weather {
  final Temperature? temperature;
  final Temperature? tempFeelsLike;
  final String? weatherDescription;
  final String? weatherMain;
  final int? humidity;
  final double? windSpeed;
  final int? windDegree;
  final int? pressure;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? lon;
  final double? lat;

  Weather({
    this.temperature,
    this.tempFeelsLike,
    this.weatherDescription,
    this.weatherMain,
    this.humidity,
    this.windSpeed,
    this.windDegree,
    this.pressure,
    this.sunrise,
    this.sunset,
    this.lon,
    this.lat,
  });

  factory Weather.fromFirestore(Map<String, dynamic> data) {
    return Weather(
      temperature: Temperature(data['main']['temp']),
      tempFeelsLike: Temperature(data['main']['feels_like']),
      weatherDescription: data['weather'][0]['description'],
      weatherMain: data['weather'][0]['main'],
      humidity: data['main']['humidity'],
      windSpeed: (data['wind']['speed'] as num?)?.toDouble(),
      windDegree: data['wind']['deg'],
      pressure: data['main']['pressure'],
      sunrise: DateTime.fromMillisecondsSinceEpoch((data['sys']['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((data['sys']['sunset'] as int) * 1000),
      lon: (data['coord']['lon'] as num?)?.toDouble(),
      lat: (data['coord']['lat'] as num?)?.toDouble(),
    );
  }
}

class Temperature {
  final double? kelvin;

  Temperature(this.kelvin);

  double? get celsius => kelvin != null ? kelvin! - 273.15 : null;
}