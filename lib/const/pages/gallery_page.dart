import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gallery_web_app/models/image_model.dart';
import 'package:http/http.dart' as http;

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({super.key});

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  List<ImageModel> _images = [];
  int _page = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchImages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchImages();
    }
  }

  Future<void> _fetchImages({String? query}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    const String baseUrl =
        'https://pixabay.com/api/?key=43598726-ad6f10da0025c45b095355418';
    String apiUrl;
    if (query != null) {
      apiUrl = '$baseUrl&q=$query&page=1';
      _page = 1;
    } else {
      apiUrl = '$baseUrl&page=$_page';
    }

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> hits = data['hits'];
      final List<ImageModel> images =
          hits.map((hit) => ImageModel.fromJson(hit)).toList();
      setState(() {
        if (query == null) {
          _images.addAll(images);
          _page++;
        } else {
          _images = images;
        }
        _loading = false;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        _clearSearch();
      } else {
        _fetchImages(query: query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _fetchImages();
    _page = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search....',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _clearSearch();
                _page = 1;
              },
            ),
          ),
        ),
      ),
      body: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width ~/ 200,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index];
          return GestureDetector(
            onTap: () => _openFullScreen(context, image),
            child: Stack(
              children: [
                Image.network(
                  image.webformatURL,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${image.likes} likes',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${image.views} views',
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFullScreen(BuildContext context, ImageModel image) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.7),
      pageBuilder: (BuildContext context, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Hero(
                tag: image.largeImageURL,
                child: Image.network(
                  image.largeImageURL,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }
}
