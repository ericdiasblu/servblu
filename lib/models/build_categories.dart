import 'package:flutter/material.dart';

class BuildCategories extends StatelessWidget {
  final String? textCategory;
  final IconData? icon;

  const BuildCategories(
      {Key? key, required this.textCategory, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 9,
        ),
        ElevatedButton(
          onPressed: () {
          },
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(0),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.blue, width: 3),
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.blue,
                size: 35,
              ),
            ),
          ),
        ),
        Text(
          textCategory!,
          style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
