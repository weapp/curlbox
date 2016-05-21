require "spec_helper"

describe Manager do
  subject { Manager.new(:memory, namespace: "namespace") }

  it { expect(subject.get("hello")).to be_nil }

  it {
    subject.post("hello", ["w"])
    expect(subject.get("hello").read).to eq "w"
  }

  it { expect(subject.get("hello.json").read).to eq "{\n}\n" }

  it {
    subject.post("hello.json", ["w"])
    expect(subject.get("hello.json").read).to eq "w"
  }

  it {
    expect(Manager.as_s(StringIO.new("io"))).to eq "io"
  }

  it {
    expect(Manager.as_io("string").read).to eq "string"
  }
end
