/// What happened to a cart or invoice after a tap on a line.
enum LineChange {
  /// The line was added or its quantity changed.
  updated,

  /// The quantity went to zero, so the line was removed.
  removed,

  /// Refused: the warehouse doesn't have that many.
  overStock,
}
