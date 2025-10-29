# frozen_string_literal: true

RSpec.describe Wikiwiki::API do
  let(:wiki_id) { "test-wiki" }
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=).with(true)
  end

  describe "#initialize" do
    context "with password-based authentication" do
      let(:auth) { Wikiwiki::Auth.password("admin_password") }

      context "when authentication succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {"status":"ok","token":"jwt_token_123"}
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "authenticates and stores JWT token internally" do
          api = Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit)
          expect(api.__send__(:token)).to eq("jwt_token_123")
        end
      end

      context "when authentication fails" do
        let(:failed_response) { instance_double(Net::HTTPUnauthorized) }

        before do
          allow(http).to receive(:request).and_return(failed_response)
          allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(failed_response).to receive_messages(code: "401", message: "Unauthorized")
        end

        it "raises Wikiwiki::Error" do
          expect { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }.to raise_error(Wikiwiki::Error, "API request failed: 401 Unauthorized")
        end
      end
    end

    context "with API key-based authentication" do
      let(:auth) { Wikiwiki::Auth.api_key("api_key_123", "secret_456") }

      context "when authentication succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {"status":"ok","token":"jwt_token_789"}
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "authenticates and stores JWT token internally" do
          api = Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit)
          expect(api.__send__(:token)).to eq("jwt_token_789")
        end
      end

      context "when authentication fails" do
        let(:failed_response) { instance_double(Net::HTTPUnauthorized) }

        before do
          allow(http).to receive(:request).and_return(failed_response)
          allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(failed_response).to receive_messages(code: "401", message: "Unauthorized")
        end

        it "raises Wikiwiki::Error" do
          expect { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }.to raise_error(Wikiwiki::Error, "API request failed: 401 Unauthorized")
        end
      end
    end
  end

  describe "with authenticated API instance" do
    let(:auth) { Wikiwiki::Auth.password("test_password") }
    let(:auth_response) { instance_double(Net::HTTPSuccess) }
    let(:api) { Wikiwiki::API.new(wiki_id:, auth:, rate_limiter: Wikiwiki::RateLimiter.no_limit) }

    before do
      allow(auth_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(auth_response).to receive(:body).and_return(<<~JSON)
        {"status":"ok","token":"jwt_token_123"}
      JSON
    end

    describe "#get_pages" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "pages": [
                {"name": "FrontPage", "timestamp": "2022-01-01T00:00:00+09:00"},
                {"name": "SideBar", "timestamp": "2022-01-02T00:00:00+09:00"}
              ]
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
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
          request = instance_double(Net::HTTP::Get)
          allow(Net::HTTP::Get).to receive(:new).with("/test-wiki/pages").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_pages

          expect(Net::HTTP::Get).to have_received(:new).with("/test-wiki/pages")
          expect(request).to have_received(:[]=).with("Authorization", "Bearer jwt_token_123")
        end
      end

      context "when request fails" do
        let(:failed_response) { instance_double(Net::HTTPNotFound) }

        before do
          allow(http).to receive(:request).and_return(auth_response, failed_response)
          allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(failed_response).to receive_messages(code: "404", message: "Not Found")
        end

        it "raises Wikiwiki::Error" do
          expect { api.get_pages }.to raise_error(Wikiwiki::Error, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        let(:unauthorized_response) { instance_double(Net::HTTPUnauthorized) }

        before do
          allow(http).to receive(:request).and_return(auth_response, unauthorized_response)
          allow(unauthorized_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(unauthorized_response).to receive_messages(code: "401", message: "Unauthorized")
        end

        it "raises Wikiwiki::Error" do
          expect { api.get_pages }.to raise_error(Wikiwiki::Error, "API request failed: 401 Unauthorized")
        end
      end
    end

    describe "#get_page" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "FrontPage",
              "source": "TITLE:FrontPage\\n* Welcome",
              "timestamp": "2022-01-01T00:00:00+09:00"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
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
          request = instance_double(Net::HTTP::Get)
          allow(Net::HTTP::Get).to receive(:new).with("/test-wiki/page/FrontPage").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_page(encoded_page_name: "FrontPage")

          expect(Net::HTTP::Get).to have_received(:new).with("/test-wiki/page/FrontPage")
          expect(request).to have_received(:[]=).with("Authorization", "Bearer jwt_token_123")
        end
      end

      context "when page name is URL-encoded" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "Test Page",
              "source": "TITLE:Test Page",
              "timestamp": "2022-01-01T00:00:00+09:00"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "constructs request path with encoded page name" do
          request = instance_double(Net::HTTP::Get)
          allow(Net::HTTP::Get).to receive(:new).with("/test-wiki/page/Test%20Page").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_page(encoded_page_name: "Test%20Page")

          expect(Net::HTTP::Get).to have_received(:new).with("/test-wiki/page/Test%20Page")
        end
      end

      context "when page name is URL-encoded with Japanese characters" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "テストページ",
              "source": "TITLE:テストページ",
              "timestamp": "2022-01-01T00:00:00+09:00"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "constructs request path with encoded Japanese page name" do
          request = instance_double(Net::HTTP::Get)
          encoded_name = "%E3%83%86%E3%82%B9%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8"
          allow(Net::HTTP::Get).to receive(:new).with("/test-wiki/page/#{encoded_name}").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_page(encoded_page_name: encoded_name)

          expect(Net::HTTP::Get).to have_received(:new).with("/test-wiki/page/#{encoded_name}")
        end
      end

      context "when request fails" do
        let(:failed_response) { instance_double(Net::HTTPNotFound) }

        before do
          allow(http).to receive(:request).and_return(auth_response, failed_response)
          allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(failed_response).to receive_messages(code: "404", message: "Not Found")
        end

        it "raises Wikiwiki::Error" do
          expect { api.get_page(encoded_page_name: "NonExistent") }.to raise_error(Wikiwiki::Error, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        let(:unauthorized_response) { instance_double(Net::HTTPUnauthorized) }

        before do
          allow(http).to receive(:request).and_return(auth_response, unauthorized_response)
          allow(unauthorized_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(unauthorized_response).to receive_messages(code: "401", message: "Unauthorized")
        end

        it "raises Wikiwiki::Error" do
          expect { api.get_page(encoded_page_name: "FrontPage") }.to raise_error(Wikiwiki::Error, "API request failed: 401 Unauthorized")
        end
      end
    end

    describe "#put_page" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {"status":"ok"}
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "returns hash with status ok" do
          result = api.put_page(encoded_page_name: "TestPage", source: "TITLE:Test\n# Content")
          expect(result).to eq({"status" => "ok"})
        end

        it "sends PUT request to /page/:page_name endpoint with Bearer token and source" do
          request = instance_double(Net::HTTP::Put)
          allow(Net::HTTP::Put).to receive(:new).with("/test-wiki/page/TestPage").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(true)
          allow(request).to receive(:[]=)
          allow(request).to receive(:body=)

          api.put_page(encoded_page_name: "TestPage", source: "TITLE:Test\n# Content")

          expect(Net::HTTP::Put).to have_received(:new).with("/test-wiki/page/TestPage")
          expect(request).to have_received(:[]=).with("Authorization", "Bearer jwt_token_123")
          expect(request).to have_received(:[]=).with("Content-Type", "application/json")
          expect(request).to have_received(:body=).with(<<~JSON.chomp)
            {"source":"TITLE:Test\\n# Content"}
          JSON
        end
      end

      context "when request fails" do
        let(:failed_response) { instance_double(Net::HTTPNotFound) }

        before do
          allow(http).to receive(:request).and_return(auth_response, failed_response)
          allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(failed_response).to receive_messages(code: "404", message: "Not Found")
        end

        it "raises Wikiwiki::Error" do
          expect { api.put_page(encoded_page_name: "NonExistent", source: "content") }.to raise_error(Wikiwiki::Error, "API request failed: 404 Not Found")
        end
      end

      context "when token is invalid" do
        let(:unauthorized_response) { instance_double(Net::HTTPUnauthorized) }

        before do
          allow(http).to receive(:request).and_return(auth_response, unauthorized_response)
          allow(unauthorized_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(unauthorized_response).to receive_messages(code: "401", message: "Unauthorized")
        end

        it "raises Wikiwiki::Error" do
          expect { api.put_page(encoded_page_name: "TestPage", source: "content") }.to raise_error(Wikiwiki::Error, "API request failed: 401 Unauthorized")
        end
      end
    end

    describe "#get_attachments" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
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

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "returns hash with attachments" do
          result = api.get_attachments(encoded_page_name: "FrontPage")
          expect(result["attachments"]).to have_key("logo.png")
        end
      end
    end

    describe "#get_attachment" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "FrontPage",
              "file": "logo.png",
              "src": "base64data"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "returns file info with src data" do
          result = api.get_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
          expect(result["file"]).to eq("logo.png")
          expect(result["src"]).to eq("base64data")
        end
      end

      context "when attachment name is URL-encoded" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "FrontPage",
              "file": "test file.png",
              "src": "base64data"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "constructs request path with encoded attachment name" do
          request = instance_double(Net::HTTP::Get)
          allow(Net::HTTP::Get).to receive(:new)
            .with("/test-wiki/page/FrontPage/attachment/test%20file.png").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "test%20file.png")

          expect(Net::HTTP::Get).to have_received(:new)
            .with("/test-wiki/page/FrontPage/attachment/test%20file.png")
        end
      end

      context "when page and attachment names are URL-encoded with Japanese characters" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {
              "page": "テストページ",
              "file": "画像.png",
              "src": "base64data"
            }
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "constructs request path with encoded page and attachment names" do
          request = instance_double(Net::HTTP::Get)
          encoded_page = "%E3%83%86%E3%82%B9%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8"
          encoded_file = "%E7%94%BB%E5%83%8F.png"
          allow(Net::HTTP::Get).to receive(:new)
            .with("/test-wiki/page/#{encoded_page}/attachment/#{encoded_file}").and_return(request)
          allow(request).to receive(:request_body_permitted?).and_return(false)
          allow(request).to receive(:[]=)

          api.get_attachment(encoded_page_name: encoded_page, encoded_attachment_name: encoded_file)

          expect(Net::HTTP::Get).to have_received(:new)
            .with("/test-wiki/page/#{encoded_page}/attachment/#{encoded_file}")
        end
      end
    end

    describe "#put_attachment" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {"status":"ok"}
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "returns hash with status ok" do
          result = api.put_attachment(encoded_page_name: "FrontPage", attachment_name: "logo.png", encoded_content: "base64data")
          expect(result).to eq({"status" => "ok"})
        end
      end
    end

    describe "#delete_attachment" do
      context "when request succeeds" do
        let(:response) { instance_double(Net::HTTPSuccess) }
        let(:response_body) do
          <<~JSON
            {"status":"ok"}
          JSON
        end

        before do
          allow(http).to receive(:request).and_return(auth_response, response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(response_body)
        end

        it "returns hash with status ok" do
          result = api.delete_attachment(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
          expect(result).to eq({"status" => "ok"})
        end
      end
    end
  end
end
