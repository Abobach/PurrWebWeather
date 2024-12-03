import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WeatherSearchScreen(),
    );
  }
}

class WeatherSearchScreen extends StatefulWidget {
  const WeatherSearchScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherSearchScreenState createState() => _WeatherSearchScreenState();
}

class _WeatherSearchScreenState extends State<WeatherSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = 'London'; // Default city
  String _temperature = '';
  String _weatherDescription = '';
  String _precipitation = '';
  String _errorMessage = '';
  List<String> _citySuggestions = []; // List for city suggestions

  final String apiKey = 'f3551e29ac184c2baed120343240312'; // Your WeatherAPI key

  Future<void> fetchWeather(String city) async {
    final url = Uri.parse('https://api.weatherapi.com/v1/current.json?key=$apiKey&q=${Uri.encodeComponent(city)}&lang=en');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _city = data['location']['name'];
          _temperature = '${data['current']['temp_c']}°C'; // Temperature in Celsius
          _weatherDescription = data['current']['condition']['text'];
          _precipitation = data['current']['precip_mm'] != null ? '${data['current']['precip_mm']} mm' : 'No precipitation';
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: не удалось подключиться к API. $e';
      });
    }
  }

  Future<void> fetchCitySuggestions(String query) async {
    final url = Uri.parse('https://api.weatherapi.com/v1/search.json?key=$apiKey&q=${Uri.encodeComponent(query)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _citySuggestions = List<String>.from(data.map((city) => city['name']));
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка: не удалось получить данные о городе.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: не удалось подключиться к API. $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather(_city); // Fetch weather for the default city at app launch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода PurrWeb'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Input field for city search
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Введите город',
                border: OutlineInputBorder(),
              ),
              onChanged: (String query) {
                if (query.isNotEmpty) {
                  fetchCitySuggestions(query); // Fetch city suggestions as user types
                } else {
                  setState(() {
                    _citySuggestions = [];
                  });
                }
              },
              onSubmitted: (String city) {
                setState(() {
                  _city = city;
                  fetchWeather(_city); // Fetch weather for entered city
                });
              },
            ),
            const SizedBox(height: 16),
            // Show city suggestions in a list
            if (_citySuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: _citySuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_citySuggestions[index]),
                    onTap: () {
                      setState(() {
                        _city = _citySuggestions[index];
                        fetchWeather(_city); // Fetch weather for selected city
                        _controller.text = _city;
                        _citySuggestions = []; // Clear suggestions after selection
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            // Error message if there is any
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            // Weather information if available
            if (_city.isNotEmpty && _errorMessage.isEmpty)
              Column(
                children: [
                  Text(
                    _city,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _temperature,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherDescription,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Осадки: $_precipitation',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
