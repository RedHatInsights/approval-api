RSpec.describe Template, type: :model do
  it { should have_many(:workflows) }
  it { should validate_presence_of(:title) }

  describe '.seed' do
    before do
      ENV['APPROVAL_PAM_SERVICE_HOST'] = 'localhost'
      ENV['APPROVAL_PAM_SERVICE_PORT'] = '8080'
      ENV['KIE_SERVER_USERNAME']       = 'executionUser'
      ENV['KIE_SERVER_PASSWORD']       = 'password'
      ENV['KIE_CONTAINER_ID']          = 'approval_1.0.0'
      ENV['BPM_BML_PROCESS_ID']        = 'com.redhat.management.approval.MultiStageEmails'
      ENV['BPM_BML_SIGNAL_NAME']       = 'nextGroup'
    end

    after do
      ENV['APPROVAL_PAM_SERVICE_HOST'] = nil
      ENV['APPROVAL_PAM_SERVICE_PORT'] = nil
      ENV['KIE_SERVER_USERNAME']       = nil
      ENV['KIE_SERVER_PASSWORD']       = nil
      ENV['KIE_CONTAINER_ID']          = nil
      ENV['BPM_BML_PROCESS_ID']        = nil
      ENV['BPM_BML_SIGNAL_NAME']       = nil
    end

    it 'creates a default template' do
      described_class.seed
      expect(described_class.count).to eq(1)

      template = described_class.find_by(:title => 'Basic')
      expect(template.process_setting).to include(
        'host'         => 'localhost:8080',
        'username'     => 'executionUser',
        'password'     => a_kind_of(Integer),
        'container_id' => 'approval_1.0.0',
        'process_id'   => 'com.redhat.management.approval.MultiStageEmails'
      )
      expect(template.signal_setting).to include(
        'host'         => 'localhost:8080',
        'username'     => 'executionUser',
        'password'     => a_kind_of(Integer),
        'container_id' => 'approval_1.0.0',
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
