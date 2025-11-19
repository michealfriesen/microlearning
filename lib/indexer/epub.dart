// ignore_for_file: unused_local_variable

import 'dart:core';
import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:microlearning/prompts/prompts.dart';

void main() async {
  var fileName = "/Users/glassjack/Downloads/Learn_Haskell_by_Example_v14.epub";
  var targetFile = io.File(fileName);

  var content = await targetFile.readAsBytes();

  var book = await EpubReader.readBook(content);
  // either deepseek-r1:14b or gemma3:4b
  final client = Prompter.withModel('gemma3:4b');
  final chapters = await client.findChapterNames(book);

  print(book.title);
  print(book.author);
  print(chapters);
}
