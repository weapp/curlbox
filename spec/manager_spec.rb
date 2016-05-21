require "spec_helper"

describe Manager do
  subject { Manager.new(:memory, namespace: "namespace") }

  it { expect(subject.read("hello")).to be_nil }

  it {
    subject.post("hello", ["w"])
    expect(subject.read("hello").read).to eq "w"
  }

  it { expect(subject.read("hello.json").read).to eq "{\n}\n" }

  it {
    subject.post("hello.json", ["w"])
    expect(subject.read("hello.json").read).to eq "w"
  }

  it {
    expect(Manager.as_s(StringIO.new("io"))).to eq "io"
  }

  it {
    expect(Manager.as_io("string").read).to eq "string"
  }
end
