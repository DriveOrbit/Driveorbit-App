import 'package:flutter/material.dart';

class BulletPoint extends StatelessWidget {
  final String text;
  
  const BulletPoint({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class ToolItem extends StatelessWidget {
  final String text;
  final bool available;
  
  const ToolItem({Key? key, required this.text, required this.available}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
