describe Trainer do
  describe Trainer::JunitGenerator do
    it "works for a valid .plist file" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid1.plist")
      junit = File.read("spec/fixtures/Valid1.junit")
      expect(tp.to_junit).to eq(junit)
    end

    it "works for a valid .plist file and xcpretty naming" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid1.plist", { xcpretty_naming: true })
      junit = File.read("spec/fixtures/Valid1-x.junit")
      expect(tp.to_junit).to eq(junit)
    end

    it "works for a with all tests passing" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid2.plist")
      junit = File.read("spec/fixtures/Valid2.junit")
      expect(tp.to_junit).to eq(junit)
    end

    it "works for a with all tests passing and xcpretty naming" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid2.plist", { xcpretty_naming: true })
      junit = File.read("spec/fixtures/Valid2-x.junit")
      expect(tp.to_junit).to eq(junit)
    end

    it "includes .crash test attachments" do
      tp = Trainer::TestParser.new("spec/fixtures/Test-ShapeSwift.xcresult/TestSummaries.plist", { include_crash_trace: true })
      junit = File.read("spec/fixtures/Test-ShapeSwift.xcresult/TestSummaries.xml")
      expect(tp.to_junit).to eq(junit)
    end
  end
end
