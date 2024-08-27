import 'package:flutter/material.dart';

class CurrentSubjectCard extends StatefulWidget {
  const CurrentSubjectCard({Key? key}) : super(key: key);

  @override
  State<CurrentSubjectCard> createState() => _CurrentSubjectCardState();
}

class _CurrentSubjectCardState extends State<CurrentSubjectCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.95;
    final cardHeight = cardWidth * 0.38;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: cardHeight * 0.05,
          horizontal: cardHeight * 0.07,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: cardWidth * 0.055,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '{N}교시는',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: cardHeight * 0.15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '{과목명}이에요!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: cardHeight * 0.15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: cardHeight * 0.01),
                      Text(
                        '{N+1}교시 - {과목명}',
                        style: TextStyle(
                          color: const Color(0xFF848484),
                          fontSize: cardHeight * 0.06,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: cardHeight * 0.06),
                      Text(
                        '오전 00:00 - 오전 00:00',
                        style: TextStyle(
                          color: const Color(0xFF848484),
                          fontSize: cardHeight * 0.06,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: cardHeight * 0.06),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: cardWidth * 0.045),
            Container(
              width: cardHeight * 0.62,
              height: cardHeight * 0.62,
              decoration: ShapeDecoration(
                color: const Color(0xFF6EA7FA),
                shape: OvalBorder(
                  side: BorderSide(
                    width: cardHeight * 0.015,
                    color: const Color(0xFF6F97F6),
                  ),
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://via.placeholder.com/80',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: cardWidth * 0.05),
          ],
        ),
      ),
    );
  }
}
