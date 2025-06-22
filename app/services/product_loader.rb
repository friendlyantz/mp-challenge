# frozen_string_literal: true

module Services
  class ProductLoader
    def self.load_from_file(file_path, fallback_path = nil)
      products = {}
      messages = []

      data = if File.exist?(file_path)
        JSON.parse(File.read(file_path))
      elsif fallback_path && File.exist?(fallback_path)
        messages << "Database file not found at #{file_path}. Using default products."
        JSON.parse(File.read(fallback_path))
      else
        messages << "No valid database file found."
        return {products: products, messages: messages}
      end

      data.each do |record|
        currency = record["currency"] || "AUD"

        product = Models::Product.new(
          uuid: record["uuid"],
          name: record["name"],
          price: record["price"],
          currency: currency
        )

        if product.valid?
          if products.key?(product.uuid)
            messages << "Duplicate product UUID detected: #{product.uuid}. Skipping."
          else
            products[product.uuid] = product
            messages << "Loaded product: #{product.name} - #{product.price.format} (#{product.price.currency})"
          end
        else
          messages << "Invalid product record: #{record}. Skipping."
        end
      end

      {products: products, messages: messages}
    rescue JSON::ParserError => e
      {products: {}, messages: ["Invalid JSON format: #{e.message}"]}
    rescue => e
      {products: {}, messages: ["Error loading database: #{e.message}"]}
    end
  end
end
