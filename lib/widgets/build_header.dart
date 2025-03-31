import 'package:flutter/material.dart';

class BuildHeader extends StatelessWidget {
  final String title;
  final bool backPage;
  final GestureTapCallback? onTap;

  const BuildHeader({
    super.key,
    required this.title,
    required this.backPage,
    this.onTap,
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
                  onTap: onTap,
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
          ],
        ),
      ),
    );
  }
}
