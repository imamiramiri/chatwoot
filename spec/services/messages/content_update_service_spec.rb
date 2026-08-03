require 'rails_helper'

describe Messages::ContentUpdateService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when the message is an editable outgoing message' do
      let(:message) do
        create(:message, conversation: conversation, account: account, message_type: :outgoing, content: 'original')
      end

      it 'updates the content and marks it as edited' do
        described_class.new(message: message, content: 'updated').perform

        expect(message.reload.content).to eq('updated')
        expect(message.edited).to be(true)
        expect(message.edited_at).to be_present
      end

      it 'keeps the previous content as history' do
        described_class.new(message: message, content: 'updated').perform

        expect(message.reload.previous_content).to eq('original')
      end

      it 'edits a private note' do
        note = create(:message, conversation: conversation, account: account, message_type: :outgoing,
                                private: true, content: 'note')

        described_class.new(message: note, content: 'edited note').perform

        expect(note.reload.content).to eq('edited note')
      end
    end

    context 'when the message is not editable' do
      it 'raises for an incoming message' do
        message = create(:message, conversation: conversation, account: account, message_type: :incoming, content: 'hi')

        expect { described_class.new(message: message, content: 'x').perform }
          .to raise_error(Messages::ContentUpdateService::EditNotAllowedError)
        expect(message.reload.content).to eq('hi')
      end

      it 'raises for a deleted message' do
        message = create(:message, conversation: conversation, account: account, message_type: :outgoing,
                                   content: 'deleted', content_attributes: { deleted: true })

        expect { described_class.new(message: message, content: 'x').perform }
          .to raise_error(Messages::ContentUpdateService::EditNotAllowedError)
      end

      it 'raises when the new content is blank' do
        message = create(:message, conversation: conversation, account: account, message_type: :outgoing, content: 'x')

        expect { described_class.new(message: message, content: '   ').perform }
          .to raise_error(Messages::ContentUpdateService::EditNotAllowedError)
      end
    end
  end
end
