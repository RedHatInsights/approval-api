RSpec.describe Template, type: :model do
  it { should have_many(:workflows) }
  it { should validate_presence_of(:title) }

  describe '.seed' do
    before do
      ENV['APPROVAL_PAM_SERVICE_HOST'] = 'localhost'
      ENV['APPROVAL_PAM_SERVICE_PORT'] = '8080'
      ENV['KIE_SERVER_USERNAME']       = 'executionUser'
      ENV['KIE_SERVER_PASSWORD']       = 'password'
    end

    after do
      ENV['APPROVAL_PAM_SERVICE_HOST'] = nil
      ENV['APPROVAL_PAM_SERVICE_PORT'] = nil
      ENV['KIE_SERVER_USERNAME']       = nil
      ENV['KIE_SERVER_PASSWORD']       = nil
    end

    it 'creates a default template' do
      described_class.seed
      expect(described_class.count).to eq(1)

      template = described_class.find_by(:title => 'Basic')
      expect(template.process_setting).to include(
        'host'         => 'localhost:8080',
        'username'     => 'executionUser',
        'password'     => a_kind_of(Integer),
        'container_id' => 'approval',
        'process_id'   => 'MultiStageEmails'
      )
      expect(template.signal_setting).to include(
        'host'         => 'localhost:8080',
        'username'     => 'executionUser',
        'password'     => a_kind_of(Integer),
        'container_id' => 'approval',
        'signal_name'  => 'nextGroup',
      )
    end

    it 'skips already seeded record' do
      described_class.seed
      template_first_round = described_class.find_by(:title => 'Basic')

      described_class.seed
      tempalte_second_round = described_class.find_by(:title => 'Basic')
      expect(template_first_round.attributes).to eq(tempalte_second_round.attributes)
    end
  end

  describe '#destroy' do
    let(:password_id1) { Encryption.create!.id }
    let(:password_id2) { Encryption.create!.id }
    let(:template) { FactoryBot.create(:template, :process_setting => {'password' => password_id1}, :signal_setting => {'password' => password_id2}) }

    it 'deletes encrypted passwords' do
      expect(Encryption.where(:id => password_id1)).to exist
      expect(Encryption.where(:id => password_id2)).to exist
      template.destroy
      expect(Encryption.where(:id => password_id1)).not_to exist
      expect(Encryption.where(:id => password_id2)).not_to exist
    end
  end
end
