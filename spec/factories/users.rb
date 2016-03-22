FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@server.com" }
    password 'password'
    role
  end
end
