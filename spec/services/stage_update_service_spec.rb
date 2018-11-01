RSpec.describe StageUpdateService do
  let(:request) { create(:request) }
  let(:stage)   { create(:stage, :request => request)}
  subject { described_class.new(stage.id) }
  let!(:event_service) { EventService.new(request) }

  before { allow(EventService).to receive(:new).with(request).and_return(event_service) }

  context 'state becomes notified' do
    it 'sends approver_group_notified event' do
      expect(event_service).to receive(:approver_group_notified)
      subject.update(:state => Stage::NOTIFIED_STATE)
      stage.reload
      expect(stage.state).to eq(Stage::NOTIFIED_STATE)
    end
  end

  context 'state becomes finished' do
    it 'sends approver_group_finished event' do
      expect(event_service).to receive(:approver_group_finished)
      subject.update(:state => Stage::FINISHED_STATE)
      stage.reload
      expect(stage.state).to eq(Stage::FINISHED_STATE)
    end
  end

  context 'state unchanged' do
    it 'sends no events' do
      expect(event_service).not_to receive(:approver_group_notified)
      expect(event_service).not_to receive(:approver_group_finished)
      subject.update(:comments => 'another reason')
      stage.reload
      expect(stage.comments).to eq('another reason')
    end
  end
end
