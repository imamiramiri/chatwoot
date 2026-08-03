class Messages::ContentUpdateService
  # Raised when an agent attempts to edit a message that is not editable
  # (e.g. incoming messages, deleted messages, non-text content types).
  class EditNotAllowedError < StandardError; end

  attr_reader :message, :content, :user

  def initialize(message:, content:, user: nil)
    @message = message
    @content = content.to_s
    @user = user
  end

  def perform
    ensure_editable!

    update_message_content
    message
  end

  private

  def ensure_editable!
    raise EditNotAllowedError, I18n.t('conversations.messages.edit.not_allowed') unless editable?
  end

  # Only an agent's own outgoing content (replies to the contact and private
  # notes) can be edited. Incoming, activity, template, deleted, non-text or
  # empty messages are never editable.
  def editable?
    message.outgoing? &&
      message.text? &&
      !message.deleted &&
      content.present?
  end

  # Keeps a single previous version in content_attributes and marks the message
  # as edited. Saving triggers `after_update_commit :dispatch_update_event`,
  # which broadcasts MESSAGE_UPDATED to agents and the contact (web widget).
  def update_message_content
    message.previous_content = message.content
    message.content = content
    message.edited = true
    message.edited_at = Time.current.to_i
    message.save!
  end
end
