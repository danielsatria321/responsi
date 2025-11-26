import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Newsdetailpage extends StatefulWidget {
  final int category;

  const Newsdetailpage({super.key, required this.category});

  @override
  State<Newsdetailpage> createState() => _NewsdetailpageState();
}

class _NewsdetailpageState extends State<Newsdetailpage> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoritesList = prefs.getStringList('favorites') ?? [];
    setState(() {
      isFavorite = favoritesList.any((item) {
        final decoded = json.decode(item);
        return decoded['id'] == widget.category;
      });
    });
  }

  Future<void> toggleFavorite(Map<String, dynamic> news) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoritesList = prefs.getStringList('favorites') ?? [];

    if (isFavorite) {
      favoritesList.removeWhere((item) {
        final decoded = json.decode(item);
        return decoded['id'] == widget.category;
      });
      await prefs.setStringList('favorites', favoritesList);
      setState(() {
        isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dihapus dari favorit'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      favoritesList.add(json.encode(news));
      await prefs.setStringList('favorites', favoritesList);
      setState(() {
        isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ditambahkan ke favorit'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchNewsDetail() async {
    //API
    final url = Uri.parse(
      'https://api.spaceflightnewsapi.net/v4/articles/${widget.category}',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Berita'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: fetchNewsDetail(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    toggleFavorite(snapshot.data!);
                  },
                  tooltip: isFavorite
                      ? 'Hapus dari favorit'
                      : 'Tambah ke favorit',
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchNewsDetail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Gagal memuat berita',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Data tidak ditemukan'));
          }

          final news = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  news['image_url'] ?? '',
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported, size: 60),
                    );
                  },
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['title'] ?? 'No Title',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade900,
                        ),
                      ),
                      SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.newspaper,
                            size: 20,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            news['news_site'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(width: 20),
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              news['published_at'] != null
                                  ? news['published_at'].toString().substring(
                                      0,
                                      10,
                                    )
                                  : '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Ringkasan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            news['summary'] ?? 'Tidak ada ringkasan tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      if (news['url'] != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Buka: ${news['url']}')),
                              );
                            },
                            icon: Icon(Icons.open_in_browser),
                            label: Text('Baca Selengkapnya'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
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
