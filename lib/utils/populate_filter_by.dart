String populateFilterBy(Map<String, Set<String>> filterState) {
  final filterItems = [];
  filterState.forEach((key, value) {
    if (value.isNotEmpty) {
      filterItems.add('$key:=[${value.join(',')}]');
    }
  });
  return filterItems.join(' && ');
}
