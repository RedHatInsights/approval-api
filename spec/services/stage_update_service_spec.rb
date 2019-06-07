RSpec.describe StageUpdateService do
  let(:template) { create(:template, :signal_setting => {'processor_type' => 'jbpm', 'url' => 'url'}) }
  let(:workflow) { create(:workflow, :template => template) }
  let(:request)  { create(:request, :workflow => workflow) }
  let!(:stage1)  { create(:stage, :request => request) }
  let!(:stage2)  { create(:stage, :request => request) }
  let(:svc1)     { described_class.new(stage1.id) }
  let(:svc2)     { described_class.new(stage2.id) }
  let!(:event_service) { EventService.new(request) }

  before do
    allow(EventService).to  receive(:new).with(request).and_return(event_service)
    allow(event_service).to receive(:request_started)
    allow(event_service).to receive(:request_finished)
    allow(event_service).to receive(:request_canceled)
  end

  around do |example|
    ManageIQ::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
    end
  end

  context 'state becomes notified' do
    it 'sends approver_group_notified event and updates request' do
      expect(event_service).to receive(:approver_group_notified)
      svc1.update(:state => Stage::NOTIFIED_STATE)
      stage1.reload
      expect(stage1.state).to eq(Stage::NOTIFIED_STATE)
    end
  end

  context 'state becomes finished' do
    let(:jbpm) { double(:jbpm) }
    before { allow(JbpmProcessService).to receive(:new).and_return(jbpm) }

    describe 'first stage' do
      context 'with external process' do
        it 'sends approver_group_finished event and signals the external process' do
          expect(jbpm).to receive(:signal).with('denied')
          expect(event_service).to receive(:approver_group_finished)
          svc1.update(:state => Stage::FINISHED_STATE, :decision => 'denied')
          stage1.reload
          stage2.reload
          expect(stage1.state).to eq(Stage::FINISHED_STATE)
          expect(stage2.state).to eq(Stage::PENDING_STATE)
        end
      end

      context 'without external process' do
        let(:template) { create(:template) }

        it 'sends approver_group_finished event and moves to next stage' do
          expect(event_service).to receive(:approver_group_finished)
          expect(event_service).to receive(:approver_group_notified)
          svc1.update(:state => Stage::FINISHED_STATE)
          stage1.reload
          stage2.reload
          expect(stage1.state).to eq(Stage::FINISHED_STATE)
          expect(stage2.state).to eq(Stage::NOTIFIED_STATE)
        end
      end
    end

    describe 'last stage' do
      it 'sends approver_group_finished event and updates request' do
        expect(jbpm).to receive(:signal).with('approved')
        expect(event_service).to receive(:approver_group_finished)
        svc2.update(:state => Stage::FINISHED_STATE, :decision => 'approved')
        stage2.reload
        request.reload
        expect(stage2.state).to eq(Stage::FINISHED_STATE)
        expect(request.state).to eq(Request::FINISHED_STATE)
      end
    end
  end

  context 'state becomes canceled' do
    let(:jbpm) { double(:jbpm) }
    before { allow(JbpmProcessService).to receive(:new).and_return(jbpm) }

    describe 'first stage' do
      context 'with external process' do
        it 'signals the external process' do
          expect(jbpm).to receive(:signal).with('canceled')
          svc1.update(:state => Stage::CANCELED_STATE)
          stage1.reload
          stage2.reload
          expect(stage1.state).to eq(Stage::CANCELED_STATE)
          expect(stage2.state).to eq(Stage::PENDING_STATE)
        end
      end

      context 'without external process' do
        let(:template) { create(:template) }

        it 'skips the rest stages and cancels the request' do
          svc1.update(:state => Stage::CANCELED_STATE)
          stage1.reload
          stage2.reload
          request.reload
          expect(stage1.state).to eq(Stage::CANCELED_STATE)
          expect(stage2.state).to eq(Stage::SKIPPED_STATE)
          expect(request.state).to eq(Request::CANCELED_STATE)
        end
      end
    end

    describe 'last stage' do
      it 'cancels request' do
        expect(jbpm).to receive(:signal).with('canceled')
        svc2.update(:state => Stage::CANCELED_STATE)
        stage2.reload
        request.reload
        expect(stage2.state).to eq(Stage::CANCELED_STATE)
        expect(request.state).to eq(Request::CANCELED_STATE)
      end
    end
  end

  context 'state unchanged' do
    it 'sends no events' do
      expect(event_service).not_to receive(:approver_group_notified)
      expect(event_service).not_to receive(:approver_group_finished)
      svc1.update(:reason => 'another reason')
      stage1.reload
      expect(stage1.reason).to eq('another reason')
    end
  end
end
