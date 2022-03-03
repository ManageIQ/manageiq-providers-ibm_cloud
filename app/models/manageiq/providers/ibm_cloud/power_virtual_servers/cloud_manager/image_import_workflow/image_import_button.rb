class ManageIQ::Providers::IbmCloud::PowerVirtualServers::CloudManager::ImageImportWorkflow::ImageImportButton < ApplicationHelper::Button::Basic
  def role_allows_feature?
    role_allows?(:feature => 'image_import')
  end

  def disabled?
    return true unless role_allows_feature?
  end

  def skipped?
    !visible?
  end

  def visible?
    true
  end
end
