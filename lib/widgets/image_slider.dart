import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageSlider extends StatefulWidget {
  final List<String> imagePaths;
  const ImageSlider({Key? key, required this.imagePaths}) : super(key: key);

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 415, // largura atualizada para combinar com _buildImage
        height: 197, // altura atualizada para combinar com _buildImage
        child: ClipRRect(
          child: Stack(
            children: [
              // Slider de imagens
              PageView(
                controller: _pageController,
                children: widget.imagePaths.map((path) {
                  return Image.asset(
                    path,
                    fit: BoxFit.cover,
                  );
                }).toList(),
              ),
              // Indicadores (bolinhas) na parte inferior central
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imagePaths.length, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 8 : 4,
                      height: _currentPage == index ? 8 : 4,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
