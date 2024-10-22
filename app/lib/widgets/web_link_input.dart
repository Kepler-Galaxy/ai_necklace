import 'package:flutter/material.dart';
import 'package:foxxy_package/providers/memory_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

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
            S.current.ArticleLinkWeChatArticleorOthers,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: S.current.PasteArticleLinkHere,
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
                  : Text(S.current.CreateMemory,
                      style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submitLink() async {
    String inputText = _linkController.text.trim();
    String? extractedUrl = _extractUrl(inputText);

    if (extractedUrl != null) {
      Navigator.of(context).pop();
      await Provider.of<MemoryProvider>(context, listen: false)
          .addWebLinkMemory(extractedUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.NoValidURLFound)),
      );
    }
  }

  String? _extractUrl(String text) {
    // Regular expression to match URLs
    final urlRegExp = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    final match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }
}
