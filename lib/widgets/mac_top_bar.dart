import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MacTopBar extends StatelessWidget {
  const MacTopBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          const Expanded(
            child: TitleBar(),
          ),
          Theme(
            data: ThemeData.dark(),
            child: PopupMenuButton(
              onSelected: (value) {
                if (value == 1) {
                  launchUrlString('https://github.com/odinapp/odin#readme');
                } else if (value == 2) {
                  launchUrlString('https://www.buymeacoffee.com/HashStudios');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  height: 32,
                  value: 1,
                  child: Text(
                    "About",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  height: 32,
                  child: Text(
                    "Support us",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.adaptive.more_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TitleBar extends StatelessWidget {
  const TitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Odin",
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white60,
        ),
      ),
    );
  }
}
