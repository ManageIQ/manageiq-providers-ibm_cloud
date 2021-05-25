describe ManageIQ::Providers::IbmCloud::ObjectStorage::ObjectManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_cloud_object_storage)
  end
  context "#refresh" do
    let(:ems) do
      uid_ems    = "960f1ca0-8a54-402b-9747-f980a84bd312"
      auth_key   = Rails.application.secrets.ibm_cloud_object_storage[:api_key]
      access_key = Rails.application.secrets.ibm_cloud_object_storage[:access_key]
      secret_key = Rails.application.secrets.ibm_cloud_object_storage[:secret_key]

      FactoryBot.create(
        :ems_ibm_cloud_object_storage_object,
        :uid_ems         => uid_ems,
        :provider_region => "us-south",
        :endpoints       => [FactoryBot.create(
          :endpoint,
          :role => 'default',
          :url  => 'https://s3.us-east.cloud-object-storage.appdomain.cloud'
        )]
      ).tap do |ems|
        ems.authentications << FactoryBot.create(
          :authentication,
          :authtype => 'default',
          :auth_key => auth_key
        )
        ems.authentications << FactoryBot.create(
          :authentication,
          :authtype => 'bearer',
          :userid   => access_key,
          :password => secret_key
        )
      end
    end

    it "full refresh" do
      2.times do
        full_refresh(ems)
        ems.reload
      end
    end

    def full_refresh(ems)
      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(ems)
      end
    end
  end
end
