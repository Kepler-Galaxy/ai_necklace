import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:provider/provider.dart';
import 'package:foxxy_package/pages/memory_detail/memory_detail_provider.dart';

class LittleRedBookWidget extends StatelessWidget {
  const LittleRedBookWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<MemoryDetailProvider, MemoryExternalLink>(
      selector: (context, provider) => provider.memory.externalLink!,
      builder: (context, memoryExternalLink, child) {
        List<String> images = memoryExternalLink.webContentResponse!.images;
        List<ImageDescription> imageDescriptions =
            memoryExternalLink.webPhotoUnderstanding!;
        
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: imageDescriptions.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, idx) {
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (c) {
                    return getDialog(
                      context,
                      () => Navigator.pop(context),
                      () => Navigator.pop(context),
                      'Description',
                      imageDescriptions[idx].description,
                      singleButton: true,
                    );
                  },
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    base64Decode(imageDescriptions[idx].imageBase64),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        imageDescriptions[idx].description,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
        );
      },
    );
  }
}
