import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';

import '../utils/utils.dart';

enum MessageRole { user, assistant }

class Message {
  MessageRole role;
  String body;
  String? attachedFile;

  Message({
    required this.role,
    required this.body,
    this.attachedFile,
  });

  @override
  String toString() => 'Message(role: ${role.name}, body: $body)';
}

extension LlmMessageExt on List<Message> {
  Future<List<Content>> toGeminiMessages() async {
    final List<Content> content = <Content>[];
    for (final Message message in this) {
      if (message.role == MessageRole.user) {
        content.add(
          Content.text(
            '${message.body}${(message.attachedFile != null && message != last) ? '\n${message.attachedFile}' : ''}',
          ),
        );
        if (message.attachedFile != null && message == last) {
          content.add(
            Content.data(
              Utils.getMimeType(message.attachedFile!),
              await Utils.getBytesFromFile(message.attachedFile!),
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
        final bool hasAttachedFile =
            message.attachedFile != null && message == last;
        String? base64File;
        String? mimeType;
        if (hasAttachedFile) {
          final File file = File(message.attachedFile!);
          if (await file.exists()) {
            final List<int> fileBytes = await file.readAsBytes();
            base64File = base64Encode(fileBytes);
            mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
          }
        }
        messages.add(<String, dynamic>{
          'role': 'user',
          'content': <Map<String, dynamic>>[
            <String, String>{
              'type': 'text',
              'text':
                  '${message.body}${message.attachedFile != null && message != last ? '\n${message.attachedFile}' : ''}',
            },
            if (hasAttachedFile)
              <String, dynamic>{
                'type': 'image_url',
                'image_url': <String, String>{
                  'url': 'data:$mimeType;base64,$base64File',
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
