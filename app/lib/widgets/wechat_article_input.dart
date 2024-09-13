import 'package:flutter/material.dart';
import 'package:friend_private/backend/http/api/memories.dart';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:provider/provider.dart';

class WeChatArticleInputWidget extends StatefulWidget {
  @override
  _WeChatArticleInputWidgetState createState() => _WeChatArticleInputWidgetState();
}

class _WeChatArticleInputWidgetState extends State<WeChatArticleInputWidget> {
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
            'WeChat Article Link',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'Paste WeChat article link here',
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
                  : Text('Create Memory', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submitLink() async {
    Navigator.of(context).pop();
    Provider.of<MemoryProvider>(context, listen: false).setCreatingWeChatMemory(true);

    try {
      final memory = await createMemoryFromWeChatArticle(_linkController.text);
      Provider.of<MemoryProvider>(context, listen: false).addMemory(memory);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Memory created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create memory: $e')),
      );
    } finally {
      Provider.of<MemoryProvider>(context, listen: false).setCreatingWeChatMemory(false);
    }
  }
}
