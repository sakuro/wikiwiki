# Wikiwiki

{file:README.md English version}

[Wikiwiki](https://wikiwiki.jp/) REST API用のRubyクライアントライブラリおよびコマンドラインツールです。

## 概要

このgemは、Wikiwikiのwikiを操作するためのRubyライブラリとCLIツールの両方を提供します。

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

### トークン認証

事前に認証して得られたJWTトークンは、有効期限以内なら再利用できます：

```ruby
auth = Wikiwiki::Auth.token(token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
```

## 使い方

### コマンドラインインターフェース

`wikiwiki`コマンドで、すべてのAPI操作にアクセスできます：

```bash
# 環境変数で認証情報を設定（オプション）
export WIKIWIKI_WIKI_ID=your-wiki-id
export WIKIWIKI_PASSWORD=your-password
# または
export WIKIWIKI_API_KEY_ID=your-api-key-id
export WIKIWIKI_SECRET=your-secret
# または事前に取得したトークンを使用
export WIKIWIKI_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 後で使用するためにトークンを取得
wikiwiki auth --wiki-id=your-wiki-id --password=your-password
# またはexportと組み合わせて使用
export WIKIWIKI_TOKEN=$(wikiwiki auth --wiki-id=your-wiki-id --password=your-password)

# ページ一覧
wikiwiki page list

# ページのメタデータ表示
wikiwiki page show FrontPage

# ページのコンテンツをダウンロード
wikiwiki page get FrontPage
wikiwiki page get FrontPage frontpage.txt

# ページをアップロード/更新（標準入力またはファイルから）
wikiwiki page put TestPage < content.txt
wikiwiki page put TestPage content.txt

# 添付ファイル一覧
wikiwiki attachment list FrontPage

# 添付ファイルのメタデータ表示
wikiwiki attachment show FrontPage logo.png

# 添付ファイルをダウンロード
wikiwiki attachment get FrontPage logo.png
wikiwiki attachment get FrontPage logo.png --directory downloads/

# 添付ファイルをアップロード（最大512 KiB）
wikiwiki attachment put FrontPage image.png
wikiwiki attachment put FrontPage local.png --name remote.png

# 添付ファイルを削除
wikiwiki attachment delete FrontPage logo.png

# 既存のファイル/添付ファイルを上書きするには --force を使用
wikiwiki page get FrontPage existing.txt --force
wikiwiki attachment put FrontPage logo.png --force

# 注意: --force による添付ファイルの上書きはアトミックではありません。
# 既存の添付ファイルを削除してから新しいファイルをアップロードします。
# アップロードに失敗した場合、添付ファイルは失われます。

# コマンドラインで認証情報を指定（環境変数より優先）
wikiwiki --wiki-id=your-wiki-id --password=your-password page list
wikiwiki --wiki-id=your-wiki-id --api-key-id=id --secret=secret page list
wikiwiki --wiki-id=your-wiki-id --token=eyJ... page list

# 自動化のためのJSON出力
wikiwiki page list --json
wikiwiki attachment show FrontPage logo.png --json

# 詳細モードとデバッグモード
wikiwiki page list --verbose
wikiwiki page list --debug
```

### Rubyライブラリ

ライブラリを使用する基本的な例：

```ruby
require "wikiwiki"

# 認証情報を使って初期化
auth = Wikiwiki::Auth.password(password: "admin_password")
wiki = Wikiwiki::Wiki.new(wiki_id: "your-wiki-id", auth:)

# 認証トークンを取得して再利用
token = wiki.token
# トークンを保存して後で使用...

# 後で保存したトークンを使用
auth = Wikiwiki::Auth.token(token: token)
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
