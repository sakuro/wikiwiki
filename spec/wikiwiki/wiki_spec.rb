# frozen_string_literal: true

require "digest/md5"

RSpec.describe Wikiwiki::Wiki do
  let(:wiki_id) { "test-wiki" }
  let(:auth) { Wikiwiki::Auth.password(password: "test_password") }
  let(:api) { instance_double(Wikiwiki::API) }
  let(:rate_limiter) { Wikiwiki::RateLimiter.no_limit }
  let(:wiki) { Wikiwiki::Wiki.new(wiki_id:, auth:, rate_limiter:) }

  before do
    allow(Wikiwiki::API).to receive(:new).with(wiki_id:, auth:, rate_limiter:).and_return(api)
  end

  describe "#page_names" do
    it "returns an array of page names" do
      allow(api).to receive(:get_pages).and_return(
        {
          "pages" => [
            {"name" => "FrontPage", "timestamp" => "2022-01-01T00:00:00+09:00"},
            {"name" => "SideBar", "timestamp" => "2022-01-02T00:00:00+09:00"}
          ]
        }
      )

      expect(wiki.page_names).to eq(%w[FrontPage SideBar])
    end
  end

  describe "#page" do
    it "returns a Page object with page content" do
      allow(api).to receive(:get_page).with(encoded_page_name: "TestPage").and_return(
        {
          "page" => "TestPage",
          "source" => "TITLE:Test\n# Content",
          "timestamp" => "2022-01-01T00:00:00+09:00"
        }
      )

      page = wiki.page(page_name: "TestPage")

      expect(page).to be_a(Wikiwiki::Page)
      expect(page.name).to eq("TestPage")
      expect(page.source).to eq("TITLE:Test\n# Content")
      expect(page.timestamp).to eq(Time.new(2022, 1, 1, 0, 0, 0, "+09:00"))
      expect(page.timestamp).to be_a(Time)
    end

    it "URL-encodes page name before passing to API" do
      allow(api).to receive(:get_page).with(encoded_page_name: "Test%20Page").and_return(
        {
          "page" => "Test Page",
          "source" => "TITLE:Test Page",
          "timestamp" => "2022-01-01T00:00:00+09:00"
        }
      )

      page = wiki.page(page_name: "Test Page")

      expect(page.name).to eq("Test Page")
      expect(api).to have_received(:get_page).with(encoded_page_name: "Test%20Page")
    end

    it "URL-encodes Japanese page name before passing to API" do
      encoded_name = "%E3%83%86%E3%82%B9%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8"
      allow(api).to receive(:get_page).with(encoded_page_name: encoded_name).and_return(
        {
          "page" => "テストページ",
          "source" => "TITLE:テストページ",
          "timestamp" => "2022-01-01T00:00:00+09:00"
        }
      )

      page = wiki.page(page_name: "テストページ")

      expect(page.name).to eq("テストページ")
      expect(api).to have_received(:get_page).with(encoded_page_name: encoded_name)
    end

    it "raises Wikiwiki::Error when page does not exist" do
      allow(api).to receive(:get_page).with(encoded_page_name: "NonExistent")
        .and_raise(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")

      expect { wiki.page(page_name: "NonExistent") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
    end
  end

  describe "#update_page" do
    let(:new_source) { "TITLE:New\n# New Content" }

    it "updates the page with new content" do
      allow(api).to receive(:put_page).with(encoded_page_name: "TestPage", source: new_source)
        .and_return({"status" => "ok"})

      result = wiki.update_page(page_name: "TestPage", source: new_source)

      expect(result).to eq({"status" => "ok"})
      expect(api).to have_received(:put_page).with(encoded_page_name: "TestPage", source: new_source)
    end

    it "URL-encodes page name before passing to API" do
      allow(api).to receive(:put_page).with(encoded_page_name: "Test%20Page", source: new_source)
        .and_return({"status" => "ok"})

      wiki.update_page(page_name: "Test Page", source: new_source)

      expect(api).to have_received(:put_page).with(encoded_page_name: "Test%20Page", source: new_source)
    end

    it "raises Wikiwiki::Error when update fails" do
      allow(api).to receive(:put_page).with(encoded_page_name: "TestPage", source: new_source)
        .and_raise(Wikiwiki::ServerError, "API request failed: 500 Internal Server Error")

      expect { wiki.update_page(page_name: "TestPage", source: new_source) }.to raise_error(Wikiwiki::ServerError, "API request failed: 500 Internal Server Error")
    end
  end

  describe "#attachment_names" do
    it "returns array of attachment file names" do
      allow(api).to receive(:get_attachments).with(encoded_page_name: "FrontPage").and_return(
        {
          "attachments" => {
            "logo.png" => {
              "page" => "FrontPage",
              "file" => "logo.png",
              "size" => 12345,
              "time" => 1_640_962_800,
              "type" => "image/png",
              "md5hash" => "abc123"
            },
            "doc.pdf" => {
              "page" => "FrontPage",
              "file" => "doc.pdf",
              "size" => 54321,
              "time" => 1_640_966_400,
              "type" => "application/pdf",
              "md5hash" => "def456"
            }
          }
        }
      )

      attachment_names = wiki.attachment_names(page_name: "FrontPage")

      expect(attachment_names).to be_an(Array)
      expect(attachment_names.size).to eq(2)
      expect(attachment_names).to include("logo.png", "doc.pdf")
    end

    it "returns empty array when no attachments exist" do
      allow(api).to receive(:get_attachments).with(encoded_page_name: "EmptyPage").and_return(
        {
          "attachments" => []
        }
      )

      attachment_names = wiki.attachment_names(page_name: "EmptyPage")

      expect(attachment_names).to eq([])
    end

    it "URL-encodes page name before passing to API" do
      allow(api).to receive(:get_attachments).with(encoded_page_name: "Test%20Page").and_return(
        {
          "attachments" => {}
        }
      )

      wiki.attachment_names(page_name: "Test Page")

      expect(api).to have_received(:get_attachments).with(encoded_page_name: "Test%20Page")
    end

    it "raises Wikiwiki::Error when request fails" do
      allow(api).to receive(:get_attachments).with(encoded_page_name: "FrontPage")
        .and_raise(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")

      expect { wiki.attachment_names(page_name: "FrontPage") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
    end
  end

  describe "#attachment" do
    it "returns Attachment object with decoded file data" do
      binary_data = "PNG file content data"
      base64_data = Base64.strict_encode64(binary_data)
      correct_md5 = Digest::MD5.hexdigest(binary_data)
      correct_size = binary_data.bytesize

      allow(api).to receive(:get_attachment).with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
        .and_return(
          {
            "page" => "FrontPage",
            "file" => "logo.png",
            "size" => correct_size,
            "time" => 1_640_962_800,
            "type" => "image/png",
            "md5hash" => correct_md5,
            "src" => base64_data
          }
        )

      attachment = wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png")

      expect(attachment).to be_a(Wikiwiki::Attachment)
      expect(attachment.page_name).to eq("FrontPage")
      expect(attachment.name).to eq("logo.png")
      expect(attachment.size).to eq(correct_size)
      expect(attachment.time).to eq(Time.at(1_640_962_800))
      expect(attachment.type).to eq("image/png")
      expect(attachment.content).to eq(binary_data)
    end

    it "URL-encodes page name and attachment name before passing to API" do
      binary_data = "test data"
      base64_data = Base64.strict_encode64(binary_data)
      correct_md5 = Digest::MD5.hexdigest(binary_data)
      correct_size = binary_data.bytesize

      allow(api).to receive(:get_attachment)
        .with(encoded_page_name: "Test%20Page", encoded_attachment_name: "test%20file.png")
        .and_return(
          {
            "page" => "Test Page",
            "file" => "test file.png",
            "size" => correct_size,
            "time" => 1_640_962_800,
            "type" => "image/png",
            "md5hash" => correct_md5,
            "src" => base64_data
          }
        )

      wiki.attachment(page_name: "Test Page", attachment_name: "test file.png")

      expect(api).to have_received(:get_attachment)
        .with(encoded_page_name: "Test%20Page", encoded_attachment_name: "test%20file.png")
    end

    it "raises Wikiwiki::Error when size does not match" do
      binary_data = "PNG file content data"
      base64_data = Base64.strict_encode64(binary_data)
      wrong_size = 99999

      allow(api).to receive(:get_attachment).with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
        .and_return(
          {
            "page" => "FrontPage",
            "file" => "logo.png",
            "size" => wrong_size,
            "time" => 1_640_962_800,
            "type" => "image/png",
            "md5hash" => "dummy_hash",
            "src" => base64_data
          }
        )

      expect { wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png") }.to raise_error(Wikiwiki::ContentIntegrityError, /Size mismatch/)
    end

    it "raises Wikiwiki::Error when MD5 hash does not match" do
      binary_data = "PNG file content data"
      base64_data = Base64.strict_encode64(binary_data)
      wrong_md5 = "incorrect_hash"

      allow(api).to receive(:get_attachment).with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
        .and_return(
          {
            "page" => "FrontPage",
            "file" => "logo.png",
            "size" => binary_data.bytesize,
            "time" => 1_640_962_800,
            "type" => "image/png",
            "md5hash" => wrong_md5,
            "src" => base64_data
          }
        )

      expect { wiki.attachment(page_name: "FrontPage", attachment_name: "logo.png") }.to raise_error(Wikiwiki::ContentIntegrityError, /MD5 hash mismatch/)
    end

    it "raises Wikiwiki::Error when attachment does not exist" do
      allow(api).to receive(:get_attachment).with(encoded_page_name: "FrontPage", encoded_attachment_name: "missing.png")
        .and_raise(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")

      expect { wiki.attachment(page_name: "FrontPage", attachment_name: "missing.png") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
    end
  end

  describe "#add_attachment" do
    it "uploads attachment with Base64-encoded content" do
      binary_content = "PNG binary data here"
      encoded_content = Base64.strict_encode64(binary_content)

      allow(api).to receive(:put_attachment)
        .with(encoded_page_name: "FrontPage", attachment_name: "logo.png", encoded_content:)
        .and_return({"status" => "ok"})

      result = wiki.add_attachment(page_name: "FrontPage", attachment_name: "logo.png", content: binary_content)

      expect(result).to eq({"status" => "ok"})
      expect(api).to have_received(:put_attachment)
        .with(encoded_page_name: "FrontPage", attachment_name: "logo.png", encoded_content:)
    end

    it "URL-encodes page name before passing to API" do
      binary_content = "test data"
      encoded_content = Base64.strict_encode64(binary_content)

      allow(api).to receive(:put_attachment)
        .with(encoded_page_name: "Test%20Page", attachment_name: "logo.png", encoded_content:)
        .and_return({"status" => "ok"})

      wiki.add_attachment(page_name: "Test Page", attachment_name: "logo.png", content: binary_content)

      expect(api).to have_received(:put_attachment)
        .with(encoded_page_name: "Test%20Page", attachment_name: "logo.png", encoded_content:)
    end

    it "raises Wikiwiki::Error when upload fails" do
      allow(api).to receive(:put_attachment)
        .with(encoded_page_name: "FrontPage", attachment_name: "logo.png", encoded_content: anything)
        .and_raise(Wikiwiki::ServerError, "API request failed: 500 Internal Server Error")

      expect { wiki.add_attachment(page_name: "FrontPage", attachment_name: "logo.png", content: "data") }.to raise_error(Wikiwiki::ServerError, "API request failed: 500 Internal Server Error")
    end
  end

  describe "#delete_attachment" do
    it "deletes the specified attachment" do
      allow(api).to receive(:delete_attachment)
        .with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
        .and_return({"status" => "ok"})

      result = wiki.delete_attachment(page_name: "FrontPage", attachment_name: "logo.png")

      expect(result).to eq({"status" => "ok"})
      expect(api).to have_received(:delete_attachment)
        .with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
    end

    it "URL-encodes page name and attachment name before passing to API" do
      allow(api).to receive(:delete_attachment)
        .with(encoded_page_name: "Test%20Page", encoded_attachment_name: "test%20file.png")
        .and_return({"status" => "ok"})

      wiki.delete_attachment(page_name: "Test Page", attachment_name: "test file.png")

      expect(api).to have_received(:delete_attachment)
        .with(encoded_page_name: "Test%20Page", encoded_attachment_name: "test%20file.png")
    end

    it "raises Wikiwiki::Error when deletion fails" do
      allow(api).to receive(:delete_attachment)
        .with(encoded_page_name: "FrontPage", encoded_attachment_name: "logo.png")
        .and_raise(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")

      expect { wiki.delete_attachment(page_name: "FrontPage", attachment_name: "logo.png") }.to raise_error(Wikiwiki::ResourceNotFoundError, "API request failed: 404 Not Found")
    end
  end
end
