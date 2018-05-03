describe Trainer do
  describe Trainer::JunitGenerator do
    it "works for a valid .plist file" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid1.plist")
      junit = File.read("spec/fixtures/Valid1.junit")
      expect(tp.to_junit).to eq(junit)
    end

    it "works for a plist with all tests passing" do
      tp = Trainer::TestParser.new("spec/fixtures/Valid2.plist")
      junit = File.read("spec/fixtures/Valid2.junit")
      expect(tp.to_junit).to eq(junit)
    end
    
    it "works for a plist with multiple test summaries and no run destination" do
      tp = Trainer::TestParser.new("spec/fixtures/TestSummaries-NoRunDestination.plist")
      junit = File.read("spec/fixtures/TestSummaries-NoRunDestination.junit")
      expect(tp.to_junit).to eq(junit)
    end
  end
end
