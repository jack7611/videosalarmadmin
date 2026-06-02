class RecentFile {
  final String? name;
  final String date;

  RecentFile({this.name, required this.date});
}

// Sample data representing user joins with their join dates
List<RecentFile> demoRecentFiles = [
  RecentFile(name: "John Doe", date: "01-03-2021"),
  RecentFile(name: "Jane Smith", date: "27-02-2021"),
  RecentFile(name: "Alice Brown", date: "23-02-2021"),
  RecentFile(name: "Bob White", date: "23-02-2021"),
  RecentFile(name: "Charlie Green", date: "25-02-2021"),
  RecentFile(name: "Daisy Blue", date: "25-02-2021"),
];
