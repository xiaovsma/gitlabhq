# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBridgeService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:downstream_project) { create(:project) }
  let(:bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }
  let(:instance) { described_class.new(project, user) }

  subject(:execute_service) { instance.execute(bridge) }

  context 'when user can run the bridge' do
    before do
      allow(instance).to receive(:can?).with(user, :play_job, bridge).and_return(true)
    end

    it 'marks the bridge pending' do
      execute_service

      expect(bridge.reload).to be_pending
    end

    it 'enqueues Ci::CreateCrossProjectPipelineWorker' do
      expect(::Ci::CreateCrossProjectPipelineWorker).to receive(:perform_async).with(bridge.id)

      execute_service
    end

    it "updates bridge's user" do
      execute_service

      expect(bridge.reload.user).to eq(user)
    end

    context 'when bridge is not playable' do
      let(:bridge) { create(:ci_bridge, :failed, pipeline: pipeline, downstream: downstream_project) }

      it 'raises StateMachines::InvalidTransition' do
        expect { execute_service }.to raise_error StateMachines::InvalidTransition
      end
    end
  end

  context 'when user can not run the bridge' do
    before do
      allow(instance).to receive(:can?).with(user, :play_job, bridge).and_return(false)
    end

    it 'allows user with developer role to play a bridge' do
      expect { execute_service }.to raise_error Gitlab::Access::AccessDeniedError
    end
  end
end
