import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  static Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Origin': 'http://localhost',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Analisis header rate limiting jika ada
        final limit = response.headers['x-ratelimit-limit'];
        final remaining = response.headers['x-ratelimit-remaining'];
        throw Exception('403 Forbidden. Rate limit: $remaining/$limit');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<dynamic>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = ApiService.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data dari JSON'),
        backgroundColor: Colors.blue[100],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureUsers = ApiService.fetchUsers();
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return ListTile(
                title: Text("Nama :${user['name']}"),
                subtitle: Text("Email   :${user['email']}"),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _futureUsers = ApiService.fetchUsers();
          });
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
