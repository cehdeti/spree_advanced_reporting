Spree::Admin::ReportsController.class_eval do
  before_action :basic_report_setup, only: Spree::AdvancedReport::REPORTS

  def initialize
    # From Spree::Admin::ReportController#initialize
    super
    self.class.add_available_report!(:sales_total)

    # Our advanced reports.
    Spree::AdvancedReport::REPORTS.each do |report|
      self.class.add_available_report!(report)
    end
  end

  def basic_report_setup
    @products = Spree::Product.all
    @taxons = Spree::Taxon.all
    if defined?(MultiDomainExtension)
      @stores = Store.all
    end
  end

  def revenue
    @report = Spree::AdvancedReport::IncrementReport::Revenue.new(params)
    base_report_render
  end

  def units
    @report = Spree::AdvancedReport::IncrementReport::Units.new(params)
    base_report_render
  end

  def daily_details
    @report = Spree::AdvancedReport::DailyDetailsReport.new(params)
    render template: 'spree/admin/reports/daily_details'
  end

  def profit
    @report = Spree::AdvancedReport::IncrementReport::Profit.new(params)
    base_report_render
  end

  def count
    @report = Spree::AdvancedReport::IncrementReport::Count.new(params)
    base_report_render
  end

  def top_products
    @report = Spree::AdvancedReport::TopReport::TopProducts.new(params, 4)
    base_report_top_render
  end

  def top_customers
    @report = Spree::AdvancedReport::TopReport::TopCustomers.new(params, 4)
    base_report_top_render
  end

  def geo_revenue
    @report = Spree::AdvancedReport::GeoReport::GeoRevenue.new(params)
    geo_report_render
  end

  def geo_units
    @report = Spree::AdvancedReport::GeoReport::GeoUnits.new(params)
    geo_report_render
  end

  def geo_profit
    @report = Spree::AdvancedReport::GeoReport::GeoProfit.new(params)
    geo_report_render
  end

  def order_details
    @report = Spree::AdvancedReport::OrderDetailReport.new(params)
    @groups = Spree::Group.all
    respond_to do |format|
      format.html { render template: 'spree/admin/reports/order_details' }
      format.csv { send_data @report.to_csv }
    end
  end

  private

  def geo_report_render
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]['report_type'] = params[:advanced_reporting]['report_type'].to_sym if params[:advanced_reporting]['report_type']
    params[:advanced_reporting]["report_type"] ||= :state
    respond_to do |format|
      format.html { render template: 'spree/admin/reports/geo_base' }
      format.csv do
        send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv
      end
    end
  end

  def base_report_top_render
    respond_to do |format|
      format.html { render template: 'spree/admin/reports/top_base' }
      format.csv { send_data @report.ruportdata.to_csv }
    end
  end

  def base_report_render
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]['report_type'] = params[:advanced_reporting]['report_type'].to_sym if params[:advanced_reporting]['report_type']
    params[:advanced_reporting]['report_type'] ||= :daily
    respond_to do |format|
      format.html { render template: 'spree/admin/reports/increment_base' }
      format.csv do
        if params[:advanced_reporting]['report_type'] == :all
          send_data @report.all_data.to_csv
        else
          send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv
        end
      end
    end
  end
end
