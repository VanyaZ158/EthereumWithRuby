class CreateBookEdition < ApplicationForm
  attr_reader :book_edition

  attribute :title, String
  attribute :isbn10, String
  attribute :isbn13, String
  attribute :edition, String
  attribute :binding, String
  attribute :deleted, Boolean

  attribute :author, String
  attribute :description, String
  attribute :publish_date, Date
  attribute :price, Integer

  attribute :height, Integer
  attribute :width, Integer
  attribute :depth, Integer

  validates :title, :isbn10, :isbn13, :edition, :binding, presence: true
  validates :deleted, inclusion: { in: [true, false] }
  validates :isbn10, length: { is: 10 }
  validates :isbn13, length: { is: 13 }
  validates :height, :width, :depth,  numericality: { greater_than: 0 }, allow_nil: true

  private

  def persist!
    @book_edition = BookEdition.create!(attributes)
  rescue ActiveRecord::RecordInvalid => invalid
    self.errors = invalid.errors
  end
end
