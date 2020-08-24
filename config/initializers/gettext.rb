Vmdb::Gettext::Domains.add_domain(
  'ManageIQ::Providers::IbmCloud',
  ManageIQ::Providers::IbmCloud::Engine.root.join('locale').to_s,
  :po
)
