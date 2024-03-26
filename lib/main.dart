import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repositories',
      home: RepositoryListScreen(),
    );
  }
}

class Repository {
  final String name;
  final String description;
  final int stargazersCount;

  Repository({
    required this.name,
    required this.description,
    required this.stargazersCount,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'],
      description: json['description'] ?? 'No description',
      stargazersCount: json['stargazers_count'],
    );
  }
}

class Commit {
  final String message;
  final String author;
  final DateTime date;

  Commit({
    required this.message,
    required this.author,
    required this.date,
  });

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      message: json['commit']['message'],
      author: json['commit']['author']['name'],
      date: DateTime.parse(json['commit']['author']['date']),
    );
  }
}

class RepositoryService {
  Future<List<Repository>> fetchRepositories() async {
    final response =
    await http.get(Uri.parse('https://api.github.com/users/aryan1010/repos'));
    if (response.statusCode == 200) {
      final dynamic jsonData = json.decode(response.body);
      if (jsonData is List) {
        return jsonData.map((json) => Repository.fromJson(json)).toList();
      } else if (jsonData is Map) {
        final List<dynamic> jsonList = jsonData.values.toList();
        return jsonList.map((json) => Repository.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to fetch repositories');
    }
  }

  Future<Commit?> fetchLastCommit(String repoName) async {
    final response = await http.get(
        Uri.parse('https://api.github.com/repos/aryan1010/$repoName/commits'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      if (jsonList.isNotEmpty) {
        return Commit.fromJson(jsonList[0]);
      }
    }
    return null;
  }
}

class RepositoryListScreen extends StatefulWidget {
  @override
  _RepositoryListScreenState createState() => _RepositoryListScreenState();
}

class _RepositoryListScreenState extends State<RepositoryListScreen> {
  final RepositoryService _repositoryService = RepositoryService();
  List<Repository> _repositories = [];
  Map<String, Commit?> _commits = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final repositories = await _repositoryService.fetchRepositories();
      setState(() {
        _repositories = repositories;
      });

      // Fetch last commit for each repository
      for (var repo in repositories) {
        final commit = await _repositoryService.fetchLastCommit(repo.name);
        setState(() {
          _commits[repo.name] = commit;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: _repositories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
        itemCount: _repositories.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final repository = _repositories[index];
          final commit = _commits[repository.name];
          return GestureDetector(
            onTap: () {
              if (commit != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommitDetailsScreen(commit: commit),
                  ),
                );
              }
            },
            child: ListTile(
              leading: CircleAvatar(
                child: Text(repository.name[0].toUpperCase()),
              ),
              title: Text(
                repository.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repository.description),
                  if (commit != null)
                    Text(
                      'Last commit: ${commit.message}',
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${repository.stargazersCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CommitDetailsScreen extends StatelessWidget {
  final Commit commit;

  CommitDetailsScreen({required this.commit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commit Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(commit.message),
            SizedBox(height: 16),
            Text(
              'Author:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(commit.author),
            SizedBox(height: 16),
            Text(
              'Date:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(commit.date.toString()),
          ],
        ),
      ),
    );
  }
}