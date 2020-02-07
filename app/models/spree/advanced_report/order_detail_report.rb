class Spree::AdvancedReport::OrderDetailReport < Spree::AdvancedReport
  def initialize(report_params)
    if !report_params[:begin_date] && !report_params[:end_date]
      @begin_date = Time.now - 1.month
      @end_date = Time.now
    else
      @begin_date = report_params[:begin_date]
      @end_date = report_params[:end_date]
    end
  end

  def line_items
    lines = []

    orders.each do |order|
      transaction_id = if order.total.zero?
                         'N/A'
                       elsif order.payments.any?
                         # Assume that there is only one completed transaction per order
                         order.payments.first.response_code
                       else
                         'pending'
                       end
        
      subscription = if order.account_subscriptions.any?
                        # Assume only one subscription for now
                        order.account_subscriptions.first
                      end

      order.line_items.each do |li|
        lines << line_item_report_line(li, order, transaction_id, subscription)
      end

      order.all_adjustments.eligible.each do |adj|
        lines << adjustment_report_line(adj, order, transaction_id, subscription)
      end

      next unless order.ship_total?

      order.shipments.where('cost > 0').each do |shipment|
        lines << shipment_report_line(shipment, order, transaction_id, subscription)
      end
    end

    lines
  end

  def orders
    ::Spree::Order
      .eager_load(:payments, line_items: [:variant])
      .where(completed_at: [@begin_date..@end_date])
      .where(payment_state: :paid)
      .order(:completed_at)
  end

  def to_csv
    lines = line_items.collect(&:values)
    CSV.generate do |csv|
      csv << %w[number completed_date sku quantity unit_price amount transaction_id]
      lines.each { |li| csv << li }
    end
  end

  ReportLine = Struct.new(
    :number,
    :completed_date,
    :company,
    :billing_address,
    :sku,
    :quantity,
    :unit_price,
    :amount,
    :transaction_id,
    :subscription_id,
    :subscription_token,
    :subscription_expiration,
  )

  private

  def line_item_report_line(line_item, order, transaction_id, subscription)
    ReportLine.new(
      order.number,
      order.completed_at.strftime('%m/%d/%Y'),
      order.billing_address.company,
      "%s %s %s, %s %s, %s" % [order.billing_address.address1, order.billing_address.address2, order.billing_address.city, order.billing_address.state_text, order.billing_address.zipcode, order.billing_address.country.to_s],
      line_item.variant.sku,
      line_item.quantity,
      line_item.price.to_f,
      (line_item.price * line_item.quantity).to_f,
      transaction_id,
      subscription.presence ? subscription.id : '',
      subscription.presence ? subscription.token : '',
      subscription.presence ? subscription.end_datetime.strftime('%m/%d/%Y') : '',
    )
  end

  def adjustment_report_line(adj, order, transaction_id, subscription)
    ReportLine.new(
      order.number,
      order.completed_at.strftime('%m/%d/%Y'),
      order.billing_address.company,
      "%s %s %s, %s %s, %s" % [order.billing_address.address1, order.billing_address.address2, order.billing_address.city, order.billing_address.state_text, order.billing_address.zipcode, order.billing_address.country.to_s],
      adj.label,
      nil,
      nil,
      adj.amount.to_f,
      transaction_id,
      subscription.presence ? subscription.id : '',
      subscription.presence ? subscription.token : '',
      subscription.presence ? subscription.end_datetime.strftime('%m/%d/%Y') : '',
    )
  end

  def shipment_report_line(shipment, order, transaction_id, subscription)
    ReportLine.new(
      order.number,
      order.completed_at.strftime('%m/%d/%Y'),
      order.billing_address.company,
      "%s %s %s, %s %s, %s" % [order.billing_address.address1, order.billing_address.address2, order.billing_address.city, order.billing_address.state_text, order.billing_address.zipcode, order.billing_address.country.to_s],
      shipment.shipping_method.try(:name) || 'Unknown shipping method',
      nil,
      nil,
      shipment.cost.to_f,
      transaction_id,
      subscription.presence ? subscription.id : '',
      subscription.presence ? subscription.token : '',
      subscription.presence ? subscription.end_datetime.strftime('%m/%d/%Y') : '',
    )
  end
end
