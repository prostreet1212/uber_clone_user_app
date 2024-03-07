import 'package:flutter/material.dart';

class InfoDialog extends StatefulWidget {
  const InfoDialog({Key? key,this.title,this.description}) : super(key: key);

  final String? title,description;

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.grey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 12,
                ),
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 22,
                    color:Colors.white60 ,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 27,
                ),
                Text(
                  widget.description!,
                textAlign: TextAlign.center,
                  style: TextStyle(
                    color:Colors.white54,
                  ),
                ),
                SizedBox(
                  height: 32,
                ),
                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                    child: Text('OK'),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
