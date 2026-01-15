import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EducationalResources extends StatefulWidget {
  const EducationalResources({super.key});

  @override
  _EducationalResourcesState createState() => _EducationalResourcesState();
}

class _EducationalResourcesState extends State<EducationalResources> {
  List<Map<String, String>> articles = [];

  @override
  void initState() {
    super.initState();
    fetchMediumArticles(); // Fetch articles from Medium on initialization
  }

  Future<void> fetchMediumArticles() async {
    final url = Uri.parse(
        'https://api.rss2json.com/v1/api.json?rss_url=https://medium.com/feed/@dreammendapp');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items =
            data['items']; // Explicitly declare as List<dynamic>

        setState(() {
          articles = items.map((article) {
            String rawDescription = article['description']?.toString() ?? '';
            rawDescription = rawDescription.replaceAll(RegExp(r'</?(strong|b|em|i|u)>'), '');
            var description = RegExp(r'<p>(.*?)<\/p>')
              .firstMatch(rawDescription)
              ?.group(1) ?? '';

            var image = RegExp(r'<img[^>]*src="(.*?)"')
              .firstMatch(article['description']?.toString() ?? '')
              ?.group(1) ?? '';

            print("image: $image");

            return {
              'title': article['title']?.toString() ?? '',
              'description': description, // Remove HTML tags
              'image': image, // Extract image URL
              'date': (article['pubDate']?.toString() ?? '')
                  .split(' ')[0], // Ensure string format
              'readTime': 'short read', // Placeholder read time
              'url': article['link']?.toString() ?? '',
            };
          }).toList(); // No need for .cast<Map<String, String>>()
        });
      }
    } catch (e) {
      print('Error fetching Medium articles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.educationalResources),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.educationalResourcesWelcome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.educationalResourcesDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.educationalResourcesMediumTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (articles
                .isEmpty) // Show a loading indicator if articles are not yet fetched
              const Center(child: CircularProgressIndicator()),
            for (var article in articles) // Dynamically generate article cards
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ArticleCard(
                  title: article['title']!,
                  description: article['description']!,
                  imageAsset: article['image']!,
                  date: article['date']!,
                  readTime: article['readTime']!,
                  url: article['url']!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;
  final String date;
  final String readTime;
  final String url;

  const ArticleCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.date,
    required this.readTime,
    required this.url,
  });

  void _openUrl(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri,
            mode: url_launcher.LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.educationalResourcesCannotOpenUrl),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(AppLocalizations.of(context)!.educationalResourcesUnableToOpen),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.educationalResourcesCopyUrlBelow),
                      const SizedBox(height: 8),
                      SelectableText(url),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.educationalResourcesCopyUrl),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.educationalResourcesUrlCopied),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.educationalResourcesClose),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openUrl(context),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageAsset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                          child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                          ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('$readTime • $date',
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
