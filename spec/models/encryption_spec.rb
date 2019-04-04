RSpec.describe Encryption, type: :model do
  it 'encrypts and decrypts a secret' do
    expect(ManageIQ::Password).to receive(:encrypt).and_return('xyz')
    expect(ManageIQ::Password).to receive(:decrypt).and_return('abc')

    test = Encryption.create(:secret => 'test')
    expect(test.secret).to eq('abc')
    expect(test.secret_encrypted).to eq('xyz')
  end
end
