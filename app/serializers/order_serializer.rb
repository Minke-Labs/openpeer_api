class OrderSerializer < ActiveModel::Serializer
  attributes :id, :fiat_amount, :status, :token_amount, :price, :uuid, :cancelled_at,
    :created_at

  belongs_to :buyer
  belongs_to :list
  has_one :escrow
  has_one :dispute
end
