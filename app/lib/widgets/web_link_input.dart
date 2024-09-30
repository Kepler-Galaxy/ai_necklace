import 'package:flutter/material.dart';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:provider/provider.dart';

class WebLinkArticleInputWidget extends StatefulWidget {
  @override
  _WebLinkArticleInputWidgetState createState() =>
      _WebLinkArticleInputWidgetState();
}

class _WebLinkArticleInputWidgetState extends State<WebLinkArticleInputWidget> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Article Link: WeChat Article or Others',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'Paste article link here',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLink,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Create Memory',
                      style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submitLink() async {
    Navigator.of(context).pop();
    await Provider.of<MemoryProvider>(context, listen: false)
        .addWebLinkMemory(_linkController.text);
  }
}
