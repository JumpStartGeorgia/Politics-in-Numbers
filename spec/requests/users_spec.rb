require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:site_admin_role) { FactoryGirl.create(:role, name: 'site_admin') }
  let(:site_admin_user) { FactoryGirl.create(:user, role: site_admin_role) }

  before(:example) do
    login_as(site_admin_user, scope: :user)
  end

  describe 'GET /users' do
    it 'works' do
      get admin_users_path
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /users/1' do
    it 'works' do
      get admin_user_path(site_admin_user)
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /users/new' do
    it 'works' do
      get new_admin_user_path
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /users/1/edit' do
    it 'works' do
      get edit_admin_user_path(site_admin_user)
      expect(response).to have_http_status(200)
    end
  end
end
