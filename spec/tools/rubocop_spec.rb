require 'json'

describe 'rubocop' do
  let!(:rubocop_json) { JSON.parse(`rubocop --format json`) }

  it 'has no code style offenses' do
    expect(rubocop_json['summary']['offense_count']).to eq(0)
  end
end
