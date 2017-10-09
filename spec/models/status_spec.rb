require 'rails_helper'

RSpec.describe Status, type: :model do
  let!(:status) { Status.find_by(status_text: 'ok') }

  it 'is valid with valid attributes' do
    expect(status).to be_valid
  end

  it 'is not valid without valid attributes' do
    expect(Status.new).not_to be_valid
  end

  it 'enforces unique constraint on status_text (model level)' do
    status
    exp_err_msg = 'Validation failed: Status text has already been taken'
    expect do
      Status.create!(status_text: 'ok')
    end.to raise_error(ActiveRecord::RecordInvalid, exp_err_msg)
  end

  it 'enforces unique constraint on status_text (db level)' do
    status
    dup_status = Status.new
    dup_status.status_text = 'ok'
    expect { dup_status.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it { is_expected.to have_many(:preservation_copies) }
  it { is_expected.to have_db_index(:status_text) }

  describe '.seed_from_config' do
    it 'creates the endpoint statuses listed in Settings' do
      Settings.statuses.each do |status_text|
        expect(Status.find_by(status_text: status_text)).to be_a_kind_of Status
      end
    end

    it 'does not re-create records that already exist' do
      # run it a second time
      Status.seed_from_config
      expect(Status.pluck(:status_text).sort).to eq(
        %w[expected_version_not_found_on_disk fixity_check_failed not_found_on_disk ok]
      )
    end

    it 'adds new records if there are additions to Settings since the last run' do
      Settings.statuses << 'another_status'

      # run it a second time
      Status.seed_from_config
      expect(Status.pluck(:status_text).sort).to eq(
        %w[another_status expected_version_not_found_on_disk fixity_check_failed not_found_on_disk ok]
      )
    end
  end
end
