# frozen_string_literal: true

RSpec.describe App, type: "end to end" do
  it "renders the shopping cart" do
    expect(App.run).to match(
      <<~EXPECTATION
        Products in Shopping Cart:
        1. Jockey Wheels - Orange - $15.39
        2. Chain Ring 146mm - $65.95
        3. Carbon Brake Pads - $92.00
        4. Front Derailleur - 34.9mm - $31.22

        Discount applied: 20% off on total greater than $100

        TOTAL: $163.65
      EXPECTATION
    )
  end
end
