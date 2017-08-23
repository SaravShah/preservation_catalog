require 'rails_helper'

RSpec.describe MoabStorageController, type: :controller do

  describe "GET #index" do
    it "returns http success status code" do
      get :index
      expect(response).to have_http_status(:success)
    end
    context 'assigns @stored_druids correctly' do
      it 'without current or parent dot directories' do
        get :index
        expect(assigns(:stored_druids)).not_to include('.', '..')
      end
      it 'with all the fixture druids' do
        get :index
        expect(assigns(:stored_druids)).to include('ct764fs4485', 'dd116zh0343', 'dg806ms0373', 'jq937jp0017')
      end
      it 'Array of Strings' do
        get :index
        expect(assigns(:stored_druids)).to be_an_instance_of Array
        expect(assigns(:stored_druids).first).to be_an_instance_of String
      end
    end
    it 'returns json by default' do
      get :index
      expect(response.content_type).to eq "application/json"
    end
    it 'returns json when requested' do
      get :index, format: :json
      expect(response.content_type).to eq "application/json"
    end
    it 'returns xml when requested' do
      get :index, format: :xml
      expect(response.content_type).to eq "application/xml"
    end
  end
end