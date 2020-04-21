RSpec.describe Template, type: :model do
  it { should have_many(:workflows) }
  it { should validate_presence_of(:title) }

  describe '.seed' do
    let(:envs) do
      {
        :APPROVAL_PAM_SERVICE_HOST => 'localhost',
        :APPROVAL_PAM_SERVICE_PORT => '8080',
        :KIE_SERVER_USERNAME       => 'executionUser',
        :KIE_SERVER_PASSWORD       => 'password'
      }
    end

    it 'creates a default template' do
      RequestSpecHelper.with_modified_env envs do
        described_class.seed
        expect(described_class.count).to eq(1)

        template = described_class.find_by(:title => 'Basic')
        expect(template.process_setting).to include(
          'processor_type' => 'jbpm',
          'host'           => 'localhost:8080',
          'username'       => 'executionUser',
          'password'       => a_kind_of(Integer),
          'container_id'   => 'approval',
          'process_id'     => 'MultiStageEmails'
        )
        expect(template.signal_setting).to include(
          'processor_type' => 'jbpm',
          'host'           => 'localhost:8080',
          'username'       => 'executionUser',
          'password'       => a_kind_of(Integer),
          'container_id'   => 'approval',
          'signal_name'    => 'nextGroup'
        )
      end
    end

    it 'skips already seeded record' do
      RequestSpecHelper.with_modified_env envs do
        described_class.seed
        template_first_round = described_class.find_by(:title => 'Basic')
        expect(described_class.count).to eq(1)

        described_class.seed
        expect(described_class.count).to eq(1)
        template_second_round = described_class.find_by(:title => 'Basic')

        expect(template_first_round.attributes).to eq(template_second_round.attributes)
      end
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

  context '.policy_class' do
    it "is TemplatePolicy" do
      expect(Template.policy_class).to eq(TemplatePolicy)
    end
  end
end
