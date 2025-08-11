class DuetSource {
  final Uri uri;
  const DuetSource(this.uri);

  factory DuetSource.filePath(String path) => DuetSource(Uri.file(path));
  factory DuetSource.network(String url) => DuetSource(Uri.parse(url));
}
