/// Builds the link that ROCIs Tasks understands (`rocistasks://add_task`): it opens the
/// Add Task screen prefilled, so no account or server is involved.
Uri buildTasksUri(String title, List<String> lines) => Uri(
  scheme: 'rocistasks',
  host: 'add_task',
  queryParameters: {
    'title': title,
    'notes': lines.map((l) => '- $l').join('\n'),
  },
);
