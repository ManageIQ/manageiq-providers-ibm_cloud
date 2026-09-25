k8s_dir = Gem.loaded_specs['manageiq-providers-kubernetes']&.gem_dir ||
          File.expand_path('../../../manageiq-providers-kubernetes', __dir__)
require "#{k8s_dir}/lib/manageiq/providers/kubernetes/workers/event_catcher_base"
require "#{k8s_dir}/workers/event_catcher/event_parser"

require 'ibm_cloud_iam'

class EventCatcher < KubernetesEventCatcherBase
  attr_reader :token_expiry

  private

  def auth_options
    iam_token_api = IbmCloudIam::TokenOperationsApi.new
    grant_type    = 'urn:ibm:params:oauth:grant-type:apikey'
    header_params = {
      'Content-Type'  => 'application/x-www-form-urlencoded',
      'Authorization' => 'Basic a3ViZTprdWJl',
      'cache-control' => 'no-cache'
    }
    response      = iam_token_api.get_token_api_key(grant_type, authentication['auth_key'], {:header_params => header_params})
    @token_expiry = response.expiration ? Time.at(response.expiration).utc : nil
    {:bearer_token => response.id_token}
  end

  def log_prefix
    'MIQ(ManageIQ::Providers::IbmCloud::ContainerManager::EventCatcher)'
  end
end
