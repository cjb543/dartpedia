import 'package:cli/cli.dart' as cli;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:command_runner/command_runner.dart';
import 'package:cli/cli.dart';
import 'package:command_runner/command_runner.dart';

const version = '0.1.1';

void main(List<String> arguments) async {
  final errorLogger = initFileLogger('errors');
  final app =
      CommandRunner(
          onOutput: (String output) async {
            await write(output);
          },
          onError: (Object error) {
            if (error is Error) {
              errorLogger.severe(
                '[Error] ${error.toString()}\n${error.stackTrace}',
              );
              throw error;
            }
            if (error is Exception) {
              errorLogger.warning(error);
            }
          },
        )
        ..addCommand(HelpCommand())
        ..addCommand(SearchCommand(logger: errorLogger))
        ..addCommand(GetArticleCommand(logger: errorLogger));

  await app.run(arguments);
}


void searchWikipedia(List<String>? arguments) async {
  final String articleTitle;

  if (arguments == null || arguments.isEmpty){
    print('Please provide an article title');
    final inputFromStdin = stdin.readLineSync(); // read input
    if (inputFromStdin == null || inputFromStdin.isEmpty){
      print("No article title provided. Exiting");
      return;
    }
    articleTitle = inputFromStdin;
  } else {
    articleTitle = arguments.join(' ');
  }

  print('Looking up articles about "$articleTitle", Please wait.');
  
  // Call API
  var articleContent = await getWikipediaArticle(articleTitle);
  print(articleContent);
}


void printUsage(){
  print(
  "The following commands are valid: 'help', 'version', 'search <ARTICLE-TITLE>' "
  );
}


Future<String> getWikipediaArticle(String articleTitle) async {
  final url = Uri.https(
    'en.wikipedia.org',
    '/api/rest_v1/page/summary/$articleTitle',
  );
  final response = await http.get(url); // Make the HTTP request

  if (response.statusCode == 200) {
    return response.body; // Return the response body if successful
  }

  // Return an error message if the request failed
  return 'Error: Failed to fetch article "$articleTitle". Status code: ${response.statusCode}';
}

