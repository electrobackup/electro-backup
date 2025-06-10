class WebhooksController < ApplicationController
  skip_forgery_protection

  def stripe
    # Моканий payload, якщо підпису немає
    if Rails.env.development? || Rails.env.test?
      event = {
        "type" => "checkout.session.completed",
        "data" => {
          "object" => {
            "id" => "cs_test_mocked_123",
            "customer_details" => {
              "email" => "mock@example.com"
            },
            "amount_total" => 5000,
            "shipping_details" => {
              "address" => {
                "line1" => "123 Test St",
                "city" => "Testville",
                "state" => "CA",
                "postal_code" => "12345"
              }
            }
          }
        }
      }.with_indifferent_access
    else
      # Реальний Stripe webhook
      stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
      Stripe.api_key = stripe_secret_key
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
      
      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError
        render status: 400, json: { error: "Invalid webhook" }
        return
      end
    end

    # Опрацювання
    if event["type"] == "checkout.session.completed"
      session = event["data"]["object"]
      shipping_details = session["shipping_details"]

      address = if shipping_details
        "#{shipping_details['address']['line1']} #{shipping_details['address']['city']}, #{shipping_details['address']['state']} #{shipping_details["address"]["postal_code"]}"
      else
        ""
      end

      order = Order.create!(
        customer_email: session["customer_details"]["email"],
        total: session["amount_total"],
        address: address,
        fulfilled: false
      )

      # Мокуємо лінійні товари (один або більше)
      line_items = [
        {
          "quantity" => 1,
          "price" => {
            "product" => "prod_mocked_1"
          }
        }
      ]

      # Фейковий продукт для тестів
      product_metadata = {
        "product_id" => "1",
        "size" => "42",
        "product_stock_id" => "1"
      }

      line_items.each do |item|
        product_id = product_metadata["product_id"].to_i
        OrderProduct.create!(
          order: order,
          product_id: product_id,
          quantity: item["quantity"],
          size: product_metadata["size"]
        )
        Stock.find(product_metadata["product_stock_id"]).decrement!(:amount, item["quantity"])
      end
    else
      puts "Unhandled event type: #{event["type"]}"
    end

    render json: { message: 'Webhook handled successfully.' }
  end
end
