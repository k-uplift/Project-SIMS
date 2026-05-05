class Recipe {
  final String id;
  final String title;
  final String time;
  final String description;
  final List<String> ownedIngredients;
  final List<String> missingIngredients;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.ownedIngredients,
    required this.missingIngredients,
    required this.steps,
  });
}