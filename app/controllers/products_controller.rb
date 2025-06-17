class ProductsController < ApplicationController
  def show
    @product = Product.all
  end
end
