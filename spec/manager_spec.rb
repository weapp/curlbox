require "spec_helper"

def as_s(buffer)
  Manager.as_s(buffer)
end

describe Manager do
  [:memory, :fs, :s3].each do |adapter|
    next if adapter == :s3 && !ENV["BUCKET"]
    context "Adapter: #{adapter}" do
      subject { Manager.new(adapter: adapter, namespace: "test/manager", bucket: ENV["BUCKET"]) }

      describe "#get", :get, adapter do
        it { expect(subject.get("/#{EXECUTION}")).to be_nil }

        it { expect(as_s subject.get("/#{EXECUTION}.json")).to eq "{\n}\n" }
      end

      describe "#post", :post, adapter do
        it {
          subject.post("/POST/#{EXECUTION}", StringIO.new('{"k": "v"}'))
          expect(as_s subject.get("/POST/#{EXECUTION}")).to eq '{"k": "v"}'
        }

        it {
          subject.post("/POST/#{EXECUTION}.json", StringIO.new('{"k": "v"}'))
          expect(as_s subject.get("/POST/#{EXECUTION}.json")).to eq '{"k": "v"}'
        }
      end

      describe "#put", :put, adapter do
        it {
          subject.put("/PUT/#{EXECUTION}", StringIO.new('{"k": "v"}'))
          expect(as_s subject.get("/PUT/#{EXECUTION}")).to eq pretty(k: :v)
        }

        it {
          subject.put("/PUT/#{EXECUTION}.json", StringIO.new('{"k": "v"}'))
          expect(as_s subject.get("/PUT/#{EXECUTION}.json")).to eq pretty(k: :v)
        }
      end

      describe "#delete", :delete, adapter do
        it "delete file" do
          expect(subject.get("/DELETE_FILE/#{EXECUTION}")).to be_nil
          subject.post("/DELETE_FILE/#{EXECUTION}", StringIO.new("content"))
          expect(as_s subject.get("/DELETE_FILE/#{EXECUTION}")).to eq "content"
          subject.delete("/DELETE_FILE/#{EXECUTION}")
          expect(subject.get("/DELETE_FILE/#{EXECUTION}")).to be_nil
        end

        it "delete folder" do
          expect(subject.get("/DELETE_FOLDER/#{EXECUTION}/file")).to be_nil
          subject.post("/DELETE_FOLDER/#{EXECUTION}/file", StringIO.new("content"))
          expect(as_s subject.get("/DELETE_FOLDER/#{EXECUTION}/file")).to eq "content"
          subject.delete("/DELETE_FOLDER/#{EXECUTION}")
          expect(subject.get("/DELETE_FOLDER/#{EXECUTION}/file")).to be_nil
        end
      end
    end


    describe ".as_s" do
      it { expect(Manager.as_s(StringIO.new("io"))).to eq "io" }
    end

    describe ".as_io" do
      it { expect(Manager.as_io("string").read).to eq "string" }
    end
  end
end
