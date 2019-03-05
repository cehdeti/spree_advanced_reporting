Spree::Core::Engine.routes.draw do
  Spree::AdvancedReport::REPORTS.each do |report|
    match "/admin/reports/#{report}", to: "admin/reports##{report}",
                                      via: [:get, :post],
                                      as: "#{report}_admin_reports"
  end
end
