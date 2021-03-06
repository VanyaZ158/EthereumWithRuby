class RegistryImporter < ApplicationService
  def initialize(contract, input_name, model, form_class, entity_contract_name)
    @contract = contract
    @input_name = input_name
    @inputs = EthereumTools.parse_inputs(@contract, @input_name)

    @model = model
    @form_class = form_class
    @entity_contract_name = entity_contract_name
  end

  def call
    blocks_result = SafeBlockManager.call(@contract)
    return if blocks_result.blank?

    filter_id = EthereumTools.generate_filter_id(
      @contract,
      @input_name,
      from_block: blocks_result[:from_block],
      to_block: blocks_result[:to_block]
    )
    events = EthereumTools.events_from_filter(@contract, @input_name, filter_id)

    @model.connection.transaction do
      events.each do |event|
        transaction_id = event[:transactionHash]
        transaction = Ethereum::Singleton.instance.eth_get_transaction_receipt(transaction_id)
        args = EthereumTools.decode_outputs(transaction, @inputs)

        entity_id = args.first.to_i
        mapped_item = ContractDataMapper.call(@contract, @entity_contract_name, entity_id)
                                        &.merge(external_contract_id: entity_id)
        next if mapped_item.blank?

        form = @form_class.new(mapped_item.merge(external_contract_id: entity_id))
        next if form.invalid?

        persisted_entity = @model.find_by(external_contract_id: form.external_contract_id)
        if persisted_entity.present?
          persisted_entity.update!(form.attributes.except(:external_contract_id))
          next
        end

        @model.create!(form.attributes)
      end
    end
  end
end
