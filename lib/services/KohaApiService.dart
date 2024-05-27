import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_response.dart';
import 'package:alburhaan/models/BookDetail.dart';

class KohaApiService {
  final String baseUrl = "https://library.al-burhaan.org/api/v1/";
  final String username = 'Alburhaan';
  final String password = 'H1b1scus_16';

  Future<List<BookResponse>> fetchBooks(int page, {String? query}) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    String url = "${baseUrl}biblios?_page=$page&_per_page=10";
    if (query != null && query.isNotEmpty) {
      var queryJson = jsonEncode({"title": {"-like": "%$query%"}});
      url += "&q=${Uri.encodeComponent(queryJson)}";
    }
    var response = await http.get(Uri.parse(url), headers: {
      'Authorization': basicAuth,
      'Accept': 'application/json; charset=utf-8'
    });

    print("Requesting URL: $url");
    if (response.statusCode == 200) {
      List<dynamic> booksJson = jsonDecode(utf8.decode(response.bodyBytes));
      return booksJson.map((data) => BookResponse.fromJson(data)).toList();
    } else {
      print("Failed to fetch books. Status code: ${response.statusCode}, Response: ${response.body}");
      throw Exception('Failed to load books. Status code: ${response.statusCode}');
    }
  }

  Future<BookDetail> fetchBookDetail(int biblioId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    String url = "$baseUrl/biblios/$biblioId";

    var response = await http.get(Uri.parse(url), headers: {
      'Authorization': basicAuth,
      'Accept': 'application/json; charset=utf-8'
    });

    if (response.statusCode == 200) {
      var decodedData = utf8.decode(response.bodyBytes);
      var jsonData = json.decode(decodedData);

      // Fetch items for the biblio to get shelving location and holdings
      var itemsResponse = await fetchBiblioItems(biblioId);
      String? shelvingLocation = itemsResponse.isNotEmpty ? itemsResponse[0]['location'] : null;

      return BookDetail.fromJson({
        ...jsonData,
        'shelving_location': shelvingLocation,
        'holdings': itemsResponse,
      });
    } else {
      throw Exception('Failed to load book detail. Status code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBiblioItems(int biblioId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    String url = "$baseUrl/biblios/$biblioId/items";

    var response = await http.get(Uri.parse(url), headers: {
      'Authorization': basicAuth,
      'Accept': 'application/json; charset=utf-8'
    });

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load biblio items. Status code: ${response.statusCode}');
    }
  }
}
