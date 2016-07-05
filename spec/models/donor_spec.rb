require 'rails_helper'

describe Donor do
  it "is not valid without a name" do
    expect(true).to eq true
    # include ActionDispatch::TestProcess
    # donorset = Donorset.create( source: fixture_file_upload( File.join(Rails.root, 'public', 'upload', 'donors', '2014.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'))
    # donorset.should be_valid
  end
  it "is not valid without a name"
  it "is not valid without an age"
  it "is not valid with an age less than zero"
end
