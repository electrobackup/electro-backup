class NewCheckoutsController < ApplicationController

  def create
    cart = params[:cart]
    shipping_form
  end

  def shipping_form
    @order = Order.new  # Initialize a new order object to bind to the form
  end

  def submit_shipping
    # Validate the form fields
    if params[:order][:name].blank? || params[:order][:phone].blank? || params[:order][:email].blank? || params[:order][:address].blank?
      flash[:error] = "All fields are required"
      @order = Order.new(order_params)  # Repopulate the form with the submitted data
      render :shipping_form and return
    end

    # Create the order and process the cart
    cart = session[:cart] || []

    # Assuming `Order.create!` creates an order with relevant details
    order = Order.create!(
      # name: params[:order][:name],
      # phone: params[:order][:phone],
      customer_email: params[:order][:email],
      address: params[:order][:address],
      fulfilled: false,
      total: cart.sum { |item| item["price"].to_i * item["quantity"].to_i }
    )

    # Process each cart item
    cart.each do |item|
      product = Product.find(item["id"])
      stock = Stock.find_by(product_id: product.id)

      OrderProduct.create!(
        order: order,
        product_id: product.id,
        quantity: item["quantity"].to_i,
        size: item["size"]
      )

      stock.decrement!(:amount, item["quantity"].to_i)
    end

    session[:cart] = nil  # Clear the cart session after processing

    redirect_to success_path  # Redirect to success page after order is created
  end

  private

  def order_params
    params.require(:order).permit(:customer_email, :address)
  end
end
