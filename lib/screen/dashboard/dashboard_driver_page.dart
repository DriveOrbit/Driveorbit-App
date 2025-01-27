import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: 'Good Morning, ',
                      style: GoogleFonts.poppins(
                          color: Color(0xFF6D6BF8), fontSize: 20.0)),
                  const TextSpan(
                      text: 'Chandeera!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0)),
                ],
              ),
            ),
            const SizedBox(width: 9),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/IMG-20241116-WA0044.jpg'),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: <Widget>[
          vehicleListItem('Nissan Sunny (1997)', 'KY-7766', 'assets/illust.png',
              'Not available'),
          vehicleListItem(
              'Nissan Sunny (1997)', 'KY-7766', 'assets/illust.png', 'Booked'),
          vehicleListItem('Nissan Sunny (1997)', 'KY-7766', 'assets/illust.png',
              'Available'),
          vehicleListItem('Nissan Sunny (1997)', 'KY-7766', 'assets/illust.png',
              'Available'),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget vehicleListItem(
      String model, String plate, String iconPath, String status) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Image.asset(iconPath, width: 40),
        title: Text(model, style: TextStyle(color: Colors.white)),
        subtitle: Text(plate, style: TextStyle(color: Colors.grey)),
        trailing: Text(status,
            style: TextStyle(
                color: status == 'Available' ? Colors.green : Colors.red)),
      ),
    );
  }
}
