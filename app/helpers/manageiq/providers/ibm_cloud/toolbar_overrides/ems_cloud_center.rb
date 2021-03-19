module ManageIQ
  module Providers
    module IbmCloud
      module ToolbarOverrides
        class EmsCloudCenter < ::ApplicationHelper::Toolbar::Override
          button_group('ibmcloud_image_import_export_group', [
              button(
                  :import_image,
                  'pficon pficon-import fa-lg',
                  t = N_('Import Image'),
                  t,
                  :data  => {'function'      => 'sendDataWithRx',
                             'function-data' => {:controller     => 'provider_dialogs',
                                                 :button         => :import_image,
                                                 :modal_title    => N_('Choose Provider and Image'),
                                                 :component_name => 'ImportImageForm'}},
                  :klass => ::ApplicationHelper::Button::ButtonWithoutRbacCheck),
          ])
        end
      end
    end
  end
end