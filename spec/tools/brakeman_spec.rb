require 'json'

describe 'brakeman' do
  let(:brakeman_json) { JSON.parse(`brakeman -q -f json`) }

  it 'has no security warnings (run "brakeman" in terminal to see warnings)' do
    expect(brakeman_json['warnings'].size).to eq(0)
  end
end
