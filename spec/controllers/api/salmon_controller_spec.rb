require 'rails_helper'

RSpec.describe Api::SalmonController, type: :controller do
  render_views

  let(:account) { Fabricate(:user, account: Fabricate(:account, username: 'catsrgr8')).account }

  before do
    stub_request(:get, "https://quitter.no/.well-known/host-meta").to_return(request_fixture('.host-meta.txt'))
    stub_request(:get, "https://quitter.no/.well-known/webfinger?resource=acct:gargron@quitter.no").to_return(request_fixture('webfinger.txt'))
    stub_request(:get, "https://quitter.no/api/statuses/user_timeline/7477.atom").to_return(request_fixture('feed.txt'))
    stub_request(:get, "https://quitter.no/avatar/7477-300-20160211190340.png").to_return(request_fixture('avatar.txt'))
  end

  describe 'POST #update' do
    before do
      request.env['RAW_POST_DATA'] = File.read(File.join(Rails.root, 'spec', 'fixtures', 'salmon', 'mention.xml'))
      post :update, params: { id: account.id }
    end

    it 'contains XML in the request body' do
      expect(request.body.read).to be_a String
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'creates remote account' do
      expect(Account.find_by(username: 'gargron', domain: 'quitter.no')).to_not be_nil
    end

    it 'creates status' do
      expect(Status.find_by(uri: 'tag:quitter.no,2016-03-20:noticeId=1276923:objectType=note')).to_not be_nil
    end

    it 'creates mention for target account' do
      expect(account.mentions.count).to eq 1
    end
  end
end
