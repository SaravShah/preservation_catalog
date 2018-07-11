class AddLastArchiveValidationToPreservedCopy < ActiveRecord::Migration[5.1]
  def change
    add_column :preserved_copies, :last_archive_validation, :datetime
    add_index :preserved_copies, :last_archive_validation
  end
end
