describe String, "inflections" do
  [
    "PowerVirtualServers",
    "power_virtual_servers"
  ].each do |name|
    example("#pluralize")   { expect(name.pluralize).to eq(name) }
    example("#singularize") { expect(name.singularize).to eq(name) }
    example("#classify")    { expect(name.classify).to eq("PowerVirtualServers") }
  end
end
