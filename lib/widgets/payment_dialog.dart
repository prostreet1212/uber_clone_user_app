import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import '../methods/common_methods.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({Key? key, required this.fareAmount}) : super();

  final String fareAmount;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.black54,
      child: Container(
        margin: EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 21,
            ),
            Text(
              'PAY CASH',
              style: TextStyle(color: Colors.grey),
            ),
            Divider(
              height: 1.5,
              color: Colors.white70,
              thickness: 1,
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              '\$' + widget.fareAmount,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 36,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 16,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'This is fare amount ( \$ ${widget.fareAmount} ) you have to pay to the driver',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(
              height: 31,
            ),
            ElevatedButton(
              child: Text('PAY CASH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pop(context,'paid');

              },
            ),
            SizedBox(
              height: 41,
            ),
          ],
        ),
      ),
    );
  }
}
