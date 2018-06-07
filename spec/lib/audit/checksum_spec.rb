require 'rails_helper'
require_relative "../../../lib/audit/checksum.rb"
require_relative '../../load_fixtures_helper.rb'

RSpec.describe Checksum do
  let(:endpoint_name) { 'fixture_sr1' }
  let(:limit) { Settings.c2m_sql_limit }

  before { allow(described_class.logger).to receive(:info) } # silence STDOUT chatter

  context '.validate_disk' do
    include_context 'fixture moabs in db'
    let(:subject) { described_class.validate_disk(endpoint_name, limit) }

    context 'when there are PreservedCopies to check' do
      let(:cv_mock) { instance_double(ChecksumValidator) }

      it 'creates an instance and calls #validate_checksums for every result when results are in a single batch' do
        allow(ChecksumValidator).to receive(:new).and_return(cv_mock)
        expect(cv_mock).to receive(:validate_checksums).exactly(3).times
        described_class.validate_disk(endpoint_name, limit)
      end

      it 'creates an instance and calls #validate_checksums on everything in batches' do
        pcs_from_scope = PreservedCopy.by_endpoint_name(endpoint_name).fixity_check_expired
        cv_list = pcs_from_scope.map do |pc|
          ChecksumValidator.new(pc)
        end
        cv_list.each do |cv|
          allow(ChecksumValidator).to receive(:new).with(cv.preserved_copy).and_return(cv)
          expect(cv).to receive(:validate_checksums).exactly(1).times.and_call_original
        end
        described_class.validate_disk(endpoint_name, 2)
      end
    end

    context 'when there are no PreservedCopies to check' do
      it 'will not create an instance to call validate_manifest_inventories on' do
        allow(ChecksumValidator).to receive(:new)
        PreservedCopy.all.update(last_checksum_validation: (Time.now.utc + 2.days))
        expect(ChecksumValidator).not_to receive(:new)
        subject
      end
    end
  end

  describe ".validate_disk_profiled" do
    let(:subject) { described_class.validate_disk_profiled('fixture_sr3') }

    it "spins up a profiler, calling profiling and printing methods on it" do
      mock_profiler = instance_double(Profiler)
      expect(Profiler).to receive(:new).and_return(mock_profiler)
      expect(mock_profiler).to receive(:prof)
      expect(mock_profiler).to receive(:print_results_flat).with('cv_validate_disk')
      subject
    end

    it "calls .validate_disk" do
      expect(described_class).to receive(:validate_disk)
      subject
    end
  end

  describe ".validate_disk_all_endpoints" do
    let(:subject) { described_class.validate_disk_all_endpoints }

    it 'calls validate_disk once per storage root' do
      expect(described_class).to receive(:validate_disk).exactly(HostSettings.storage_roots.entries.count).times
      subject
    end

    it 'calls validate_disk with the right arguments' do
      HostSettings.storage_roots.each_key do |storage_name|
        expect(described_class).to receive(:validate_disk).with(
          storage_name
        )
      end
      subject
    end
  end

  describe ".validate_disk_all_endpoints_profiled" do
    let(:subject) { described_class.validate_disk_all_endpoints_profiled }

    it "spins up a profiler, calling profiling and printing methods on it" do
      mock_profiler = instance_double(Profiler)
      expect(Profiler).to receive(:new).and_return(mock_profiler)
      expect(mock_profiler).to receive(:prof)
      expect(mock_profiler).to receive(:print_results_flat).with('cv_validate_disk_all_endpoints')
      subject
    end
    it "calls .validate_disk_all_endpoints" do
      expect(described_class).to receive(:validate_disk_all_endpoints)
      subject
    end
  end

  describe ".validate_druid" do
    include_context 'fixture moabs in db'
    it 'creates an instance ancd calls #validate_checksums for every result' do
      druid = 'bz514sm9647'
      pres_copies = PreservedCopy.by_druid(druid)
      cv_list = pres_copies.map do |pc|
        ChecksumValidator.new(pc)
      end
      cv_list.each do |cv|
        allow(ChecksumValidator).to receive(:new).with(cv.preserved_copy).and_return(cv)
        expect(cv).to receive(:validate_checksums).exactly(1).times.and_call_original
      end
      described_class.validate_druid(druid)
    end

    it "logs a debug message" do
      druid = 'xx000xx0500'
      error_msg = "Found 0 preserved copies."
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
      expect(Rails.logger).to receive(:debug).with(error_msg)
      described_class.validate_druid(druid)
    end

    it 'returns the checksum results lists for each PreservedCopy that was checked' do
      checksum_results_lists = described_class.validate_druid('bz514sm9647')
      expect(checksum_results_lists.size).to eq 1 # should just be one PC for the druid
      checksum_results = checksum_results_lists.first
      expect(checksum_results.contains_result_code?(AuditResults::MOAB_CHECKSUM_VALID)).to eq true
    end
  end

  describe ".validate_list_of_druids" do
    it 'calls Checksum.validate_druid once per druid' do
      csv_file_path = 'spec/fixtures/druid_list.csv'
      CSV.foreach(csv_file_path) do |row|
        expect(described_class).to receive(:validate_druid).with(row.first)
      end
      described_class.validate_list_of_druids(csv_file_path)
    end
  end
end
