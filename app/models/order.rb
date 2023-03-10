class Order < ApplicationRecord
  enum status: [:created, :escrowed, :release, :cancelled, :dispute, :closed]

  belongs_to :list
  belongs_to :buyer, class_name: 'User'
  belongs_to :cancelled_by, class_name: 'User', optional: true
  has_one :escrow
  has_one :dispute
  has_many :transactions

  scope :from_user, ->(address) do
    joins(list: [:seller]).joins(:buyer)
      .where('lower(users.address) = ? OR lower(buyers_orders.address) = ?', address.downcase, address.downcase)
  end

  def cancel(user)
    return if escrow.present? || !created? # TODO: Marcos cancel logic

    cancel!(user)
  end

  def cancel!(user)
    update(status: :cancelled, cancelled_by: user, cancelled_at: Time.now)
    NotificationWorker.perform_async(NotificationWorker::ORDER_CANCELLED, id)
  end

  def broadcast
    if buyer
      ActionCable.server.broadcast("OrdersChannel_#{uuid}_#{buyer.address}",
        ActiveModelSerializers::SerializableResource.new(self, scope: buyer, include: '**').to_json)
    end

    seller = list.seller
    if seller
      ActionCable.server.broadcast("OrdersChannel_#{uuid}_#{seller.address}",
        ActiveModelSerializers::SerializableResource.new(self, scope: seller, include: '**').to_json)
    end
  end

  before_create do
    if !self.uuid
      self.uuid = Uuid.generate

      while(Order.where(uuid: uuid).any?)
        self.uuid = Uuid.generate
      end
      self.trade_id = generate_trade_id
    end
  end

  private

  def generate_trade_id
    seller = Eth::Util.bin_to_hex Eth::Util.zpad_hex(list.seller.address, 0)
    buyer_address = Eth::Util.bin_to_hex Eth::Util.zpad_hex(buyer.address, 0)
    token = Eth::Util.bin_to_hex Eth::Util.zpad_hex(list.token.address, 0)
    addresses = [uuid, seller, buyer_address, token].join
    data = "#{addresses}#{Eth::Abi.encode(['uint256'], [raw_token_amount]).unpack("H*")[0]}"
    bytes = [data[2..-1]].pack("H*")
    Eth::Util.prefix_hex(Eth::Util.keccak256(bytes).unpack("H*")[0])
  end

  def raw_token_amount
    (token_amount * 10 ** list.token.decimals).to_i
  end
end
