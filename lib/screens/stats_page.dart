// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, unnecessary_null_comparison

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    var box = Hive.box('userBox');
    String username = box.get('username') ?? 'Unknown';
    //print('Username from Hive: $username');

    try {
      // Fetch stats from leetcode-stats-api
      final statsResponse = await http.get(
        Uri.parse('https://leetcode-stats-api.herokuapp.com/$username'),
      );

      if (statsResponse.statusCode == 200) {
        final statsData = jsonDecode(statsResponse.body);
        if (statsData['status'] == 'success') {
          // Fetch submissions from LeetCode GraphQL API
          final submissions = await fetchSubmissions(username);

          setState(() {
            stats = {
              'solved': statsData['totalSolved'] ?? 0,
              'easy': statsData['easySolved'] ?? 0,
              'medium': statsData['mediumSolved'] ?? 0,
              'hard': statsData['hardSolved'] ?? 0,
              'badges': 0,
              'submissions': submissions,
              'dailySubmissions': _parseSubmissionCalendar(statsData['submissionCalendar']),
            };
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to retrieve stats';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error fetching stats: ${statsResponse.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<List<String>> fetchSubmissions(String username) async {
    const String leetcodeSessionCookie = 'YOUR_LEETCODE_SESSION_COOKIE_HERE'; // Replace with your actual cookie

    const String query = '''
      query recentSubmissions(\$username: String!, \$limit: Int!) {
        recentSubmissionList(username: \$username, limit: \$limit) {
          title
          statusDisplay
          lang
          timestamp
        }
      }
    ''';

    final Map<String, dynamic> variables = {
      'username': username,
      'limit': 20,
    };

    try {
      //print('Fetching submissions for username: $username');
      final response = await http.post(
        Uri.parse('https://leetcode.com/graphql'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'LEETCODE_SESSION=$leetcodeSessionCookie',
        },
        body: jsonEncode({
          'query': query,
          'variables': variables,
        }),
      );

      //print('GraphQL Response Status: ${response.statusCode}');
      //print('GraphQL Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //print('Parsed GraphQL Data: $data');

        if (data['data'] != null && data['data']['recentSubmissionList'] != null) {
          final submissions = data['data']['recentSubmissionList'] as List<dynamic>;
          if (submissions.isEmpty) {
            //print('No submissions found for user $username');
            return ['No submissions found for this user'];
          }
          return submissions.map((submission) {
            final title = submission['title'] ?? 'Unknown Problem';
            final status = submission['statusDisplay'] ?? 'Unknown Status';
            final lang = submission['lang'] ?? 'Unknown Language';
            final timestamp = submission['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(submission['timestamp']) * 1000).toString()
                : 'Unknown Date';
            return '$title ($status, $lang, $timestamp)';
          }).toList();
        } else if (data['errors'] != null) {
          //print('GraphQL Errors: ${data['errors']}');
          return ['GraphQL Error: ${data['errors'].toString()}'];
        } else {
          //print('No submission data found in response');
          return ['No submission data found'];
        }
      } else {
        //print('Failed to fetch submissions: ${response.statusCode}');
        return ['Error fetching submissions: ${response.statusCode}'];
      }
    } catch (e) {
      //print('Exception while fetching submissions: $e');
      return ['Error fetching submissions: $e'];
    }
  }

  Map<String, List<int>> _parseSubmissionCalendar(dynamic calendar) {
    Map<String, List<int>> result = {
      'Jan': [],
      'Feb': [],
      'Mar': [],
      'Apr': [],
      'May': [],
      'Jun': [],
      'Jul': [],
      'Aug': [],
      'Sep': [],
      'Oct': [],
      'Nov': [],
      'Dec': [],
    };

    if (calendar == null || calendar is! Map<String, dynamic>) {
      return result;
    }

    calendar.forEach((timestamp, count) {
      if (timestamp != null && count != null && int.tryParse(count.toString()) != null && int.tryParse(count.toString())! > 0) {
        try {
          DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
          String month = _getMonthName(date.month);
          if (result.containsKey(month)) {
            result[month]!.add(date.day);
          }
        } catch (e) {
          // Skip invalid timestamps
        }
      }
    });

    return result;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('userBox');
    String username = box.get('username') ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: Text('$username\'s Stats', style: TextStyle(color: Colors.white),),
        backgroundColor:Color.fromARGB(255, 31, 31, 31),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 7),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 31, 31, 31),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'QUESTIONS COUNT',
                                      style: TextStyle(color: Colors.white70, fontSize: 16),
                                    ),
                                    Text(
                                      'SOLVED : ${stats!['solved']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDifficultyRow('EASY', stats!['easy'], Colors.green),
                                    _buildDifficultyRow('MEDIUM', stats!['medium'], Colors.orange),
                                    _buildDifficultyRow('HARD', stats!['hard'], Colors.red),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'BADGES',
                                      style: TextStyle(color: Colors.white70, fontSize: 16),
                                    ),
                                    Text(
                                      'EARNED : ${stats!['badges']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                                    const SizedBox(height: 10),
                                    const Icon(Icons.camera_alt, color: Colors.white, size: 50),
                                    const Text(
                                      'No badges earned yet !!',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
// Daily Submissions Section
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 31, 31, 31),
                            borderRadius: BorderRadius.circular(15)
                          ),
                        child:Column(
                          children: [
                        const Text(
                          'DAILY SUBMISSIONS',
                          style: TextStyle(color: Colors.white70, fontSize: 18,fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Past 12 months',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMonthGrid('Jan', stats!['dailySubmissions']['Jan'] ?? []),
                                  _buildMonthGrid('Feb', stats!['dailySubmissions']['Feb'] ?? []),
                                  _buildMonthGrid('Mar', stats!['dailySubmissions']['Mar'] ?? []),
                                  _buildMonthGrid('Apr', stats!['dailySubmissions']['Apr'] ?? []),
                                  _buildMonthGrid('May', stats!['dailySubmissions']['May'] ?? []),
                                  _buildMonthGrid('Jun', stats!['dailySubmissions']['Jun'] ?? []),
                                  _buildMonthGrid('Jul', stats!['dailySubmissions']['Jul'] ?? []),
                                  _buildMonthGrid('Aug', stats!['dailySubmissions']['Aug'] ?? []),
                                  _buildMonthGrid('Sep', stats!['dailySubmissions']['Sep'] ?? []),
                                  _buildMonthGrid('Oct', stats!['dailySubmissions']['Oct'] ?? []),
                                  _buildMonthGrid('Nov', stats!['dailySubmissions']['Nov'] ?? []),
                                  _buildMonthGrid('Dec', stats!['dailySubmissions']['Dec'] ?? []),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                          ],
                        ),
                        ),
                        const SizedBox(height: 20),

                        // Submissions Section
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 31, 31, 31),
                            borderRadius: BorderRadius.circular(15)
                          ),
                        child:Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                          const Text(
                            'SUBMISSIONS',
                            style: TextStyle(color: Colors.white70, fontSize: 18,fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          stats!['submissions'].isEmpty
                              ? const Text(
                                  'No submissions available',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                )
                              : (stats!['submissions'].length == 1 && stats!['submissions'][0].startsWith('Error'))
                                  ? Text(
                                      stats!['submissions'][0],
                                      style: const TextStyle(color: Colors.red, fontSize: 16),
                                    )
                                  : (stats!['submissions'].length == 1 && stats!['submissions'][0].startsWith('No submissions'))
                                      ? Text(
                                          stats!['submissions'][0],
                                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: stats!['submissions'].length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(255, 59, 59, 59),
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                              child:Padding(padding: EdgeInsets.all(5),
                                              child:Text(
                                                stats!['submissions'][index],
                                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                              ),),),
                                            );
                                          },
                                        ),
                            ],),
                        ),),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDifficultyRow(String difficulty, int count, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 10),
        Text(
          '$difficulty : $count',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(String month, List<int> activeDays) {
    const double cellSize = 20.0;
    const int rows = 5;
    const int columns = 7;
    const double spacing = 2.0;
    const double gridHeight = cellSize * rows + (rows - 1) * spacing;
    const double gridWidth = cellSize * columns + (columns - 1) * spacing;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            month,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: gridHeight,
            width: gridWidth,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(35, (index) {
                int day = index + 1;
                return Container(
                  color: activeDays.contains(day) ? Colors.green : Colors.grey[800],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}