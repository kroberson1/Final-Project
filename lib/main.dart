import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Spotify App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String clientId = 'b70226563b474711ad1e6f0ca077896a';
  final String redirectUri = 'ai.autonet.afterme';
  String? accessToken;
  List<Map<String, dynamic>> topTracks = [];

  Future<void> authenticateSpotify() async {
    // Open Spotify authentication URL
    final result = await FlutterWebAuth.authenticate(
      url:
      'https://accounts.spotify.com/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=token&scope=user-top-read',
      callbackUrlScheme: "flutterapp",
    );

    final Uri resultUri = Uri.parse(result);

    if (resultUri.fragment != null) {
      // Extract access token from URL fragment
      final Map<String, String> params = Uri.splitQueryString(resultUri.fragment!);

      if (params.containsKey('access_token')) {
        setState(() {
          accessToken = params['access_token'];
        });

        await getTopTracks();
      }
    }
  }

  Future<void> getTopTracks() async {
    if (accessToken != null) {
      // Fetch user's top tracks from Spotify API
      final result = await fetchWebApi(
        'v1/me/top/tracks?time_range=long_term&limit=5',
        'GET',
        accessToken: accessToken!,
      );

      setState(() {
        topTracks = List<Map<String, dynamic>>.from(result['items']);
      });
    }
  }

  Future<Map<String, dynamic>> fetchWebApi(String endpoint, String method,
      {String? accessToken}) async {
    // Make HTTP GET request to Spotify API with access token
    final response = await http.get(
      Uri.parse('https://api.spotify.com/$endpoint'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      try {
        // Decode JSON response
        return json.decode(response.body);
      } catch (e) {
        print('Error decoding JSON: $e');
        return {};
      }
    } else {
      print('Error: ${response.statusCode}, ${response.reasonPhrase}');
      return {};
    }
  }

  void clearData() {
    // Clear topTracks list
    setState(() {
      topTracks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Spotify Tracks'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: authenticateSpotify,
              child: Text('Authenticate with Spotify'),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: getTopTracks,
              child: Text('Get Top Tracks'),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: clearData,
              child: Text('Clear Data'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: topTracks.length,
              itemBuilder: (context, index) {
                final track = topTracks[index];
                return ListTile(
                  title: Text('${track['name']}'),
                  subtitle: Text(
                    'by ${track['artists'].map((artist) => artist['name']).join(', ')}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

