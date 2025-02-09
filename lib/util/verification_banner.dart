import 'package:flutter/material.dart';

class VerificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You need to verify your account to continue.',
            style: TextStyle(color: Colors.white),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/verify');
            },
            child: Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
