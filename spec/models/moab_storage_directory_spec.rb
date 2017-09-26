require 'rails_helper'

RSpec.describe MoabStorageDirectory, type: :model do
  let(:storage_dir) { 'spec/fixtures/moab_storage_root' }

  describe '.find_moab_paths' do
    it 'passes a druid as the first parameter to the block it gets' do
      MoabStorageDirectory.find_moab_paths(storage_dir) do |druid, _path, _path_match_data|
        expect(druid).to match(/[[:lower:]]{2}\d{3}[[:lower:]]{2}\d{4}/)
      end
    end
    it 'passes a valid file path as the second parameter to the block it gets' do
      MoabStorageDirectory.find_moab_paths(storage_dir) do |_druid, path, _path_match_data|
        expect(File.exist?(path)).to be true
      end
    end
    it 'passes a MatchData object as the third parameter to the block it gets' do
      MoabStorageDirectory.find_moab_paths(storage_dir) do |_druid, _path, path_match_data|
        expect(path_match_data).to be_a_kind_of(MatchData)
      end
    end
  end

  describe '.list_moab_druids' do
    let(:druids) { MoabStorageDirectory.list_moab_druids(storage_dir) }

    it 'lists the expected druids in the fixture directory' do
      expect(druids).to include('bj102hs9687', 'bp628nk4868', 'bz514sm9647', 'dc048cw1328', 'jj925bx9565')
    end
    it 'returns only the expected druids in the fixture directory' do
      expect(druids.length).to eq 5
    end
  end

  describe '.storage_dir_regexp' do
    it 'caches the regular expression used to match druid paths under a given directory' do
      allow(Regexp).to receive(:new).and_call_original
      MoabStorageDirectory.send(:storage_dir_regexp, 'foo')
      MoabStorageDirectory.send(:storage_dir_regexp, 'foo')
      expect(Regexp).to have_received(:new).once
    end
  end
end