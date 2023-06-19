describe ManageIQ::Providers::IbmCloud::VPC::CloudManager::ProvisionWorkflow do
  include Spec::Support::WorkflowHelper

  let(:admin)    { FactoryBot.create(:user_with_group) }
  let(:ems)      { FactoryBot.create(:ems_ibm_cloud_vpc) }
  let(:template) { FactoryBot.create(:template_ibm_cloud_vpc, :ext_management_system => ems) }
  let(:workflow) do
    stub_dialog
    allow_any_instance_of(User).to receive(:get_timezone).and_return(Time.zone)
    allow_any_instance_of(ManageIQ::Providers::CloudManager::ProvisionWorkflow).to receive(:update_field_visibility)
    wf = described_class.new({:src_vm_id => template.id}, admin.userid)
    wf
  end

  it "pass platform attributes to automate" do
    stub_dialog
    assert_automate_dialog_lookup(admin, 'cloud', 'ibm_vpc')
    described_class.new({}, admin.userid)
  end

  context "with empty relationships" do
    it "#placement_availability_zone_to_zone" do
      expect(workflow.placement_availability_zone_to_zone).to eq({})
    end

    it "#guest_access_key_pairs_to_keys" do
      expect(workflow.guest_access_key_pairs_to_keys).to eq({})
    end

    it "#cloud_networks_to_vpc" do
      expect(workflow.cloud_networks_to_vpc).to eq({})
    end

    it "#cloud_subnets" do
      expect(workflow.cloud_subnets).to eq({})
    end

    it "#security_group_to_security_group" do
      expect(workflow.security_group_to_security_group).to eq({})
    end

    it "#allowed_instance_types" do
      expect(workflow.allowed_instance_types).to eq({})
    end

    it "#storage_type_to_profile" do
      expect(workflow.storage_type_to_profile).to eq({})
    end

    it "#cloud_volumes_to_volumes" do
      expect(workflow.cloud_volumes_to_volumes).to eq({})
    end
  end

  context "with valid relationships" do
    describe "#placement_availability_zone_to_zone" do
      let!(:az) { FactoryBot.create(:availability_zone, :ext_management_system => ems) }

      it "returns the availability_zones" do
        expect(workflow.placement_availability_zone_to_zone).to eq(az.id => az.name)
      end
    end

    describe "#guest_access_key_pairs_to_keys" do
      let!(:kp) { FactoryBot.create(:auth_key_pair_cloud, :ems_ref => "kp1", :name => "key_pair", :resource => ems) }

      it "returns the key_pairs" do
        expect(workflow.guest_access_key_pairs_to_keys).to eq(kp.ems_ref => kp.name)
      end
    end

    describe "#allowed_instance_types" do
      let!(:flavor) { FactoryBot.create(:flavor, :ems_ref => "bx2d-2x8", :name => "bx2d-2x8", :ext_management_system => ems) }

      it "returns the instance_types" do
        expect(workflow.allowed_instance_types).to eq(flavor.id => flavor.name)
      end
    end

    describe "#storage_type_to_profile" do
      let!(:cvt) { FactoryBot.create(:cloud_volume_type, :ems_ref => "volume-profile1", :name => "Volume Profile 1", :ext_management_system => ems.storage_manager) }

      it "returns the cloud_volume_types" do
        expect(workflow.storage_type_to_profile).to eq(cvt.ems_ref => cvt.name)
      end
    end

    describe "#cloud_volumes_to_volumes" do
      let!(:cv) { FactoryBot.create(:cloud_volume, :ems_ref => "volume1", :name => "Volume 1", :status => "available", :availability_zone => az, :ext_management_system => ems.storage_manager) }
      let!(:az) { FactoryBot.create(:availability_zone, :ext_management_system => ems) }

      context "with a placement_availability_zone selected" do
        before { workflow.values[:placement_availability_zone] = [az.id, az.name] }

        it "returns the cloud_volumes" do
          expect(workflow.cloud_volumes_to_volumes).to eq(cv.ems_ref => cv.name)
        end
      end

      context "with no placement_availability_zone selected" do
        it "returns no cloud_volumes" do
          expect(workflow.cloud_volumes_to_volumes).to eq({})
        end
      end

      context "with a different availability_zone selected" do
        before do
          az2 = FactoryBot.create(:availability_zone, :ext_management_system => ems)
          workflow.values[:placement_availability_zone] = [az2.id, az2.name]
        end

        it "returns no cloud_volumes" do
          expect(workflow.cloud_volumes_to_volumes).to eq({})
        end
      end
    end

    describe "#cloud_networks_to_vpc" do
      let!(:cn) { FactoryBot.create(:cloud_network, :ems_ref => "cn1", :name => "Cloud Network", :ext_management_system => ems.network_manager) }

      it "returns the cloud_networks" do
        expect(workflow.cloud_networks_to_vpc).to eq(cn.ems_ref => cn.name)
      end
    end

    describe "#cloud_subnets" do
      let!(:cs) { FactoryBot.create(:cloud_subnet, :availability_zone => az, :cloud_network => cn, :ems_ref => "cs1", :name => "Cloud Subnet", :ext_management_system => ems.network_manager) }
      let!(:cn) { FactoryBot.create(:cloud_network, :ems_ref => "cn1", :name => "Cloud Network", :ext_management_system => ems.network_manager) }
      let!(:az) { FactoryBot.create(:availability_zone, :ext_management_system => ems) }

      context "with no availability_zone selected" do
        before { workflow.values[:cloud_network] = [cn.ems_ref, cn.name] }

        it "returns no cloud_subnets" do
          expect(workflow.cloud_subnets).to eq({})
        end
      end

      context "with no cloud_network selected" do
        before { workflow.values[:placement_availability_zone] = [az.id, az.name] }

        it "returns no cloud_subnets" do
          expect(workflow.cloud_subnets).to eq({})
        end
      end

      context "with a different cloud_network selected" do
        before do
          cn2 = FactoryBot.create(:cloud_network, :ems_ref => "cn2", :name => "Cloud Network 2", :ext_management_system => ems.network_manager)
          workflow.values[:cloud_network] = [cn2.ems_ref, cn2.name]
          workflow.values[:placement_availability_zone] = [az.id, az.name]
        end

        it "returns no cloud_subnets" do
          expect(workflow.cloud_subnets).to eq({})
        end
      end

      context "with a different availability_zone selected" do
        before do
          az2 = FactoryBot.create(:availability_zone, :ext_management_system => ems)
          workflow.values[:cloud_network] = [cn.ems_ref, cn.name]
          workflow.values[:placement_availability_zone] = [az2.id, az2.name]
        end

        it "returns no cloud_subnets" do
          expect(workflow.cloud_subnets).to eq({})
        end
      end

      context "with a cloud_network and availability_zone selected" do
        before do
          workflow.values[:cloud_network] = [cn.ems_ref, cn.name]
          workflow.values[:placement_availability_zone] = [az.id, az.name]
        end

        it "returns the cloud_subnet" do
          expect(workflow.cloud_subnets).to eq(cs.ems_ref => cs.name)
        end
      end
    end

    describe "#security_group_to_security_group" do
      let!(:cn) { FactoryBot.create(:cloud_network, :ext_management_system => ems.network_manager) }
      let!(:sg) { FactoryBot.create(:security_group, :name => "SecurityGroup", :ext_management_system => ems.network_manager, :cloud_network => cn) }

      context "with a cloud_network selected" do
        before { workflow.values[:cloud_network] = [cn.ems_ref, cn.name] }

        it "returns the security_group" do
          expect(workflow.security_group_to_security_group).to eq(sg.id => sg.name)
        end
      end

      context "with no cloud_network selected" do
        it "doesn't return the security_group" do
          expect(workflow.security_group_to_security_group).to eq({})
        end
      end
    end
  end
end
