class Spree::AdvancedReport::OrderDetailReport < Spree::AdvancedReport
  def initialize(report_params)
    if !report_params[:begin_date] && !report_params[:end_date]
      @begin_date = Time.now - 1.month
      @end_date = Time.now
    else
      @begin_date = report_params[:begin_date]
      @end_date = report_params[:end_date]
    end

    @orders = ::Spree::Order
      .eager_load(:payments, line_items: [:variant])
      .where(completed_at: [@begin_date..@end_date])
      .where("spree_payments.state = 'completed'")
      .order(:completed_at)
  end

  def line_items
    lines = []

    @orders.each do |order|
      if order.payments.any?
        # Assume that there is only one completed transaction per order
        transaction_id = order.payments.first.response_code
      else
        transaction_id = 'pending'
      end

      order.line_items.each do |li|
        lines << ReportLine.new(
          order.number,
          order.completed_at.strftime('%m/%d/%Y'),
          li.variant.sku,
          li.quantity,
          li.price.to_f,
          (li.price * li.quantity).to_f,
          transaction_id
        )
      end

      # Tax and whole-order adjustments
      order.all_adjustments.each do |adj|
        lines << ReportLine.new(
          order.number,
          order.completed_at.strftime('%m/%d/%Y'),
          adj.label,
          nil,
          nil,
          adj.amount.to_f,
          transaction_id
        )
      end

      # Shipments
      order.shipments.each do |shipment|
        lines << ReportLine.new(
          order.number,
          order.completed_at.strftime('%m/%d/%Y'),
          shipment.shipping_method.name,
          nil,
          nil,
          shipment.cost.to_f,
          transaction_id
        )
      end if order.ship_total?
    end

    lines
  end

  def to_csv
    lines = line_items.collect(&:values)
    CSV.generate do |csv|
      csv << %w(number completed_date sku quantity unit_price amount transaction_id)
      lines.each { |li| csv << li }
    end
  end

  ReportLine = Struct.new(
    :number,
    :completed_date,
    :sku,
    :quantity,
    :unit_price,
    :amount,
    :transaction_id
  )
end
