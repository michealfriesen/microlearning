// Make API call with chunk to build review questions

// Potentially compare notes to determine missed content

import 'dart:convert' show jsonDecode;
import 'dart:core';
import 'package:ollama_dart/ollama_dart.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:html2md/html2md.dart' as html2md;

class Chapters {
  String tableOfContents;
  List<String> contentChapters;

  Chapters({required this.tableOfContents, required this.contentChapters});

  factory Chapters.fromJson(Map<String, dynamic> json) {
    return Chapters(
      tableOfContents: json['table of contents'] as String,
      contentChapters: json['chapters'] as List<String>,
    );
  }
}

class Prompter {
  final OllamaClient _client;
  final String _modelName;

  Prompter.withModel(String name) : _client = OllamaClient(), _modelName = name;

  Future<Chapters> findChapterNames(EpubBook book) async {
    final chapterTitles = book.chapters
        .where((chapter) => chapter.title != null)
        .map((chapter) => chapter.title!)
        .fold("", (acc, val) => "$acc\n$val");

    final rsp = await _client.generateChatCompletion(
      request: GenerateChatCompletionRequest(
        model: _modelName,
        messages: [
          Message(
            role: MessageRole.system,
            content: """
You are a book comprehension assistant. You're responsibility is
to accurately extract information as accurately as possible.

The user will provide a line delimeted list of chapter titles. Extract out
the numbered chapters and the table of contents chapter into a json
object.

example input format:
```
forward
acknowledgments
table of contents
1 The Meaning of Life
2 How to Use This Information
appendix
```

example output format:
```
{
	"table of contents": "Table of Contents"
	"chapters": [
		"1 The Meaning of Life",
		"2 How to Use This Information"
	]
}
```

The table of contents chapter may not literally be called table of contents.
Try to infer which one of the chapters would be most likely to be the
table of contents. They are typically before any actual content in the book
but after the title page & legal descriptions

Example chapter names for table of contents are
* Contents
* Table
* TOC
* Table of Contents 

Chapters that have content in them typically are numbered and are descriptive. They are the
most numerous and are in the middle between the table of contents chapter and
the appendix/index. There are typically more content chapters than non content chapters

Example content chapter name formats are
* Example Chapter Name
* 1 Example Chapter Name
* 1. Example Chapter Name
* 1 - Example Chapter Name
* I. Example Chapter Name

Chapter names may come in mixed casing formats. Preserve the exact name & format in the output.

Use the next message as input
""",
          ),
          Message(role: MessageRole.user, content: chapterTitles),
        ],
      ),
    );

    print(rsp.message.content);

    return Chapters.fromJson(
      jsonDecode(rsp.message.content) as Map<String, dynamic>,
    );
  }
}
