import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../utils/utils.dart';

enum MessageRole { user, assistant }

class Message {
  MessageRole role;
  String body;
  String? attachedImage;

  Message({
    required this.role,
    required this.body,
    this.attachedImage,
  });
}

extension LlmMessageExt on List<Message> {
  Future<List<Content>> toGeminiMessages() async {
    final List<Content> content = <Content>[];
    for (final Message message in this) {
      if (message.role == MessageRole.user) {
        content.add(
          Content.text(
            '${message.body}${(message.attachedImage != null && message != last) ? '\n${message.attachedImage}' : ''}',
          ),
        );
        if (message.attachedImage != null && message == last) {
          content.add(
            Content.data(
              Utils.getMimeType(message.attachedImage!),
              await Utils.getBytesFromFile(message.attachedImage!),
            ),
          );
        }
      } else {
        content.add(Content.model(<Part>[TextPart(message.body)]));
      }
    }
    return content;
  }

  Future<List<Map<String, dynamic>>> toOpenAiMessages() async {
    final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];
    for (final Message message in this) {
      if (message.role == MessageRole.user) {
        final bool attachImage =
            message.attachedImage != null && message == last;
        String? base64Image;
        if (attachImage) {
          final File imageFile = File(message.attachedImage!);
          if (await imageFile.exists()) {
            final List<int> imageBytes = await imageFile.readAsBytes();
            base64Image = base64Encode(imageBytes);
          }
        }
        messages.add(<String, dynamic>{
          'role': 'user',
          'content': <Map<String, dynamic>>[
            <String, String>{
              'type': 'text',
              'text':
                  '${message.body}${message.attachedImage != null && message != last ? '\n${message.attachedImage}' : ''}',
            },
            if (attachImage)
              <String, dynamic>{
                'type': 'image_url',
                'image_url': <String, String>{
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
          ],
        });
      } else {
        messages.add(<String, dynamic>{
          'role': 'assistant',
          'content': message.body,
        });
      }
    }
    return messages;
  }
}
