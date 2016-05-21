require "spec_helper"

describe CurlBox do
  let(:app) { CurlBox.new(adapter: :memory, log_level: Logger::ERROR) }
  let(:conn) { Faraday.new { |conn| conn.adapter :rack, app } }

  after { app.manager.delete("/") }

  describe "GET /GET/doc" do
    subject { conn.get("/GET/doc") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end
  end

  describe "GET /GET/doc.json" do
    subject { conn.get("/GET/doc.json") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 200, pretty }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 200, pretty }
    end
  end

  describe "GET /public/GET/doc" do
    subject { conn.get("/public/GET/doc") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end
  end

  describe "POST /POST/doc" do
    subject { conn.post("/POST/doc", "data") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 200, "/POST/doc\n" }
    end
  end

  describe "PUT /PUT/doc" do
    subject { conn.post("/PUT/doc", "data") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 200, "/PUT/doc\n" }
    end
  end

  describe "GET /cache/#{EXECUTION}/GET/doc" do
    subject { conn.get("/cache/#{EXECUTION}/GET/doc") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end
  end

  describe "GET /cache/#{EXECUTION}/GET/doc.json" do
    subject { conn.get("/cache/#{EXECUTION}/GET/doc.json") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 401, "" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 200, pretty }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 200, pretty }
    end
  end

  describe "GET /public/cache/#{EXECUTION}/GET/doc" do
    subject { conn.get("/public/cache/#{EXECUTION}/GET/doc") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 404, "Not Found\n" }
    end
  end

  describe "POST /cache/#{EXECUTION}/POST/doc" do
    subject { conn.post("/cache/#{EXECUTION}/POST/doc", "data") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end
  end

  describe "PUT /cache/#{EXECUTION}/PUT/doc" do
    subject { conn.post("/cache/#{EXECUTION}/PUT/doc", "data") }

    context "annon", :annon do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end

    context "user", :user do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end

    context "admin", :admin do
      it { is_expected.to have_status_and_body 405, "Method not allowed\n" }
    end
  end

  context "json flow", :examples, :admin do
    context "first post" do
      let(:path) { "/POST/doc.json" }

      example doc_with_line do
        expect(conn.get(path))
          .to have_status_and_body 200, pretty
        expect(conn.post(path, '{"a":"b"}'))
          .to have_status_and_body 200, "#{path}\n"
        expect(conn.get(path))
          .to have_status_and_body 200, '{"a":"b"}'
        expect(conn.put(path, '{"a":"b"}'))
          .to have_status_and_body 200, "#{path}\n"
        expect(conn.get(path))
          .to have_status_and_body 200, pretty(a: :b)
        expect(conn.put(path, '{"b":"c"}'))
          .to have_status_and_body 200, "#{path}\n"
        expect(conn.get(path))
          .to have_status_and_body 200, pretty(a: :b, b: :c)
      end
    end

    context "first put" do
      let(:path) { "/PUT/doc.json" }

      example doc_with_line do
        expect(conn.get(path))
          .to have_status_and_body 200, pretty
        expect(conn.put(path, '{"a":"b"}'))
          .to have_status_and_body 200, "#{path}\n"
        expect(conn.get(path))
          .to have_status_and_body 200, pretty(a: :b)
        expect(conn.put(path, '{"b":"c"}'))
          .to have_status_and_body 200, "#{path}\n"
        expect(conn.get(path))
          .to have_status_and_body 200, pretty(a: :b, b: :c)
      end
    end
  end

  context "cache flow", :admin, :examples do
    example "passthrough json" do
      expect(conn.get("/cache/#{EXECUTION}#{path}.json"))
        .to have_status_and_body 200, pretty
    end

    example "passthrough after post" do
      expect(conn.post(path, '{"a":"b"}'))
        .to have_status_and_body 200, "#{path}\n"

      expect(conn.get("/cache/#{EXECUTION}#{path}"))
        .to have_status_and_body 200, '{"a":"b"}'
    end

    let(:path) { "/POST/cache/doc.json" }

    example doc_with_line do
      # empty
      expect(conn.post(path, '{"a":"b"}'))
        .to have_status_and_body 200, "#{path}\n"

      # updating original
      expect(conn.get(path))
        .to have_status_and_body 200, '{"a":"b"}'

      # caching
      expect(conn.get("/cache/#{EXECUTION}#{path}"))
        .to have_status_and_body 200, '{"a":"b"}'

      # updating original
      expect(conn.post(path, '{"b":"c"}'))
        .to have_status_and_body 200, "#{path}\n"

      # original updated
      expect(conn.get(path))
        .to have_status_and_body 200, '{"b":"c"}'

      # cache persisted
      expect(conn.get("/cache/#{EXECUTION}#{path}"))
        .to have_status_and_body 200, '{"a":"b"}'

      # caching
      expect(conn.get("/cache/#{EXECUTION}-other-key#{path}"))
        .to have_status_and_body 200, '{"b":"c"}'

      # updating original
      expect(conn.post(path, '{"j":"k"}'))
        .to have_status_and_body 200, "#{path}\n"

      # original updated
      expect(conn.get(path))
        .to have_status_and_body 200, '{"j":"k"}'

      # cache persisted
      expect(conn.get("/cache/#{EXECUTION}#{path}"))
        .to have_status_and_body 200, '{"a":"b"}'

      # second cache persisted
      expect(conn.get("/cache/#{EXECUTION}-other-key#{path}"))
        .to have_status_and_body 200, '{"b":"c"}'

    end
  end

end
