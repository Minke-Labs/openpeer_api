require 'rails_helper'

describe Api::V1::PaymentMethodsController, type: :request do
  include_context 'authentication'

  describe '.index' do
    let!(:payment_methods) { create_list(:payment_method, 2) }
    context 'with an address filter' do
      it 'returns payment_methods from the address' do
        get api_v1_payment_methods_path, params: { address: payment_methods[0].user.address },
                                                    headers: authentication_header

        expect(response).to be_successful
        json = ActiveModelSerializers::SerializableResource.new([payment_methods[0]], each_serializer: PaymentMethodSerializer).to_json
        expect(response.body).to eq(json)
      end
    end
  end
end
