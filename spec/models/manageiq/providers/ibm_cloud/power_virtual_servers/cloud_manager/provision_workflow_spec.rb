describe ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ProvisionWorkflow do
  include Spec::Support::WorkflowHelper

  let(:admin) { FactoryBot.create(:user_with_group) }
  let(:ems) { FactoryBot.create(:ems_ibm_cloud_power_virtual_servers_cloud) }
  let(:template) do
    FactoryBot.create(
      :template_ibm_cloud_power_virtual_servers,
      :name                  => "template",
      :ext_management_system => ems
    )
  end
  let(:workflow) do
    stub_dialog
    allow(User).to receive_messages(:server_timezone => "UTC")
    described_class.new({:src_vm_id => template.id}, admin.userid)
  end

  it "#parse_new_volumes_fields" do
    values = {
      :storage_type => [0, "tier1"],
      :name         => nil,
      :size         => nil,
      :shareable    => false
    }
    expect(workflow.parse_new_volumes_fields(values))
      .to match_array([])
    values = {
      :storage_type => [1, "tier1"],
      :name         => nil,
      :size         => nil,
      :shareable    => false,
      :name_1       => "disk_one",
      :size_1       => "1",
      :shareable_1  => "null",
      :name_2       => "disk_two",
      :size_2       => "2",
      :name_3       => "disk_three",
      :size_3       => "3",
      :shareable_3  => nil,
      :name_4       => "disk_four",
      :size_4       => "4",
      :shareable_4  => true
    }
    expect(workflow.parse_new_volumes_fields(values))
      .to match_array(
        [
          {
            :name      => "disk_one",
            :size      => 1,
            :disk_type => "tier1",
            :shareable => false
          },
          {
            :name      => "disk_two",
            :size      => 2,
            :disk_type => "tier1",
            :shareable => false
          },
          {
            :name      => "disk_three",
            :size      => 3,
            :disk_type => "tier1",
            :shareable => false
          },
          {
            :name      => "disk_four",
            :size      => 4,
            :disk_type => "tier1",
            :shareable => true
          }
        ]
      )
    values = {
      :storage_type => [2, "tier1"],
      :name         => nil,
      :size         => nil,
      :shareable    => false,
      :name_1       => "disk_one",
      :shareable_1  => "null",
      :size_2       => "2",
      :name_3       => "disk_three",
      :size_3       => "3",
      :name_4       => "disk_four",
      :size_4       => "",
      :shareable_4  => true
    }
    expect(workflow.parse_new_volumes_fields(values))
      .to match_array(
        [
          {
            :name      => "disk_one",
            :disk_type => "tier1",
            :size      => 0,
            :shareable => false
          },
          {
            :size      => 2,
            :disk_type => "tier1",
            :shareable => false
          },
          {
            :name      => "disk_three",
            :size      => 3,
            :disk_type => "tier1",
            :shareable => false
          },
          {
            :name      => "disk_four",
            :size      => 0,
            :disk_type => "tier1",
            :shareable => true
          }
        ]
      )
  end
end
