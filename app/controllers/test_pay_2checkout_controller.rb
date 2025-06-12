class TestPay2checkoutsController < ApplicationController
    def create
      cart = params[:cart]
      
      line_items = cart.map do |item|
        product = Product.find(item["id"])
        product_stock = Stock.find_by(product_id: item["id"])
  
        if product_stock.amount < item["quantity"].to_i
          render json: { 
            error: "Not enough stock for #{product.name} in size #{item["size"]}. Only #{product_stock.amount} left." 
          }, status: 400
          return
        end
  
        {
          name: item["name"],
          quantity: item["quantity"].to_i,
          price: item["price"].to_f,
          size: item["size"],
          product_id: product.id,
          product_stock_id: product_stock.id
        }
      end
  
      puts "line_items: #{line_items}"
  
      # 🔐 2Checkout credentials
      merchant_code = "YOUR_MERCHANT_CODE"
      base_url = "https://secure.2checkout.com/checkout/purchase"
  
      # ❗ Ми візьмемо лише перший товар для Buy Link, бо 2Checkout стандартний checkout підтримує один товар.
      # Для кількох товарів потрібна інтеграція через API або cart
      first_item = line_items.first
  
      payload = {
        sid: merchant_code,
        mode: "2CO",
        li_0_type: "product",
        li_0_name: first_item[:name],
        li_0_price: first_item[:price],
        li_0_quantity: first_item[:quantity],
        currency_code: "USD",
        x_receipt_link_url: "http://localhost:3000/success"
      }
  
      redirect_url = "#{base_url}?#{payload.to_query}"
  
      render json: { url: redirect_url }
    end
  
    def success
      render :success
    end
  
    def cancel
      render :cancel
    end
  end
  