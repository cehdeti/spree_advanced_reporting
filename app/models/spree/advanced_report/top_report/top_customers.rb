class Spree::AdvancedReport::TopReport::TopCustomers < Spree::AdvancedReport::TopReport
  def initialize(params, limit)
    super(params)

    orders.each do |order|
      if order.user
        data[order.user.id] ||= {
          :email => order.user.email,
          :revenue => 0,
          :units => 0
        }
        data[order.user.id][:revenue] += revenue(order)
        data[order.user.id][:units] += units(order)
      end
    end

    self.ruportdata = Table(%w[email Units Revenue])
    data.inject({}) { |h, (k, v) | h[k] = v[:revenue]; h }.sort { |a, b| a[1] <=> b [1] }.reverse[0..limit].each do |k, v|
      ruportdata << { "email" => data[k][:email], "Units" => data[k][:units], "Revenue" => data[k][:revenue] }
    end
    ruportdata.replace_column("Revenue") { |r| "$%0.2f" % r.Revenue }
    ruportdata.rename_column("email", "Customer Email")
  end
end
