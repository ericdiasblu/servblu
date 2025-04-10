import 'package:flutter/material.dart';

class BuildHeader extends StatelessWidget {
  final String title;
  final bool backPage;
  final bool refresh;
  final GestureTapCallback? onBack, onRefresh;

  const BuildHeader({
    super.key,
    required this.title,
    required this.backPage,
    required this.refresh,
    this.onBack,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF017DFE),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (backPage)
              Positioned(
                left: 16,
                child: GestureDetector(
                  onTap: onBack,
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (refresh)
              Positioned(
                right: 16,
                child: GestureDetector(
                  onTap: onRefresh,
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
