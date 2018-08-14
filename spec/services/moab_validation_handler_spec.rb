require 'rails_helper'

RSpec.describe MoabValidationHandler do
  let(:druid) { 'ab123cd4567' }
  let(:druid_path) { '/tmp/spec/root1/storage_trunk/ab/123/cd/4567/ab123cd4567'}
  let(:storage_obj) { Moab::StorageObject.new(druid, druid_path) }
  let(:mvh) { MoabValidationHandler(storage_obj) }

  # before do
  #   let(:mvh) { described_class() }
  # end

  context "#initialize" do
    moab_validation = described_class()
  end

  context '#moab' do

    it 'return complete moab' do
      p MoabValidationHandler.moab
    end
  end

  context "#object_dir" do
    #mvh = described_class(storage_obj)
    it "returns Path to the object directory" do

    end
  end

  context "#can_validate_checksums?" do

  end

  context 'moab single version metadata only' do



    it 'creates a directory structure ' do

    end

    it 'creates metadata files without content directory' do
      expect(Dir).to_not exist(druid_path + "v0001/data/content")
      expect(Dir).to exist(druid_path + "v0001/data/metadata")
    end

  end

  context 'moab single version metadata and content' do

    let(:druid_path) { '/tmp/spec/root1/storage_trunk/cd/123/ef/4567/cd123ef4567' }

    it 'creates metadata files with data/content directory' do
      expect(Dir).to exist(druid_path + "v0001/data/content")
      expect(Dir).to exist(druid_path + "v0001/data/metadata")
    end


  end

  context 'moab multiple versions with metadata only' do

    it 'creates multiple version directories with metadata only' do

    end
  end

  context 'moab mutiple versions with metadata and content' do

  end
end
