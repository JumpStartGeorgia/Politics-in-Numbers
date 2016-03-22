require 'rails_helper'
require 'cancan/matchers'

describe 'User' do
  let(:super_admin_role) { FactoryGirl.create(:role, name: 'super_admin') }
  let(:site_admin_role) { FactoryGirl.create(:role, name: 'site_admin') }

  let(:content_manager_role) do
    FactoryGirl.create(:role, name: 'content_manager')
  end

  let(:super_admin_user) { FactoryGirl.create(:user, role: super_admin_role) }
  let(:super_admin_user2) { FactoryGirl.create(:user, role: super_admin_role) }
  let(:site_admin_user) { FactoryGirl.create(:user, role: site_admin_role) }
  let(:site_admin_user2) { FactoryGirl.create(:user, role: site_admin_role) }

  let(:content_manager_user) do
    FactoryGirl.create(:user, role: content_manager_role)
  end

  let(:content_manager_user2) do
    FactoryGirl.create(:user, role: content_manager_role)
  end

  let(:visitor) { nil }

  describe 'when is super admin' do
    subject(:ability) { Ability.new(super_admin_user) }

    it 'can update super admin' do
      expect(ability).to be_able_to(:update, super_admin_user2)
    end

    it 'can update site admin' do
      expect(ability).to be_able_to(:update, site_admin_user)
    end

    it 'can update content manager' do
      expect(ability).to be_able_to(:update, content_manager_user)
    end
  end

  describe 'when is site admin' do
    subject(:ability) { Ability.new(site_admin_user) }

    it 'cannot update super admin' do
      expect(ability).not_to be_able_to(:update, super_admin_user)
    end

    it 'can update site admin' do
      expect(ability).to be_able_to(:update, site_admin_user2)
    end

    it 'can update content manager' do
      expect(ability).to be_able_to(:update, content_manager_user)
    end
  end

  describe 'when is content manager' do
    subject(:ability) { Ability.new(content_manager_user) }
    it 'cannot read users' do
      expect(ability).not_to be_able_to(:read, User.new)
    end

    it 'cannot manage users' do
      expect(ability).not_to be_able_to(:manage, User.new)
    end
  end

  describe 'when is not logged in' do
    subject(:ability) { Ability.new(visitor) }

    it 'cannot update super admin' do
      expect(ability).not_to be_able_to(:update, super_admin_user)
    end

    it 'cannot update site admin' do
      expect(ability).not_to be_able_to(:update, site_admin_user)
    end

    it 'cannot update content manager' do
      expect(ability).not_to be_able_to(:update, content_manager_user)
    end
  end
end
