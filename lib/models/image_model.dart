class ImageModel {
  final int id;
  final int views;
  final int likes;
  final String webformatURL;
  final String largeImageURL;

  ImageModel({
    required this.id,
    required this.views,
    required this.likes,
     required this.webformatURL,
    required this.largeImageURL,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      views: json['views'],
      likes: json['likes'],
        webformatURL: json['webformatURL'],
      largeImageURL: json['largeImageURL'],
    );
  }
}