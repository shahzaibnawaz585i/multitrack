import 'package:flutter/material.dart';

class ServerDropdown extends StatefulWidget {
  @override
  _ServerDropdownState createState() => _ServerDropdownState();
}

class _ServerDropdownState extends State<ServerDropdown> {
  String selectedServer = "Server 1";

  final List<String> servers = [
    "Server 1",
    "Server 2",
    "Server 3",
  ];

  @override
  Widget build(BuildContext context) {
    return
      Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedServer,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.pink),
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          items: servers.map((String server) {
            return DropdownMenuItem<String>(
              value: server,
              child: Text(server),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedServer = value!;
            });
          },
        ),
      ),
    );
  }
}