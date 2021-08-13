module ManageIQ::Providers::IbmCloud::DatabaseTypes
  ALL_TYPES = YAML.load_file(
    ManageIQ::Providers::IbmCloud::Engine.root.join('db/fixtures/ibm_cloud_database_types.yml')
  )

  def self.database_types
    ALL_TYPES
  end

  def self.all
    database_types.values
  end
end
