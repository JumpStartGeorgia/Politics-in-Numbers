require 'rails_helper'

RSpec.describe 'User', type: :feature do
  let(:content_manager_password) { 'eqwroipjzvjpo' }
  let(:new_content_manager_password) { 'dsalfkdjsakfjds' }
  let(:site_admin_password) { 'kqpiojgipoeczvipn@#!!' }

  let!(:content_manager_role) do
    FactoryGirl.create(:role, name: 'content_manager')
  end

  let!(:site_admin_role) do
    FactoryGirl.create(:role, name: 'site_admin')
  end

  let!(:super_admin_role) do
    FactoryGirl.create(:role, name: 'super_admin')
  end

  let!(:super_admin_user1) do
    FactoryGirl.create(:user, role: super_admin_role)
  end

  let!(:super_admin_user2) do
    FactoryGirl.create(:user, role: super_admin_role)
  end

  let!(:site_admin_user) do
    FactoryGirl.create(:user,
                       role: site_admin_role,
                       password: site_admin_password)
  end

  let!(:content_manager_user) do
    FactoryGirl.create(:user,
                       role: content_manager_role,
                       password: content_manager_password)
  end

  describe 'super_admin' do
    it "can update another super_admin's email and role" do
      login_as super_admin_user1, scope: :user

      visit edit_admin_user_path(super_admin_user2)
      within('.inputs') do
        fill_in 'Email', with: 'asdfsdfs@dsafdsf.com'
        select('content_manager', from: 'Role')
      end

      click_button 'Update User'
      expect(page).to have_content('User was successfully updated.')
    end

    it "can update another super_admin's email, password and role" do
      login_as super_admin_user1, scope: :user

      visit edit_admin_user_path(super_admin_user2)
      within('.inputs') do
        fill_in 'Email', with: 'asdfsdfs@dsafdsf.com'
        fill_in 'Password', with: 'asdfsdfdsflkjk;l'
        select('content_manager', from: 'Role')
      end

      click_button 'Update User'
      expect(page).to have_content('User was successfully updated.')
    end
  end

  describe 'site_admin' do
    it 'can successfully edit someone else\'s password' do
      visit new_user_session_path
      within('#new_user') do
        fill_in 'Email', with: site_admin_user.email
        fill_in 'Password', with: site_admin_password
      end

      click_on 'Log in'
      expect(page).to have_content('Signed in successfully.')

      visit edit_admin_user_path(content_manager_user)
      within('.inputs') do
        fill_in 'Password', with: new_content_manager_password
      end

      click_on 'Update User'
      expect(page).to have_content('User was successfully updated.')

      find('#user-dropdown').click
      click_on 'Logout'
      expect(page).to have_content('Signed out successfully.')

      visit new_user_session_path
      within('#new_user') do
        fill_in 'Email', with: content_manager_user.email
        fill_in 'Password', with: new_content_manager_password
      end

      click_on 'Log in'
      expect(page).to have_content('Signed in successfully.')
    end

    it 'can only select site_admin and content_manager on create user form' do
      login_as site_admin_user, scope: :user

      visit new_admin_user_path
      expect(page).to have_select 'Role',
                                  options: [site_admin_role.name,
                                            content_manager_role.name]
    end

    it 'can create a content_manager user' do
      login_as site_admin_user, scope: :user
      visit new_admin_user_path

      within('#new_user') do
        fill_in 'Email', with: 'dasfkjdsfajk@fdjkslfajds.com'
        fill_in 'Password', with: 'ADSASF!244xzfds'
        select('content_manager', from: 'Role')
      end

      click_on 'Create User'
      expect(page).to have_content('User was successfully created.')
    end
  end

  describe 'content_manager' do
    it 'can successfully edit their own password' do
      visit new_user_session_path
      within('#new_user') do
        fill_in 'Email', with: content_manager_user.email
        fill_in 'Password', with: content_manager_password
      end

      click_on 'Log in'
      expect(page).to have_content('Signed in successfully.')

      visit edit_user_registration_path
      within('#edit_user') do
        fill_in 'Password', with: new_content_manager_password
        fill_in 'Password confirmation', with: new_content_manager_password
        fill_in 'Current password', with: content_manager_user.password
      end

      click_button 'Update'
      expect(page)
        .to have_content('Your account has been updated successfully.')

      find('#user-dropdown').click
      click_on 'Logout'
      expect(page).to have_content('Signed out successfully.')

      visit new_user_session_path
      within('#new_user') do
        fill_in 'Email', with: content_manager_user.email
        fill_in 'Password', with: new_content_manager_password
      end

      click_on 'Log in'
      expect(page).to have_content('Signed in successfully.')
    end

    it 'can reset password by email' do
      visit new_user_session_path
      click_on 'Forgot your password?'

      within '#new_user' do
        fill_in 'Email', with: content_manager_user.email
      end

      click_on 'Send me reset password instructions'

      open_email(content_manager_user.email)

      # Check that email contains JumpStart slogan (in the mailer layout)
      expect(current_email)
        .to have_content 'JumpStart Georgia - We communicate data better!'

      expect(current_email.from).to eq([ENV['APPLICATION_FEEDBACK_FROM_EMAIL']])

      current_email.click_link 'Change my password'

      fill_in 'New password', with: new_content_manager_password
      fill_in 'Confirm new password', with: new_content_manager_password

      click_on 'Change my password'

      visit new_user_session_path
      within('#new_user') do
        fill_in 'Email', with: content_manager_user.email
        fill_in 'Password', with: new_content_manager_password
      end

      click_on 'Log in'
      expect(page).to have_content('Signed in successfully.')
    end
  end
end
