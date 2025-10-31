# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Wikiwiki::API do
  let(:wiki_id) { "test-wiki" }

  describe "#initialize" do
    context "with password-based authentication" do
      let(:auth) { Wikiwiki::Auth.password(password: "admin_password") }

      context "when authentication succeeds" do
        before do
          stub_request(:post, "https://api.wikiwiki.jp/test-wiki/auth")
            .with(
              body: {password: "admin_password"}.to_json,
              headers: {"Content-Type" => "application/json"}
            )
            .to_return(status: 200, body: <<~JSON)
              {"status":"ok","token":"jwt_token_123"}
            JSON
        end

        it "authenticates and stores JWT token internally" do
          api = Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit)
          expect(api.__send__(:token)).to eq("jwt_token_123")
        end
      end

      context "when authentication fails" do
        before do
          stub_request(:post, "https://api.wikiwiki.jp/test-wiki/auth")
            .with(
              body: {password: "admin_password"}.to_json,
              headers: {"Content-Type" => "application/json"}
            )
            .to_return(status: [401, "Unauthorized"])
        end

        it "raises Wikiwiki::AuthenticationError" do
          expect { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }.to raise_error(Wikiwiki::AuthenticationError, "API request failed: 401 Unauthorized")
        end
      end
    end

    context "with API key-based authentication" do
      let(:auth) { Wikiwiki::Auth.api_key(api_key_id: "api_key_123", secret: "secret_456") }

      context "when authentication succeeds" do
        before do
          stub_request(:post, "https://api.wikiwiki.jp/test-wiki/auth")
            .with(
              body: {api_key_id: "api_key_123", secret: "secret_456"}.to_json,
              headers: {"Content-Type" => "application/json"}
            )
            .to_return(status: 200, body: <<~JSON)
              {"status":"ok","token":"jwt_token_789"}
            JSON
        end

        it "authenticates and stores JWT token internally" do
          api = Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit)
          expect(api.__send__(:token)).to eq("jwt_token_789")
        end
      end

      context "when authentication fails" do
        before do
          stub_request(:post, "https://api.wikiwiki.jp/test-wiki/auth")
            .with(
              body: {api_key_id: "api_key_123", secret: "secret_456"}.to_json,
              headers: {"Content-Type" => "application/json"}
            )
            .to_return(status: [401, "Unauthorized"])
        end

        it "raises Wikiwiki::AuthenticationError" do
          expect { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }.to raise_error(Wikiwiki::AuthenticationError, "API request failed: 401 Unauthorized")
        end
      end
    end
  end

  describe "with authenticated API instance" do
    let(:auth) { Wikiwiki::Auth.password(password: "test_password") }
    let(:api) { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }

    before do
      stub_request(:post, "https://api.wikiwiki.jp/test-wiki/auth")
        .with(
          body: {password: "test_password"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
        .to_return(status: 200, body: <<~JSON)
          {"status":"ok","token":"jwt_token_123"}
        JSON
    end

    describe "#get_pages" do
      context "when request succeeds" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "pages": [
                  {"name": "FrontPage", "timestamp": "2022-01-01T00:00:00+09:00"},
                  {"name": "SideBar", "timestamp": "2022-01-02T00:00:00+09:00"}
                ]
              }
            JSON
        end

        it "returns hash with pages array" do
          result = api.get_pages
          expect(result).to eq({
            "pages" => [
              {"name" => "FrontPage", "timestamp" => "2022-01-01T00:00:00+09:00"},
              {"name" => "SideBar", "timestamp" => "2022-01-02T00:00:00+09:00"}
            ]
          })
        end

        it "sends GET request to /pages endpoint with Bearer token" do
          api.get_pages
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when request fails" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [404, "Not Found"])
        end

        it "raises Wikiwiki::ResourceNotFoundError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [401, "Unauthorized"])
        end

        it "raises Wikiwiki::AuthenticationError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::AuthenticationError, "API request failed: 401 Unauthorized")
        end
      end

      context "when server returns 500 error" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [500, "Internal Server Error"])
        end

        it "raises Wikiwiki::ServerError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::ServerError, "API request failed: 500 Internal Server Error")
        end
      end

      context "when server returns 503 error" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [503, "Service Unavailable"])
        end

        it "raises Wikiwiki::ServerError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::ServerError, "API request failed: 503 Service Unavailable")
        end
      end

      context "when server returns 400 error" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [400, "Bad Request"])
        end

        it "raises Wikiwiki::APIError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::APIError, "API request failed: 400 Bad Request")
        end
      end

      context "when server returns 429 error" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/pages")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [429, "Too Many Requests"])
        end

        it "raises Wikiwiki::APIError" do
          expect { api.get_pages }.to raise_error(Wikiwiki::APIError, "API request failed: 429 Too Many Requests")
        end
      end
    end

    describe "#get_page" do
      context "when request succeeds" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "FrontPage",
                "source": "TITLE:FrontPage\\n* Welcome",
                "timestamp": "2022-01-01T00:00:00+09:00"
              }
            JSON
        end

        it "returns hash with page details" do
          result = api.get_page(encoded_page_name: "FrontPage")
          expect(result).to eq({
            "page" => "FrontPage",
            "source" => "TITLE:FrontPage\n* Welcome",
            "timestamp" => "2022-01-01T00:00:00+09:00"
          })
        end

        it "sends GET request to /page/:page_name endpoint with Bearer token" do
          api.get_page(encoded_page_name: "FrontPage")
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when page name is URL-encoded" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/Test%20Page")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "Test Page",
                "source": "TITLE:Test Page",
                "timestamp": "2022-01-01T00:00:00+09:00"
              }
            JSON
        end

        it "constructs request path with encoded page name" do
          api.get_page(encoded_page_name: "Test%20Page")
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/Test%20Page")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when page name is URL-encoded with Japanese characters" do
        let(:encoded_name) { "%E3%83%86%E3%82%B9%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8" }

        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/#{encoded_name}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "テストページ",
                "source": "TITLE:テストページ",
                "timestamp": "2022-01-01T00:00:00+09:00"
              }
            JSON
        end

        it "constructs request path with encoded Japanese page name" do
          api.get_page(encoded_page_name: encoded_name)
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/#{encoded_name}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when request fails" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/NonExistent")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [404, "Not Found"])
        end

        it "raises Wikiwiki::ResourceNotFoundError" do
          expect { api.get_page(encoded_page_name: "NonExistent") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: [401, "Unauthorized"])
        end

        it "raises Wikiwiki::AuthenticationError" do
          expect { api.get_page(encoded_page_name: "FrontPage") }.to raise_error(Wikiwiki::AuthenticationError, "API request failed: 401 Unauthorized")
        end
      end
    end

    describe "#put_page" do
      context "when request succeeds" do
        before do
          stub_request(:put, "https://api.wikiwiki.jp/test-wiki/page/TestPage")
            .with(
              body: {source: "TITLE:Test\n# Content"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: 200, body: <<~JSON)
              {"status":"ok"}
            JSON
        end

        it "returns hash with status ok" do
          result = api.put_page(encoded_page_name: "TestPage", source: "TITLE:Test\n# Content")
          expect(result).to eq({"status" => "ok"})
        end

        it "sends PUT request to /page/:page_name endpoint with Bearer token and source" do
          api.put_page(encoded_page_name: "TestPage", source: "TITLE:Test\n# Content")
          expect(a_request(:put, "https://api.wikiwiki.jp/test-wiki/page/TestPage")
            .with(
              body: {source: "TITLE:Test\n# Content"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )).to have_been_made.once
        end
      end

      context "when request fails" do
        before do
          stub_request(:put, "https://api.wikiwiki.jp/test-wiki/page/NonExistent")
            .with(
              body: {source: "content"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: [404, "Not Found"])
        end

        it "raises Wikiwiki::ResourceNotFoundError" do
          expect { api.put_page(encoded_page_name: "NonExistent", source: "content") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        before do
          stub_request(:put, "https://api.wikiwiki.jp/test-wiki/page/TestPage")
            .with(
              body: {source: "content"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: [401, "Unauthorized"])
        end

        it "raises Wikiwiki::AuthenticationError" do
          expect { api.put_page(encoded_page_name: "TestPage", source: "content") }.to raise_error(Wikiwiki::AuthenticationError, "API request failed: 401 Unauthorized")
        end
      end
    end

    describe "#get_attachments" do
      context "when request succeeds" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachments")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "attachments": {
                  "logo.png": {
                    "page": "FrontPage",
                    "file": "logo.png",
                    "size": 12345
                  }
                }
              }
            JSON
        end

        it "returns hash with attachments" do
          result = api.get_attachments(encoded_page_name: "FrontPage")
          expect(result["attachments"]).to have_key("logo.png")
        end
      end
    end

    describe "#get_attachment" do
      context "when request succeeds" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/logo.png")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "FrontPage",
                "file": "logo.png",
                "src": "base64data"
              }
            JSON
        end

        it "returns file info with src data" do
          result = api.get_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
          expect(result["file"]).to eq("logo.png")
          expect(result["src"]).to eq("base64data")
        end
      end

      context "when attachment name is URL-encoded" do
        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/test%20file.png")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "FrontPage",
                "file": "test file.png",
                "src": "base64data"
              }
            JSON
        end

        it "constructs request path with encoded attachment name" do
          api.get_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "test%20file.png")
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/test%20file.png")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when page and attachment names are URL-encoded with Japanese characters" do
        let(:encoded_page) { "%E3%83%86%E3%82%B9%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8" }
        let(:encoded_file) { "%E7%94%BB%E5%83%8F.png" }

        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/#{encoded_page}/attachment/#{encoded_file}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "テストページ",
                "file": "画像.png",
                "src": "base64data"
              }
            JSON
        end

        it "constructs request path with encoded page and attachment names" do
          api.get_attachment(encoded_page_name: encoded_page, encoded_attachment_name: encoded_file)
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/#{encoded_page}/attachment/#{encoded_file}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end

      context "when rev parameter is specified" do
        let(:rev_hash) { "abc123def456" }

        before do
          stub_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/logo.png?rev=#{rev_hash}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {
                "page": "FrontPage",
                "file": "logo.png",
                "src": "base64data"
              }
            JSON
        end

        it "includes rev query parameter in request" do
          api.get_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png", rev: rev_hash)
          expect(a_request(:get, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/logo.png?rev=#{rev_hash}")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})).to have_been_made.once
        end
      end
    end

    describe "#put_attachment" do
      context "when request succeeds" do
        before do
          stub_request(:put, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment")
            .with(
              body: {filename: "logo.png", data: "base64data"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: 200, body: <<~JSON)
              {"status":"ok"}
            JSON
        end

        it "returns hash with status ok" do
          result = api.put_attachment(encoded_page_name: "FrontPage", attachment_name: "logo.png", encoded_content: "base64data")
          expect(result).to eq({"status" => "ok"})
        end
      end

      context "when file already exists" do
        before do
          stub_request(:put, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment")
            .with(
              body: {filename: "existing.png", data: "base64data"}.to_json,
              headers: {
                "Authorization" => "Bearer jwt_token_123",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: [409, "Conflict"])
        end

        it "raises Wikiwiki::APIError" do
          expect {
            api.put_attachment(encoded_page_name: "FrontPage", attachment_name: "existing.png", encoded_content: "base64data")
          }.to raise_error(Wikiwiki::APIError, "API request failed: 409 Conflict")
        end
      end
    end

    describe "#delete_attachment" do
      context "when request succeeds" do
        before do
          stub_request(:delete, "https://api.wikiwiki.jp/test-wiki/page/FrontPage/attachment/logo.png")
            .with(headers: {"Authorization" => "Bearer jwt_token_123"})
            .to_return(status: 200, body: <<~JSON)
              {"status":"ok"}
            JSON
        end

        it "returns hash with status ok" do
          result = api.delete_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
          expect(result).to eq({"status" => "ok"})
        end
      end
    end
  end
end
