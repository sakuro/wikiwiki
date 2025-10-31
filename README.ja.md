# Wikiwiki

{file:README.md English version}

[Wikiwiki](https://wikiwiki.jp/) REST API用のRubyクライアントライブラリです。

## 概要

このgemは、Wikiwikiのwikiをプログラムから操作するためのシンプルなインターフェースを提供します。ページ操作（一覧取得、読み取り、書き込み）と添付ファイル管理（一覧取得、アップロード、ダウンロード、削除）をサポートしています。

## インストール

アプリケーションのGemfileに以下の行を追加してください：

```ruby
gem "wikiwiki"
```

その後、以下を実行してください：

```bash
bundle install
```

または、直接インストールすることもできます：

```bash
gem install wikiwiki
```

## 認証

APIを使用する前に、wikiの管理画面でREST APIアクセスを有効にしてください。

### パスワード認証

```ruby
auth = Wikiwiki::Auth.password(password: "your_admin_password")
```

### APIキー認証

```ruby
auth = Wikiwiki::Auth.api_key(api_key_id: "your_api_key_id", secret: "your_secret")
```

## 使い方

### 基本的な使用例

```ruby
require "wikiwiki"

# 認証情報を使って初期化
auth = Wikiwiki::Auth.password(password: "admin_password")
wiki = Wikiwiki::Wiki.new(wiki_id: "your-wiki-id", auth:)

# すべてのページ名の一覧を取得
page_names = wiki.page_names
# => ["FrontPage", "SideBar", ...]

# ページを取得
page = wiki.page(page_name: "FrontPage")
puts page.source
puts page.timestamp

# ページを更新
wiki.update_page(page_name: "TestPage", source: <<~SOURCE)
  TITLE:Test
  # Hello World
SOURCE

# 添付ファイル名の一覧を取得
attachment_names = wiki.attachment_names(page_name: "FrontPage")

# 添付ファイルをダウンロード
attachment = wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png")
File.binwrite("logo.png", attachment.content)
# 注意: attachment.nameをファイル名として使用する場合は、ディレクトリトラバーサル攻撃を防ぐために安全性を検証してください

# 添付ファイルをアップロード
content = File.binread("image.png")
wiki.add_attachment(page_name: "FrontPage", attachment_name: "image.png", content:)

# 添付ファイルを削除
wiki.delete_attachment(page_name: "FrontPage", attachment_name: "image.png")
```

## リファレンス

- [ページ操作API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/1)
- [ファイル操作API](https://z.wikiwiki.jp/wikiwiki-rest-api/topic/3)

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件の下でオープンソースとして利用可能です。
