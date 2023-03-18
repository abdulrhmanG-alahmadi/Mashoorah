import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

const String customerId = 'your_customer_id';
const String xApiKey = 'your_api_key';
const String baseUrl = 'https://experimental.willow.vectara.io/v1';

Future<Response> financialAdvice(Request request) async {
  if (request.method != 'POST') {
    return Response(HttpStatus.methodNotAllowed, body: 'Invalid method');
  }

  final requestData = await request.readAsString();
  final data = json.decode(requestData);
  final userPoints = data['user_points'];
  final csvData = data['csv_data'];

  final prompt = '''As a great financial advisor, here are the data points provided:

$csvData

Find the best diversification to have the highest Sharpe ratio possible, and give a recommendation.''';

  final chatUrl = '$baseUrl/chat/completions';
  final headers = {
    'Content-Type': 'application/json',
    'customer-id': customerId,
    'x-api-key': xApiKey
  };
  final chatData = {
    'model': 'gpt-3.5-turbo',
    'messages': [{'role': 'user', 'content': prompt}]
  };

  final response = await http.post(Uri.parse(chatUrl),
      headers: headers, body: json.encode(chatData));

  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    final message = result['choices'][0]['message']['content'];
    return Response.ok(json.encode({'response': message}),
        headers: {'Content-Type': 'application/json'});
  } else {
    return Response.internalServerError(
        body: json.encode({'error': 'Failed to get a response from the GPT API.'}),
        headers: {'Content-Type': 'application/json'});
  }
}

void main() async {
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(financialAdvice);

  final server = await io.serve(handler, 'localhost', 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}