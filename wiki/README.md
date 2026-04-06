# Offline Wiki Snapshots

この `wiki/` 配下には、Notion / Confluence のコンテンツを **一度だけエクスポートして保存したスナップショット**を配置します。

- Notion: `wiki/notion/`
- Confluence: `wiki/confluence/`

エージェントは `mcp/config.json` の `notion_snapshots` / `confluence_snapshots`（ローカル filesystem）を通じて、このディレクトリ内のファイルを参照します。

